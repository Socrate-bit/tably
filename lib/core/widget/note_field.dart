import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// The rounded multi-line box for the user's own text: a recipe note or the
/// custom instructions.
class NoteField extends StatelessWidget {
  const NoteField({super.key, required this.controller, required this.hint, this.focusNode, this.maxLength});

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20.r),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 3,
      maxLines: 6,
      maxLength: maxLength,
      style: AppTextStyles.noteInput,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.noteInput.copyWith(color: AppColors.textDisabled),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.all(16.r),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        // The limit is generous; a counter would only add noise.
        counterText: '',
      ),
    );
  }
}
