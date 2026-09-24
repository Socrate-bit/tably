import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../model/recipe.dart';

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
                  Text(ingredient.icon, style: AppTextStyles.emojiIcon.copyWith(fontSize: 20.sp)),
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
