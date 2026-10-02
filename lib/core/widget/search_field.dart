import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../util/haptics.dart';

/// The rounded meal search box, with a clear button once there is text.
/// [compact] is the smaller, tinted variant used inside the replace sheet.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.onSubmitted,
    this.initialValue = '',
    this.compact = false,
  });

  final String hint;
  final String initialValue;
  final ValueChanged<String> onChanged;

  /// The keyboard's search key.
  final ValueChanged<String>? onSubmitted;
  final bool compact;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    Haptics.tap();
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(compact ? 26.r : 32.r),
      borderSide: const BorderSide(color: AppColors.border),
    );
    final style = AppTextStyles.searchInput.copyWith(fontSize: compact ? 16.sp : null);

    return TextField(
      controller: _controller,
      onChanged: (value) {
        widget.onChanged(value);
        setState(() {});
      },
      onSubmitted: widget.onSubmitted,
      style: style,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: style.copyWith(color: AppColors.textDisabled),
        filled: true,
        fillColor: compact ? AppColors.scaffold : AppColors.surface,
        contentPadding: compact
            ? EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h)
            : EdgeInsets.fromLTRB(24.w, 18.h, 16.w, 18.h),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        suffixIcon: _controller.text.isEmpty
            ? null
            : Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: GestureDetector(
                  onTap: _clear,
                  child: Container(
                    width: 28.r,
                    height: 28.r,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.fill, shape: BoxShape.circle),
                    child: Text('✕', style: AppTextStyles.meta.copyWith(fontSize: 14.sp)),
                  ),
                ),
              ),
        suffixIconConstraints: BoxConstraints(minWidth: 40.r, minHeight: 28.r),
      ),
    );
  }
}
