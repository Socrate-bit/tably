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
    this.size,
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

  /// The button's size and a single line's height; 48 by default.
  final double? size;

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _controller = TextEditingController();

  double get _height => widget.size ?? 48.r;

  /// The typed text, scaled up with a larger [InputBar.size].
  TextStyle get _textStyle =>
      widget.size == null ? AppTextStyles.noteInput : AppTextStyles.noteInput.copyWith(fontSize: 17.sp);

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
            style: _textStyle,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              // One line is exactly as tall as the button beside it.
              isDense: true,
              constraints: BoxConstraints(minHeight: _height),
              hintText: widget.hint,
              hintStyle: _textStyle.copyWith(color: AppColors.textDisabled),
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
            width: _height,
            height: _height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _canSubmit ? AppColors.brand : AppColors.neutralBar,
              shape: BoxShape.circle,
            ),
            child: Text(widget.glyph, style: AppTextStyles.primaryButtonSmall.copyWith(height: 1, fontSize: widget.size == null ? null : _height * 0.45)),
          ),
        ),
      ],
    );
  }
}
