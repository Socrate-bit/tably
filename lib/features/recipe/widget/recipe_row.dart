import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/recipe_photo.dart';
import '../../../core/widget/surface_card.dart';
import '../model/recipe.dart';
import 'craving_badge.dart';
import 'favourite_button.dart';

/// A recipe as a row: photo, title, badge, time and store price, plus a bookmark.
/// [large] is the variant used in the full recipe list and favourites.
class RecipeRow extends StatelessWidget {
  const RecipeRow({
    super.key,
    required this.recipe,
    required this.store,
    required this.country,
    required this.onTap,
    this.large = false,
    this.bordered = false,
  });

  final Recipe recipe;
  final Store store;
  final Country country;
  final VoidCallback onTap;
  final bool large;

  /// Inside a white sheet the row is outlined instead of filled.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final photo = large ? 82.r : 62.r;
    final divider = Text(' | ', style: AppTextStyles.rowMeta.copyWith(color: AppColors.neutralBar));
    final meta = large ? AppTextStyles.rowMetaLarge : AppTextStyles.rowMeta;
    return SurfaceCard(
      onTap: onTap,
      radius: large ? 22.r : 20.r,
      padding: EdgeInsets.all(large ? 12.r : 11.r),
      color: bordered ? Colors.transparent : AppColors.surface,
      child: Row(
        children: [
          RecipePhoto(url: recipe.photoUrl, height: photo, width: photo, radius: 14.r),
          SizedBox(width: large ? 14.w : 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: large ? AppTextStyles.mealTitle : AppTextStyles.recipeRowTitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                CravingBadge(craving: recipe.craving),
                SizedBox(height: large ? 6.h : 5.h),
                Row(
                  children: [
                    Text('🕐 ${recipe.time}', style: meta),
                    divider,
                    Text(formatMoney(country, recipe.price * store.priceFactor), style: meta),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          FavouriteButton(recipe: recipe),
        ],
      ),
    );
  }
}
