part of 'chat_cubit.dart';

enum ChatStatus {
  idle,

  /// Waiting on Gemini or running a tool.
  thinking,

  /// Waiting for the user to approve or decline the proposed changes.
  confirming,

  /// The last turn failed; the user can retry it.
  failed,
}

class ChatState extends Equatable {
  const ChatState({this.messages = const [], this.status = ChatStatus.idle, this.activity, this.error});

  /// The conversation, oldest first.
  final List<ChatMessage> messages;
  final ChatStatus status;

  /// The tool running now, which the typing indicator describes.
  final String? activity;
  final Object? error;

  /// The user can't send while a turn is under way.
  bool get busy => status == ChatStatus.thinking || status == ChatStatus.confirming;

  /// A recipe shown in the chat, latest first, so its card opens.
  Recipe? recipeById(String id) {
    for (final message in messages.reversed) {
      for (final recipe in message.recipes) {
        if (recipe.id == id) return recipe;
      }
    }
    return null;
  }

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatStatus? status,
    String? activity,
    bool clearActivity = false,
    Object? error,
    bool clearError = false,
  }) => ChatState(
    messages: messages ?? this.messages,
    status: status ?? this.status,
    activity: clearActivity ? null : (activity ?? this.activity),
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [messages, status, activity, error];
}
