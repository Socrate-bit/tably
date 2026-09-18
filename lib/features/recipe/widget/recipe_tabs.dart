import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../model/recipe.dart';

/// Pill switch between the ingredients and preparation lists.
class RecipeSegmentedTabs extends StatelessWidget {
  const RecipeSegmentedTabs({
    super.key,
    required this.showIngredients,
    required this.onChanged,
  });

  final bool showIngredients;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: l10n.recipeTabIngredients,
              active: showIngredients,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _Segment(
              label: l10n.recipeTabPreparation,
              active: !showIngredients,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3.r,
                    offset: Offset(0, 1.h),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.segmentedLabel.copyWith(
            color: active ? AppColors.brandDark : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// The ingredients card: icon, name, quantity.
class IngredientList extends StatelessWidget {
  const IngredientList({super.key, required this.ingredients});

  final List<Ingredient> ingredients;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      clip: true,
      child: Column(
        children: [
          for (final (index, ingredient) in ingredients.indexed)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
              decoration: BoxDecoration(
                border: index == ingredients.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Text(ingredient.icon, style: TextStyle(fontSize: 20.sp)),
                  SizedBox(width: 14.w),
                  Expanded(child: Text(ingredient.name, style: AppTextStyles.ingredientName)),
                  Text(ingredient.quantity, style: AppTextStyles.ingredientQty),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Numbered preparation steps, each in its own card.
class PreparationList extends StatelessWidget {
  const PreparationList({super.key, required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 13.h),
          child: SurfaceCard(
            radius: 20.r,
            padding: EdgeInsets.symmetric(vertical: 17.h),
            onTap: () {},
            child: Text(
              '▶  ${l10n.recipeCookStepByStep}',
              textAlign: TextAlign.center,
              style: AppTextStyles.secondaryButton.copyWith(
                fontSize: 16.sp,
                color: AppColors.brandDark,
              ),
            ),
          ),
        ),
        for (final (index, step) in steps.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: 11.h),
            child: SurfaceCard(
              radius: 18.r,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(child: Text(step, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
