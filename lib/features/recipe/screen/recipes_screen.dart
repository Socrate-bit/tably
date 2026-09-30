import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/circle_icon_button.dart';
import '../../../core/widget/count_badge.dart';
import '../../../core/widget/line_icon.dart';
import '../../../core/widget/recipe_photo.dart';
import '../../../core/widget/search_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/cubit/home_cubit.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/model/user_profile.dart';
import '../cubit/catalogue_cubit.dart';
import '../cubit/recipe_browse_cubit.dart';
import '../cubit/recipe_cubit.dart';
import '../model/recipe.dart';
import '../widget/filter_button.dart';
import '../widget/recipe_row.dart';
import 'filters_screen.dart';
import 'recipe_screen.dart';

/// The "Recettes" tab: search, filters, recently viewed and every recipe.
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final profile = context.select<ProfileCubit, UserProfile>((c) => c.state.profile);
    final browse = context.watch<RecipeBrowseCubit>().state;
    final recipeState = context.watch<RecipeCubit>().state;
    final catalogue = context.watch<CatalogueCubit>().state.recipes;
    final results = browse.apply(catalogue, store: profile.store, cravingLabel: l10n.cravingLabel);
    final favourites = recipeState.favouritesIn(catalogue);
    final recentlyViewed = recipeState.recentlyViewedIn(catalogue);

    Widget row(Recipe recipe, {bool large = false}) => RecipeRow(
          recipe: recipe,
          store: profile.store,
          country: profile.country,
          large: large,
          onTap: () => RecipeScreen.open(context, recipeId: recipe.id),
        );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, AppDimens.tabBarInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.recipesTitle, style: AppTextStyles.tabTitle)),
              CountBadge(
                count: favourites.length,
                child: CircleIconButton(
                  icon: LineIcon(LineGlyph.heart, size: 20.r, color: AppColors.ink),
                  onPressed: () => context.read<HomeCubit>().open(HomeSub.favourites),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: SearchField(
                  hint: l10n.exploreSearchPlaceholder,
                  initialValue: browse.query,
                  onChanged: context.read<RecipeBrowseCubit>().search,
                ),
              ),
              SizedBox(width: 10.w),
              FilterButton(onPressed: () => FiltersScreen.open(context)),
            ],
          ),
          SizedBox(height: 26.h),
          if (browse.isSearching) ...[
            Text(l10n.searchResultCount(results.length), style: AppTextStyles.resultCount),
            SizedBox(height: 12.h),
            if (results.isEmpty)
              _EmptyText(l10n.searchEmpty(browse.query.trim()))
            else
              ..._separated([for (final r in results) row(r)], 11.h),
          ] else ...[
            // Hidden until the user has opened a recipe.
            if (recentlyViewed.isNotEmpty) ...[
              Text(l10n.exploreRecent, style: AppTextStyles.sectionTitle),
              SizedBox(height: 14.h),
              SizedBox(
                // Photo, a two-line name and the time line.
                height: 184.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentlyViewed.length,
                  separatorBuilder: (_, _) => SizedBox(width: 14.w),
                  itemBuilder: (context, i) => _RecentCard(recipe: recentlyViewed[i]),
                ),
              ),
              SizedBox(height: 30.h),
            ],
            Text(l10n.recipesAll, style: AppTextStyles.sectionTitle),
            SizedBox(height: 14.h),
            if (results.isEmpty)
              _EmptyText(l10n.filtersEmpty)
            else
              ..._separated([for (final r in results) row(r, large: true)], 11.h),
          ],
        ],
      ),
    );
  }

  static List<Widget> _separated(List<Widget> children, double gap) => [
        for (final (i, child) in children.indexed) ...[if (i > 0) SizedBox(height: gap), child],
      ];
}

/// A card in the "Consultés récemment" rail.
class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => RecipeScreen.open(context, recipeId: recipe.id),
      child: SizedBox(
        width: 162.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipePhoto(url: recipe.photoUrl, height: 104.h, width: 162.w, radius: 16.r),
            SizedBox(height: 8.h),
            Text(recipe.title, style: AppTextStyles.recentName, maxLines: 2, overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.h),
            Text('🕐 ${recipe.time}', style: AppTextStyles.metaSmall),
          ],
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.meta.copyWith(color: AppColors.textQuaternary, fontSize: 15.sp, height: 1.5),
      ),
    );
  }
}
