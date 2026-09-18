import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/circle_icon_button.dart';
import '../../../core/widget/recipe_photo.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/recipe_cubit.dart';
import '../model/recipe.dart';
import '../service/recipe_catalogue.dart';
import 'recipe_screen.dart';

/// The recipes tab: search, cravings, cuisines and recently viewed.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return BlocBuilder<RecipeCubit, RecipeState>(
      builder: (context, state) {
        final cubit = context.read<RecipeCubit>();
        // The cravings grid collapses to the first four.
        final cravings = state.cravingsExpanded
            ? Craving.values
            : Craving.values.take(4).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.exploreEyebrow, style: AppTextStyles.eyebrow, textAlign: TextAlign.center),
              SizedBox(height: 2.h),
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(l10n.exploreTitle, style: AppTextStyles.screenTitle),
                  Positioned(
                    right: 0,
                    child: CircleIconButton(
                      glyph: '♡',
                      size: 48.r,
                      fontSize: 19,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              _SearchField(onChanged: cubit.search),
              SizedBox(height: 26.h),

              // Search replaces the browse sections while a query is active.
              if (state.query.trim().isNotEmpty)
                _SearchResults(results: state.searchResults)
              else ...[
                _SectionHeader(
                  title: l10n.exploreCravings,
                  action: state.cravingsExpanded ? l10n.exploreSeeLess : l10n.exploreSeeMore,
                  onAction: () {
                    Haptics.tap();
                    cubit.toggleCravingsExpanded();
                  },
                ),
                SizedBox(height: 14.h),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14.w,
                  mainAxisSpacing: 14.h,
                  childAspectRatio: 1.55,
                  children: [
                    for (final craving in cravings)
                      SurfaceCard(
                        radius: 20.r,
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
                        onTap: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(craving.icon, style: TextStyle(fontSize: 26.sp, height: 1)),
                            SizedBox(height: 10.h),
                            Text(
                              l10n.optionLabel(craving.id),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.optionGrid,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 30.h),
                Text(l10n.exploreByCuisine, style: AppTextStyles.sectionTitle),
                SizedBox(height: 14.h),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14.w,
                  mainAxisSpacing: 14.h,
                  childAspectRatio: 0.98,
                  children: [
                    for (final cuisine in RecipeCatalogue.cuisines) _CuisineCard(cuisine: cuisine),
                  ],
                ),
                SizedBox(height: 30.h),
                Text(l10n.exploreRecent, style: AppTextStyles.sectionTitle),
                SizedBox(height: 14.h),
                _RecentRail(recipes: state.recentlyViewed),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(32.r),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return TextField(
      onChanged: onChanged,
      style: AppTextStyles.searchInput,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: AppL10n.of(context).exploreSearchPlaceholder,
        hintStyle: AppTextStyles.searchInput.copyWith(color: AppColors.textDisabled),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, required this.onAction});

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        GestureDetector(onTap: onAction, child: Text(action, style: AppTextStyles.link)),
      ],
    );
  }
}

class _CuisineCard extends StatelessWidget {
  const _CuisineCard({required this.cuisine});

  final Cuisine cuisine;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 20.r,
      clip: true,
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecipePhoto(photoKey: cuisine.photoKey, height: 116.h, radius: 0),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cuisine.name, style: AppTextStyles.optionGrid),
                  SizedBox(height: 3.h),
                  Flexible(
                    child: Text(
                      cuisine.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.metaSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal rail of recently opened recipes.
class _RecentRail extends StatelessWidget {
  const _RecentRail({required this.recipes});

  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        separatorBuilder: (_, _) => SizedBox(width: 14.w),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return GestureDetector(
            onTap: () => _open(context, recipe.id),
            child: SizedBox(
              width: 162.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecipePhoto(photoKey: recipe.photoKey, height: 116.h, width: 162.w),
                  SizedBox(height: 8.h),
                  Flexible(
                    child: Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text('🕐 ${recipe.cookTime}', style: AppTextStyles.metaSmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Results list shown while the search box has a query.
class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results});

  final List<Recipe> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final recipe in results)
          Padding(
            padding: EdgeInsets.only(bottom: 13.h),
            child: SurfaceCard(
              radius: 20.r,
              padding: EdgeInsets.all(12.r),
              onTap: () => _open(context, recipe.id),
              child: Row(
                children: [
                  RecipePhoto(photoKey: recipe.photoKey, height: 64.r, width: 64.r, radius: 14.r),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(recipe.title, style: AppTextStyles.mealTitle),
                        SizedBox(height: 4.h),
                        Text('🕐 ${recipe.cookTime}', style: AppTextStyles.metaSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Opens a recipe and records the view.
void _open(BuildContext context, String recipeId) {
  Haptics.tap();
  context.read<RecipeCubit>().markViewed(recipeId);
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => RecipeScreen(recipeId: recipeId)),
  );
}
