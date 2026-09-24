import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/circle_icon_button.dart';
import '../../../core/widget/count_badge.dart';
import '../../../core/widget/line_icon.dart';
import '../cubit/recipe_browse_cubit.dart';

/// The round filter button; tinted, with a count, while filters are active.
class FilterButton extends StatelessWidget {
  const FilterButton({super.key, required this.onPressed, this.compact = false});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final count = context.select<RecipeBrowseCubit, int>((c) => c.state.filterCount);
    final active = count > 0;
    return CountBadge(
      count: count,
      child: CircleIconButton(
        size: compact ? 50.r : 58.r,
        background: active ? AppColors.brandSoft : (compact ? AppColors.scaffold : AppColors.surface),
        icon: LineIcon(LineGlyph.filter, size: compact ? 20.r : 21.r, color: active ? AppColors.brandDark : AppColors.ink),
        onPressed: onPressed,
      ),
    );
  }
}
