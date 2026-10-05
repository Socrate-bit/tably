import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// What the model answered: some text, and the tools it wants to call.
typedef AgentReply = ({String text, List<FunctionCall> calls});

/// The AI chef's Gemini conversation. Tools are declared but never run
/// here: the chat cubit runs them, asking the user first for any change,
/// and answers with [respond].
class ChatAgentService {
  /// Picking among two dozen tools and chaining them (find a recipe, then
  /// put it in a slot) needs more than the lite model; a little thinking
  /// keeps answers quick.
  static const model = 'gemini-3.5-flash';

  ChatSession? _session;

  bool get isStarted => _session != null;

  /// Starts a conversation that remembers [history], with the AI chef's
  /// [system] prompt and [tools].
  void start({required String system, required List<Content> history, required List<FunctionDeclaration> tools}) {
    final gemini = FirebaseAI.googleAI().generativeModel(
      model: model,
      systemInstruction: Content.system(system),
      tools: [Tool.functionDeclarations(tools)],
      generationConfig: GenerationConfig(thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.low)),
    );
    _session = gemini.startChat(history: history);
    debugPrint('[ChatAgentService] session started with ${history.length} past messages');
  }

  /// Forgets the conversation; the next [start] begins a new one.
  void reset() => _session = null;

  /// Sends the user's [text].
  Future<AgentReply> send(String text) => _ask(Content.text(text));

  /// Answers the tool calls of the last reply, in the order they came.
  Future<AgentReply> respond(List<FunctionResponse> responses) => _ask(Content.functionResponses(responses));

  Future<AgentReply> _ask(Content content) async {
    final session = _session;
    if (session == null) throw StateError('Chat session not started');
    final response = await session.sendMessage(content);
    final calls = response.functionCalls.toList();
    debugPrint('[ChatAgentService] reply: ${calls.isEmpty ? 'text' : calls.map((c) => c.name).join(', ')}');
    return (text: response.text ?? '', calls: calls);
  }
}
