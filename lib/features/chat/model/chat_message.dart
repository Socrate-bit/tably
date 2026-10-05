import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../recipe/model/recipe.dart';

/// Who a chat message is from. An action is a change the AI chef proposed,
/// shown as a card the user approves or declines.
enum ChatRole {
  user('user'),
  assistant('assistant'),
  action('action');

  const ChatRole(this.id);
  final String id;

  static ChatRole fromId(String? id) => values.firstWhere((r) => r.id == id, orElse: () => assistant);
}

/// Where a proposed change is. Pending ones left over from a closed app are
/// expired: the change they described can no longer be applied.
enum ActionStatus {
  pending('pending'),
  running('running'),
  approved('approved'),
  declined('declined'),
  failed('failed'),
  expired('expired');

  const ActionStatus(this.id);
  final String id;

  bool get isOpen => this == pending || this == running;

  static ActionStatus fromId(String? id) => values.firstWhere((s) => s.id == id, orElse: () => expired);
}

/// A change the AI chef wants to make: which [tool] and what it will do,
/// resolved from the call's arguments so the card shows exactly what runs.
class ChatAction extends Equatable {
  const ChatAction({required this.tool, required this.preview, this.status = ActionStatus.pending});

  final String tool;

  /// Ids and values only; the card turns them into words.
  final Map<String, Object?> preview;
  final ActionStatus status;

  ChatAction copyWith({ActionStatus? status}) =>
      ChatAction(tool: tool, preview: preview, status: status ?? this.status);

  Map<String, dynamic> toMap() => {'tool': tool, 'preview': preview, 'status': status.id};

  factory ChatAction.fromMap(Map<String, dynamic> map) => ChatAction(
    tool: map['tool'] as String? ?? '',
    preview: Map<String, Object?>.from(map['preview'] as Map? ?? const {}),
    status: ActionStatus.fromId(map['status'] as String?),
  );

  @override
  List<Object?> get props => [tool, preview, status];
}

/// One message of the conversation with the AI chef, stored at
/// `users/{uid}/chat/{id}`.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.at,
    this.text = '',
    this.recipes = const [],
    this.action,
  });

  final String id;
  final ChatRole role;

  /// When it was written, on this device, which orders the conversation.
  final DateTime at;
  final String text;

  /// Recipes shown as cards under the message, kept whole so they still
  /// open after the app restarts.
  final List<Recipe> recipes;
  final ChatAction? action;

  ChatMessage copyWith({ChatAction? action}) =>
      ChatMessage(id: id, role: role, at: at, text: text, recipes: recipes, action: action ?? this.action);

  Map<String, dynamic> toMap() => {
    'role': role.id,
    'at': Timestamp.fromDate(at),
    'text': text,
    'recipes': [
      for (final r in recipes) {'id': r.id, ...r.toMap()},
    ],
    if (action != null) 'action': action!.toMap(),
  };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) => ChatMessage(
    id: id,
    role: ChatRole.fromId(map['role'] as String?),
    at: (map['at'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    text: map['text'] as String? ?? '',
    recipes: [
      for (final r in map['recipes'] as List? ?? const [])
        if (r is Map) Recipe.fromMap('${r['id']}', Map<String, dynamic>.from(r)),
    ],
    action: map['action'] is Map ? ChatAction.fromMap(Map<String, dynamic>.from(map['action'] as Map)) : null,
  );

  @override
  List<Object?> get props => [id, role, at, text, recipes, action];
}
