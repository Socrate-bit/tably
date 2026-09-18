import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/check_circle.dart';
import '../../../core/widget/circle_icon_button.dart';
import '../../../core/widget/primary_button.dart';
import '../../../core/widget/recipe_photo.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/recipe_cubit.dart';
import '../model/recipe.dart';
import '../widget/macro_card.dart';
import '../widget/recipe_tabs.dart';

/// Full recipe view: photo, macros, notes card, ingredients/preparation tabs
/// and the user's own note.
class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  /// Which tab is showing — local because it never needs to outlive the screen.
  bool _showIngredients = true;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final note = context.read<RecipeCubit>().state.interactionFor(widget.recipeId).note;
    _noteController = TextEditingController(text: note);
  }

  @override
  void dispose() {
    // Persist whatever the user typed when they leave the screen.
    context.read<RecipeCubit>().setNote(widget.recipeId, _noteController.text);
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: BlocBuilder<RecipeCubit, RecipeState>(
          builder: (context, state) {
            final recipe = state.byId(widget.recipeId);
            if (recipe == null) {
              return Center(
                child: CircleIconButton(
                  glyph: '←',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              );
            }
            final interaction = state.interactionFor(recipe.id);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PhotoHeader(
                    recipe: recipe,
                    favourite: interaction.favourite,
                    onBack: () => Navigator.of(context).pop(),
                    onFavourite: () => context.read<RecipeCubit>().toggleFavourite(recipe.id),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(6.w, 22.h, 6.w, 18.h),
                    child: Text(
                      recipe.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.recipeTitle,
                    ),
                  ),
                  MacroCard(macros: recipe.macros),
                  SizedBox(height: 14.h),
                  _NotesCard(
                    recipe: recipe,
                    cooked: interaction.cooked,
                    rating: interaction.rating,
                    onToggleCooked: () => context.read<RecipeCubit>().toggleCooked(recipe.id),
                    onRate: (value) => context.read<RecipeCubit>().setRating(recipe.id, value),
                  ),
                  SizedBox(height: 18.h),
                  RecipeSegmentedTabs(
                    showIngredients: _showIngredients,
                    onChanged: (value) {
                      Haptics.tap();
                      setState(() => _showIngredients = value);
                    },
                  ),
                  SizedBox(height: 16.h),
                  if (_showIngredients)
                    IngredientList(ingredients: recipe.ingredients)
                  else
                    PreparationList(steps: recipe.steps),
                  SizedBox(height: 24.h),
                  Text(
                    l10n.recipeYourNotes,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sheetTitle,
                  ),
                  SizedBox(height: 12.h),
                  _NoteField(controller: _noteController),
                  SizedBox(height: 18.h),
                  PrimaryButton(
                    label: l10n.recipeAddToWeek,
                    fontSize: 17,
                    verticalPadding: 19.h,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Hero image with the back and favourite buttons floating over it.
class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({
    required this.recipe,
    required this.favourite,
    required this.onBack,
    required this.onFavourite,
  });

  final Recipe recipe;
  final bool favourite;
  final VoidCallback onBack;
  final VoidCallback onFavourite;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RecipePhoto(photoKey: recipe.photoKey, height: 300.h, radius: 22.r),
        Positioned(
          top: 16.h,
          left: 16.w,
          child: CircleIconButton(
            glyph: '←',
            size: 44.r,
            showBorder: false,
            onPressed: onBack,
          ),
        ),
        Positioned(
          top: 16.h,
          right: 16.w,
          child: CircleIconButton(
            glyph: favourite ? '♥' : '♡',
            size: 44.r,
            showBorder: false,
            foreground: favourite ? AppColors.brand : AppColors.ink,
            onPressed: onFavourite,
          ),
        ),
      ],
    );
  }
}

/// Cook time, servings, the cooked toggle and the star rating.
class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.recipe,
    required this.cooked,
    required this.rating,
    required this.onToggleCooked,
    required this.onRate,
  });

  final Recipe recipe;
  final bool cooked;
  final int rating;
  final VoidCallback onToggleCooked;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return SurfaceCard(
      padding: EdgeInsets.all(18.r),
      child: Column(
        children: [
          Text(l10n.recipeNotesLabel, style: AppTextStyles.cardLabelBrand),
          SizedBox(height: 14.h),
          Text(
            l10n.recipeCookTimeAndServings(recipe.cookTime, recipe.servings),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.only(top: 14.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      Haptics.toggle();
                      onToggleCooked();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckCircle(
                          checked: cooked,
                          size: 26.r,
                          uncheckedGlyphColor: AppColors.chevron,
                        ),
                        SizedBox(width: 11.w),
                        Flexible(
                          child: Text(
                            l10n.recipeMarkCooked,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.inkStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                _StarRating(rating: rating, onRate: onRate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, required this.onRate});

  final int rating;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          GestureDetector(
            onTap: () {
              Haptics.toggle();
              onRate(star);
            },
            child: Padding(
              padding: EdgeInsets.only(left: 3.w),
              child: Text(
                star <= rating ? '★' : '☆',
                style: TextStyle(
                  fontSize: 17.sp,
                  height: 1,
                  color: star <= rating ? AppColors.star : AppColors.neutralBar,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20.r),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 6,
      style: AppTextStyles.noteInput,
      decoration: InputDecoration(
        hintText: AppL10n.of(context).recipeNotePlaceholder,
        hintStyle: AppTextStyles.noteInput.copyWith(color: AppColors.textDisabled),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.all(16.r),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}
