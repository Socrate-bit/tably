import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/line_icon.dart';
import '../cubit/recipe_cubit.dart';

/// The heart on a recipe row: tinted and filled when the recipe is a favourite.
class FavouriteButton extends StatelessWidget {
  const FavouriteButton({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final favourite = context.select<RecipeCubit, bool>((c) => c.state.isFavourite(recipeId));
    return GestureDetector(
      onTap: () {
        Haptics.toggle();
        context.read<RecipeCubit>().toggleFavourite(recipeId);
      },
      child: Container(
        width: 34.r,
        height: 34.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: favourite ? AppColors.brandSoft : AppColors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: LineIcon(
          LineGlyph.heart,
          size: 18.r,
          color: favourite ? AppColors.brand : AppColors.textDisabled,
          filled: favourite,
        ),
      ),
    );
  }
}
