import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan/widget/week_meal_sheet.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../recipe/model/recipe.dart';
import '../../recipe/screen/recipe_screen.dart';
import '../../recipe/widget/recipe_row.dart';

/// A recipe the chef suggested: opens on tap, saves with the bookmark, and
/// [inWeek] offers to put it in the week in place of a planned dish.
class ChatRecipeCard extends StatelessWidget {
  const ChatRecipeCard({super.key, required this.recipe, this.inWeek = true});

  final Recipe recipe;
  final bool inWeek;

  @override
  Widget build(BuildContext context) {
    final profile = context.select((ProfileCubit c) => c.state.profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecipeRow(
          recipe: recipe,
          store: profile.store,
          country: profile.country,
          onTap: () => RecipeScreen.open(context, recipeId: recipe.id),
        ),
        if (inWeek)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Haptics.tap();
                WeekMealSheet.show(context, recipe: recipe);
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 8.h, 6.w, 2.h),
                child: Text(AppL10n.of(context).chatAddToWeek, style: AppTextStyles.link.copyWith(fontSize: 14.sp)),
              ),
            ),
          ),
      ],
    );
  }
}
