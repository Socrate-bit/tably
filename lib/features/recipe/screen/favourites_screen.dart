import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/line_icon.dart';
import '../../../core/widget/sub_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/cubit/home_cubit.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/model/user_profile.dart';
import '../cubit/catalogue_cubit.dart';
import '../cubit/recipe_cubit.dart';
import '../widget/recipe_row.dart';
import 'recipe_screen.dart';

/// "Favoris": every recipe the user has bookmarked.
class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final profile = context.select<ProfileCubit, UserProfile>((c) => c.state.profile);
    final catalogue = context.watch<CatalogueCubit>().state.recipes;
    final favourites = context.watch<RecipeCubit>().state.favouritesIn(catalogue);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, AppDimens.tabBarInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SubScreenHeader(
            title: l10n.favouritesTitle,
            subtitle: l10n.favouritesCount(favourites.length),
            onBack: context.read<HomeCubit>().closeSub,
          ),
          SizedBox(height: 18.h),
          if (favourites.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 50.h),
              child: Column(
                children: [
                  LineIcon(LineGlyph.bookmark, size: 52.r, color: AppColors.emptyStateIcon, strokeWidth: 1.6),
                  SizedBox(height: 14.h),
                  Text(
                    l10n.favouritesEmpty,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.meta.copyWith(color: AppColors.textQuaternary, fontSize: 15.sp, height: 1.5),
                  ),
                ],
              ),
            )
          else
            for (final (i, recipe) in favourites.indexed) ...[
              if (i > 0) SizedBox(height: 11.h),
              RecipeRow(
                recipe: recipe,
                store: profile.store,
                country: profile.country,
                large: true,
                onTap: () => RecipeScreen.open(context, recipeId: recipe.id),
              ),
            ],
        ],
      ),
    );
  }
}
