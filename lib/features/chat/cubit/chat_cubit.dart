import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../recipe/model/recipe.dart';
import '../model/chat_message.dart';
import '../service/chat_agent_service.dart';
import '../service/chat_prompt.dart';
import '../service/chat_service.dart';
import '../tool/chat_tool.dart';
import '../tool/chat_tools.dart';

part 'chat_state.dart';

/// Thrown when the model keeps calling tools without ever answering.
class ChatLoopException implements Exception {
  const ChatLoopException();
}

/// Runs the conversation with the AI chef. Each reply's tool calls run in
/// order: reads and Spoonacular calls straight away, changes as cards the
/// user approves or declines. Once every call of the reply has its answer,
/// they all go back to the model together, until it answers in text.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required ChatService service,
    required ChatAgentService agent,
    required ChatTools tools,
    required AnalyticsService analytics,
  }) : _service = service,
       _agent = agent,
       _tools = tools,
       _analytics = analytics,
       super(const ChatState());

  /// Model replies in a row that may call tools before one must answer.
  static const maxRounds = 8;

  /// Past messages a new conversation remembers.
  static const historyMessages = 30;

  final ChatService _service;
  final ChatAgentService _agent;
  final ChatTools _tools;
  final AnalyticsService _analytics;
  StreamSubscription<List<ChatMessage>>? _subscription;
  String? _uid;

  /// The stored conversation, and messages shown before their save landed.
  List<ChatMessage> _stored = const [];
  final _unsaved = <String, ChatMessage>{};
  int _count = 0;

  /// The reply whose tool calls are being answered, and its cards still
  /// waiting for the user, by message id.
  _Turn? _turn;
  final _proposals = <String, ({int index, ToolProposal proposal})>{};

  /// Recipes found or written in this conversation, and those to show as
  /// cards under the next reply.
  final _found = <String, Recipe>{};
  final _shown = <Recipe>[];

  late final _context = ToolContext(
    recipe: (id) => _tools.known(id) ?? _found[id] ?? state.recipeById(id),
    remember: (recipes) => _found.addAll({for (final r in recipes) r.id: r}),
    show: _shown.addAll,
  );

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _forgetTurn();
    _agent.reset();
    _subscription?.cancel();
    // Cards left pending by a closed app can't run any more.
    unawaited(_service.expirePending(uid));
    _subscription = _service.watch(uid).listen((messages) {
      _stored = messages;
      emit(state.copyWith(messages: _merged()));
    }, onError: (Object e) => debugPrint('[ChatCubit] stream error: $e'));
  }

  /// Starts afresh when the chat opens, so the chef sees the latest week
  /// and preferences. The past messages carry over as its memory.
  void refresh() {
    if (state.busy) return;
    _agent.reset();
    unawaited(_analytics.capture(AnalyticsEvents.chatOpened));
  }

  /// Sends the user's message, unless today's searches are all spent: the
  /// chat then waits for them to come back.
  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.busy || _tools.quota.state.remaining == 0) return;
    _start();
    await _put(ChatMessage(id: _newId(), role: ChatRole.user, at: DateTime.now(), text: message));
    unawaited(_analytics.capture(AnalyticsEvents.chatMessageSent, properties: {'length': message.length}));
    await _run(() => _agent.send(message), round: 0);
  }

  /// Sends the last message again after a failure.
  Future<void> retry() async {
    final last = state.messages.where((m) => m.role == ChatRole.user).lastOrNull;
    if (last == null || state.busy || _tools.quota.state.remaining == 0) return;
    _start();
    await _run(() => _agent.send(last.text), round: 0);
  }

  /// Runs a proposed change, or [run] in its place for a change only the
  /// screen can make (sharing), and tells the model how it went.
  Future<void> approve(String messageId, {Future<Map<String, Object?>> Function()? run}) async {
    final entry = _proposals.remove(messageId);
    final turn = _turn;
    if (entry == null || turn == null) return;
    await _setStatus(messageId, ActionStatus.running);
    Map<String, Object?> result;
    try {
      result = await (run ?? entry.proposal.commit)();
    } catch (e) {
      debugPrint('[ChatCubit] change failed: $e');
      result = {'error': ChatTools.reasonFor(e)};
    }
    if (isClosed) return;
    final ok = result['error'] == null;
    await _setStatus(messageId, ok ? ActionStatus.approved : ActionStatus.failed);
    debugPrint('[ChatCubit] ${turn.calls[entry.index].name} ${ok ? 'applied' : 'failed'}');
    unawaited(
      _analytics.capture(
        AnalyticsEvents.chatActionResolved,
        properties: {'tool': turn.calls[entry.index].name, 'approved': true, 'ok': ok},
      ),
    );
    await _answer(turn, entry.index, result);
  }

  Future<void> decline(String messageId) async {
    final entry = _proposals.remove(messageId);
    final turn = _turn;
    if (entry == null || turn == null) return;
    await _setStatus(messageId, ActionStatus.declined);
    unawaited(
      _analytics.capture(
        AnalyticsEvents.chatActionResolved,
        properties: {'tool': turn.calls[entry.index].name, 'approved': false},
      ),
    );
    await _answer(turn, entry.index, const {'declined_by_user': true});
  }

  void errorShown() => emit(state.copyWith(clearError: true));

  /// How the tool [name] runs, for the typing indicator.
  ToolKind? kindOf(String name) => _tools.byName[name]?.kind;

  /// Starts the Gemini conversation if needed, with the latest context.
  void _start() {
    if (_agent.isStarted) return;
    _agent.start(
      system: ChatPrompt.instruction(
        profile: _tools.profile.state.profile,
        week: _tools.weekJson(),
        now: DateTime.now(),
      ),
      history: _history(),
      tools: _tools.declarations,
    );
  }

  /// Asks the model, then works through its reply.
  Future<void> _run(Future<AgentReply> Function() ask, {required int round}) async {
    emit(state.copyWith(status: ChatStatus.thinking, clearError: true));
    try {
      final reply = await ask();
      if (isClosed) return;
      await _handle(reply, round);
    } catch (e) {
      debugPrint('[ChatCubit] turn failed: $e');
      if (!isClosed) await _fail(e);
    }
  }

  Future<void> _handle(AgentReply reply, int round) async {
    final text = reply.text.trim();
    if (text.isNotEmpty || _shown.isNotEmpty) {
      await _put(
        ChatMessage(id: _newId(), role: ChatRole.assistant, at: DateTime.now(), text: text, recipes: [..._shown]),
      );
      _shown.clear();
    }
    if (reply.calls.isEmpty) {
      emit(state.copyWith(status: ChatStatus.idle, clearActivity: true));
      return;
    }
    if (round >= maxRounds) throw const ChatLoopException();

    final turn = _turn = _Turn(reply.calls, round);
    for (final (index, call) in reply.calls.indexed) {
      final tool = _tools.byName[call.name];
      if (tool == null) {
        turn.answers[index] = {'error': 'unknown_tool'};
        continue;
      }
      emit(state.copyWith(activity: call.name));
      unawaited(
        _analytics.capture(AnalyticsEvents.chatToolCalled, properties: {'tool': call.name, 'kind': tool.kind.name}),
      );
      ToolOutcome outcome;
      try {
        outcome = await tool.run(call.args, _context);
      } catch (e) {
        debugPrint('[ChatCubit] ${call.name} failed: $e');
        outcome = ToolResult({'error': ChatTools.reasonFor(e)});
      }
      if (isClosed) return;
      switch (outcome) {
        case ToolResult(:final json):
          turn.answers[index] = json;
        case final ToolProposal proposal:
          final message = ChatMessage(
            id: _newId(),
            role: ChatRole.action,
            at: DateTime.now(),
            recipes: proposal.recipes,
            action: ChatAction(tool: call.name, preview: proposal.preview),
          );
          _proposals[message.id] = (index: index, proposal: proposal);
          await _put(message);
      }
    }
    emit(state.copyWith(clearActivity: true));
    if (turn.isComplete) {
      await _resume(turn);
    } else {
      emit(state.copyWith(status: ChatStatus.confirming));
    }
  }

  /// Records the user's answer to a card, and moves on once it was the last.
  Future<void> _answer(_Turn turn, int index, Map<String, Object?> result) async {
    turn.answers[index] = result;
    if (turn.isComplete && identical(_turn, turn)) await _resume(turn);
  }

  Future<void> _resume(_Turn turn) async {
    _turn = null;
    await _run(() => _agent.respond(turn.responses), round: turn.round + 1);
  }

  /// Ends a failed turn. The model's history may now hold calls without
  /// answers, so the next message starts a fresh conversation.
  Future<void> _fail(Object error) async {
    final waiting = _proposals.keys.toList();
    _forgetTurn();
    _agent.reset();
    for (final id in waiting) {
      await _setStatus(id, ActionStatus.expired);
    }
    emit(state.copyWith(status: ChatStatus.failed, error: error, clearActivity: true));
    unawaited(
      _analytics.capture(
        AnalyticsEvents.chatFailed,
        properties: {'reason': error is ChatLoopException ? 'loop' : ChatTools.reasonFor(error)},
      ),
    );
  }

  void _forgetTurn() {
    _turn = null;
    _proposals.clear();
    _shown.clear();
  }

  /// The past conversation as the model's memory, in text. A trailing user
  /// message is left out: it is about to be sent (again).
  List<Content> _history() {
    final recent = state.messages.length > historyMessages
        ? state.messages.sublist(state.messages.length - historyMessages)
        : state.messages;
    final contents = <Content>[];
    for (final m in recent) {
      final (role, text) = switch (m.role) {
        ChatRole.user => ('user', m.text),
        ChatRole.assistant => (
          'model',
          [
            m.text,
            if (m.recipes.isNotEmpty) '[shown recipes: ${m.recipes.map((r) => '${r.id} "${r.title}"').join(', ')}]',
          ].where((t) => t.isNotEmpty).join('\n'),
        ),
        ChatRole.action => ('model', '[proposed ${m.action?.tool}: ${m.action?.status.id}]'),
      };
      if (text.trim().isEmpty) continue;
      if (contents.isNotEmpty && contents.last.role == role) {
        contents.last = Content(role, [...contents.last.parts, TextPart(text)]);
      } else {
        contents.add(Content(role, [TextPart(text)]));
      }
    }
    while (contents.isNotEmpty && contents.first.role != 'user') {
      contents.removeAt(0);
    }
    if (contents.isNotEmpty && contents.last.role == 'user') contents.removeLast();
    return contents;
  }

  /// Shows [message] at once, then saves it.
  Future<void> _put(ChatMessage message) async {
    _unsaved[message.id] = message;
    emit(state.copyWith(messages: _merged()));
    final uid = _uid;
    if (uid == null) return;
    try {
      await _service.save(uid, message);
      if (identical(_unsaved[message.id], message)) _unsaved.remove(message.id);
    } catch (e) {
      // Stays on screen for this session; the conversation goes on.
      debugPrint('[ChatCubit] save failed: $e');
    }
  }

  Future<void> _setStatus(String messageId, ActionStatus status) async {
    final message = state.messages.where((m) => m.id == messageId).firstOrNull;
    final action = message?.action;
    if (message == null || action == null) return;
    await _put(message.copyWith(action: action.copyWith(status: status)));
  }

  List<ChatMessage> _merged() {
    final byId = {for (final m in _stored) m.id: m, ..._unsaved};
    return byId.values.toList()..sort((a, b) => a.at.compareTo(b.at));
  }

  /// Sortable and unique on this device; Firestore takes any id.
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_count++}';

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

/// The tool calls of one model reply and their answers so far, by position.
class _Turn {
  _Turn(this.calls, this.round) : answers = List.filled(calls.length, null);

  final List<FunctionCall> calls;
  final int round;
  final List<Map<String, Object?>?> answers;

  bool get isComplete => !answers.contains(null);

  List<FunctionResponse> get responses => [
    for (final (i, call) in calls.indexed) FunctionResponse(call.name, answers[i]!, id: call.id),
  ];
}
