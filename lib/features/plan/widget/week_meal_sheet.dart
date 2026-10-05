import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/app_sheet.dart';
import '../../../core/widget/line_icon.dart';
import '../../../core/widget/recipe_photo.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../recipe/model/recipe.dart';
import '../cubit/plan_cubit.dart';
import '../model/week_plan.dart';
import 'day_header.dart';

/// "Ajouter au menu de la semaine": the week's meals, day by day. [recipe]
/// takes the place of the one tapped.
class WeekMealSheet extends StatelessWidget {
  const WeekMealSheet({super.key, required this.recipe});

  final Recipe recipe;

  /// Shows the sheet; resolves to true once a meal was replaced.
  static Future<bool> show(BuildContext context, {required Recipe recipe}) async =>
      await AppSheet.show<bool>(context, (_) => WeekMealSheet(recipe: recipe)) ?? false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final week = context.select<PlanCubit, WeekPlan>((c) => c.state.week);

    return AppSheet(
      title: l10n.recipeAddToWeek,
      subtitle: l10n.replaceSubtitleWeek,
      child: ListView(
        children: [
          for (final (day, slots) in week.byDay) ...[
            DayHeader(label: l10n.dayName(day).toUpperCase()),
            SizedBox(height: 10.h),
            for (final slot in slots)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _WeekMealRow(slot: slot, onTap: () => _choose(context, slot)),
              ),
          ],
        ],
      ),
    );
  }

  void _choose(BuildContext context, PlanSlot slot) {
    Haptics.confirm();
    context.read<PlanCubit>().replace(slot.key, recipe);
    Navigator.of(context).pop(true);
  }
}

/// A planned meal: photo, slot name, title and whether it is leftovers.
class _WeekMealRow extends StatelessWidget {
  const _WeekMealRow({required this.slot, required this.onTap});

  final PlanSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return SurfaceCard(
      onTap: onTap,
      radius: 20.r,
      padding: EdgeInsets.all(11.r),
      color: Colors.transparent,
      child: Row(
        children: [
          RecipePhoto(
            url: slot.recipe.photoUrl,
            height: 62.r,
            width: 62.r,
            radius: 14.r,
            opacity: slot.isLeftover ? 0.8 : 1,
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slot.showSlotLabel) ...[
                  Text(l10n.slotName(slot.slot).toUpperCase(), style: AppTextStyles.slotLabel),
                  SizedBox(height: 3.h),
                ],
                Text(
                  slot.recipe.title,
                  style: AppTextStyles.recipeRowTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (slot.isLeftover) ...[
                  SizedBox(height: 4.h),
                  Text(l10n.leftoverBadge, style: AppTextStyles.rowMeta),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          LineIcon(LineGlyph.chevronRight, size: 18.r, color: AppColors.chevron),
        ],
      ),
    );
  }
}
