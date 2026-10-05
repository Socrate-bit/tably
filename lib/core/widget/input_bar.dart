import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../util/haptics.dart';

/// A rounded text field with a round action button beside it, used to add a
/// rule or a shopping item and to send a chat message. Submitting clears it.
class InputBar extends StatefulWidget {
  const InputBar({
    super.key,
    required this.hint,
    required this.onSubmitted,
    this.glyph = '+',
    this.enabled = true,
    this.maxLength,
    this.multiline = false,
  });

  final String hint;

  /// Called with the trimmed text; never with an empty one.
  final ValueChanged<String> onSubmitted;

  /// Drawn on the button, e.g. "+" or "↑".
  final String glyph;

  /// While false the text can be typed but not submitted.
  final bool enabled;
  final int? maxLength;

  /// Grows up to a few lines, for chat messages.
  final bool multiline;

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _controller = TextEditingController();

  bool get _canSubmit => widget.enabled && _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    Haptics.confirm();
    widget.onSubmitted(_controller.text.trim());
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(26.r),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            minLines: 1,
            maxLines: widget.multiline ? 5 : 1,
            textInputAction: TextInputAction.send,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [if (widget.maxLength != null) LengthLimitingTextInputFormatter(widget.maxLength)],
            style: AppTextStyles.noteInput,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.noteInput.copyWith(color: AppColors.textDisabled),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: _submit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48.r,
            height: 48.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _canSubmit ? AppColors.brand : AppColors.neutralBar,
              shape: BoxShape.circle,
            ),
            child: Text(widget.glyph, style: AppTextStyles.primaryButtonSmall.copyWith(height: 1)),
          ),
        ),
      ],
    );
  }
}
