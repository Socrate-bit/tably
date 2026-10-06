import 'package:firebase_ai/firebase_ai.dart';
import 'package:tably/features/chat/service/chat_agent_service.dart';

import 'live_backends.dart';

/// One tool call the model made, and what the app answered.
class EvalCall {
  EvalCall(this.name, this.args);

  final String name;
  final Map<String, Object?> args;
  Map<String, Object?>? result;
}

/// The AI chef's model over the Gemini API's REST endpoint, with the app's
/// model, prompt, tools and thinking level, so the eval runs the real
/// conversation outside the app.
class GeminiRestAgent extends ChatAgentService {
  GeminiRestAgent(this.gemini);

  final GeminiRest gemini;

  /// Every tool call, in order, for scoring.
  final calls = <EvalCall>[];

  Map<String, Object?>? _request;
  final _contents = <Object?>[];

  /// The last reply's calls, waiting for their answers.
  var _waiting = <EvalCall>[];

  @override
  bool get isStarted => _request != null;

  @override
  void start({required String system, required List<Content> history, required List<FunctionDeclaration> tools}) {
    _request = {
      'systemInstruction': Content.system(system).toJson(),
      'tools': [Tool.functionDeclarations(tools).toJson()],
      'generationConfig': GenerationConfig(
        thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.low),
      ).toJson(),
    };
    _contents
      ..clear()
      ..addAll(history.map((c) => c.toJson()));
  }

  @override
  void reset() => _request = null;

  @override
  Future<AgentReply> send(String text) => _ask(Content.text(text));

  @override
  Future<AgentReply> respond(List<FunctionResponse> responses) {
    // Answers come in the order of the calls.
    for (final (i, r) in responses.indexed) {
      if (i < _waiting.length) _waiting[i].result = r.response;
    }
    return _ask(Content.functionResponses(responses));
  }

  Future<AgentReply> _ask(Content content) async {
    final request = _request;
    if (request == null) throw StateError('Chat session not started');
    _contents.add(content.toJson());
    // The model's turn goes back verbatim, thought signatures included.
    final reply = await gemini.generate(ChatAgentService.model, {...request, 'contents': _contents});
    _contents.add(reply);
    final parts = [for (final p in (reply['parts'] as List? ?? const [])) Map<String, Object?>.from(p as Map)];
    final found = [
      for (final p in parts)
        if (p['functionCall'] case final Map call)
          FunctionCall(
            call['name'] as String,
            Map<String, Object?>.from(call['args'] as Map? ?? const {}),
            id: call['id'] as String?,
          ),
    ];
    _waiting = [for (final c in found) EvalCall(c.name, c.args)];
    calls.addAll(_waiting);
    return (text: GeminiRest.textOf(reply), calls: found);
  }
}
