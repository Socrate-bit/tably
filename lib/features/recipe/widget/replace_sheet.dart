import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/app_sheet.dart';
import '../../../core/widget/search_field.dart';
import '../../../core/widget/segmented_toggle.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan/cubit/plan_cubit.dart';
import '../../plan/model/week_plan.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/model/user_profile.dart';
import '../cubit/recipe_browse_cubit.dart';
import '../cubit/recipe_cubit.dart';
import '../model/recipe.dart';
import '../screen/filters_screen.dart';
import '../service/recipe_catalogue.dart';
import 'filter_button.dart';
import 'recipe_row.dart';

/// "Remplacer par": picks a dish for the week.
///
/// Opened from a planned meal ([slot] set), the chosen recipe replaces that
/// meal. Opened from any other recipe, the list shows this week's dishes and
/// [recipe] takes the place of the one chosen.
class ReplaceSheet extends StatefulWidget {
  const ReplaceSheet({super.key, required this.recipe, this.slot});

  final Recipe recipe;
  final PlanSlot? slot;

  /// Shows the sheet; resolves to true once the week changed.
  static Future<bool> show(BuildContext context, {required Recipe recipe, PlanSlot? slot}) async =>
      await AppSheet.show<bool>(context, (_) => ReplaceSheet(recipe: recipe, slot: slot)) ?? false;

  @override
  State<ReplaceSheet> createState() => _ReplaceSheetState();
}

class _ReplaceSheetState extends State<ReplaceSheet> {
  /// Search text and the favourites toggle only live while the sheet is open.
  String _query = '';
  bool _favouritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final profile = context.select<ProfileCubit, UserProfile>((c) => c.state.profile);
    final browse = context.watch<RecipeBrowseCubit>().state;
    final recipes = context.watch<RecipeCubit>().state;
    final week = context.select<PlanCubit, WeekPlan>((c) => c.state.week);
    final slot = widget.slot;

    // Without a slot, the candidates are the dishes already in the week.
    final pool = slot != null
        ? RecipeCatalogue.recipes
        : {for (final s in week.slots.where((s) => !s.isLeftover)) s.recipe.id: s.recipe}.values.toList();
    final options = browse
        .apply(pool, store: profile.store, cravingLabel: l10n.cravingLabel, searchText: _query)
        .where((r) => !_favouritesOnly || recipes.isFavourite(r.id))
        .where((r) => slot != null || r.id != widget.recipe.id)
        .toList();

    return AppSheet(
      title: l10n.replaceTitle,
      subtitle: slot != null ? l10n.replaceSubtitleSlot(l10n.dayName(slot.day)) : l10n.replaceSubtitleWeek,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SearchField(
                  hint: l10n.exploreSearchPlaceholder,
                  compact: true,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              SizedBox(width: 9.w),
              FilterButton(
                compact: true,
                onPressed: () {
                  Navigator.of(context).pop(false);
                  FiltersScreen.open(context);
                },
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SegmentedToggle(
            first: l10n.replaceAll,
            second: l10n.replaceFavourites,
            firstSelected: !_favouritesOnly,
            compact: true,
            onChanged: (all) => setState(() => _favouritesOnly = !all),
          ),
          SizedBox(height: 14.h),
          Expanded(
            child: options.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 26.h),
                    child: Text(
                      _favouritesOnly ? l10n.replaceEmptyFavourites : l10n.replaceEmptySearch,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.meta.copyWith(color: AppColors.textQuaternary, fontSize: 15.sp),
                    ),
                  )
                : ListView.separated(
                    itemCount: options.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (context, i) => RecipeRow(
                      recipe: options[i],
                      store: profile.store,
                      country: profile.country,
                      bordered: true,
                      onTap: () => _choose(options[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _choose(Recipe chosen) {
    Haptics.confirm();
    final plan = context.read<PlanCubit>();
    final slot = widget.slot;
    slot != null ? plan.replace(slot.key, chosen.id) : plan.replaceRecipe(chosen.id, widget.recipe.id);
    Navigator.of(context).pop(true);
  }
}
