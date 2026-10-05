import 'package:flutter/material.dart';

import '../../../core/widget/note_field.dart';
import '../../../l10n/app_localizations.dart';
import '../model/user_profile.dart';

/// The custom instructions box, also the AI chef's memory. Saves when the
/// user leaves it, or leaves the screen, rather than on every keystroke.
class CustomInstructionsField extends StatefulWidget {
  const CustomInstructionsField({super.key, required this.text, required this.onSaved});

  final String text;
  final ValueChanged<String> onSaved;

  @override
  State<CustomInstructionsField> createState() => CustomInstructionsFieldState();
}

class CustomInstructionsFieldState extends State<CustomInstructionsField> {
  late final TextEditingController _controller = TextEditingController(text: widget.text);
  late final FocusNode _focus = FocusNode()..addListener(_onFocusChange);

  void _onFocusChange() {
    if (!_focus.hasFocus) widget.onSaved(_controller.text);
  }

  /// Follows the stored text (e.g. once the profile loads) unless the user is typing.
  @override
  void didUpdateWidget(CustomInstructionsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && widget.text != _controller.text.trim()) _controller.text = widget.text;
  }

  @override
  void dispose() {
    widget.onSaved(_controller.text);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NoteField(
      controller: _controller,
      focusNode: _focus,
      hint: AppL10n.of(context).prefsCustomInstructionsHint,
      maxLength: UserProfile.customInstructionsMax,
    );
  }
}
