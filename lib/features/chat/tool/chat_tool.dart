import 'package:firebase_ai/firebase_ai.dart';

import '../../recipe/model/recipe.dart';

/// How a tool runs.
enum ToolKind {
  /// Reads the app; runs at once.
  read,

  /// Calls Spoonacular, spending the user's daily allowance; runs at once.
  quota,

  /// Changes something; runs only once the user approves its card.
  write,
}

/// What running a tool gave.
sealed class ToolOutcome {
  const ToolOutcome();
}

/// The answer for the model, sent back straight away.
class ToolResult extends ToolOutcome {
  const ToolResult(this.json);

  final Map<String, Object?> json;
}

/// A change waiting for the user: the card shows [preview] (and [recipes]),
/// and approving it runs [commit], whose result goes back to the model.
class ToolProposal extends ToolOutcome {
  const ToolProposal({required this.preview, required this.commit, this.recipes = const []});

  final Map<String, Object?> preview;
  final List<Recipe> recipes;
  final Future<Map<String, Object?>> Function() commit;
}

/// What a tool can ask of the conversation it runs in.
class ToolContext {
  const ToolContext({required this.recipe, required this.remember, required this.show});

  /// Any recipe the user can see: the catalogue, a saved favourite, or one
  /// found or written earlier in the chat. Null for an id nobody gave.
  final Recipe? Function(String id) recipe;

  /// Keeps recipes found or written by a tool, so later calls can use them.
  final void Function(List<Recipe> recipes) remember;

  /// Shows recipes as cards under the next reply.
  final void Function(List<Recipe> recipes) show;
}

/// One thing the AI chef can do: its declaration for Gemini, and how it runs.
class ChatTool {
  const ChatTool({required this.declaration, required this.kind, required this.run});

  final FunctionDeclaration declaration;
  final ToolKind kind;
  final Future<ToolOutcome> Function(Map<String, Object?> args, ToolContext context) run;

  String get name => declaration.name;
}

/// A tool that takes no arguments, declared without a parameters schema:
/// Gemini may reject an object schema with no properties.
class NoArgsDeclaration extends FunctionDeclaration {
  NoArgsDeclaration(super.name, super.description) : super(parameters: const {});

  @override
  Map<String, Object?> toJson() => {'name': name, 'description': description};
}

/// Reads tool arguments, which Gemini sends as loosely typed JSON.
extension ToolArgs on Map<String, Object?> {
  String? string(String key) => switch (this[key]) {
    final String s when s.trim().isNotEmpty => s.trim(),
    _ => null,
  };

  int? integer(String key) => (this[key] as num?)?.round();

  double? number(String key) => (this[key] as num?)?.toDouble();

  bool? boolean(String key) => this[key] as bool?;

  List<String>? strings(String key) => this[key] is List
      ? [
          for (final v in this[key] as List)
            if (v is String && v.trim().isNotEmpty) v.trim(),
        ]
      : null;

  List<Map<String, Object?>> objects(String key) => [
    for (final v in this[key] as List? ?? const [])
      if (v is Map) Map<String, Object?>.from(v),
  ];
}
