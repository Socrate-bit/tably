import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/app_sheet.dart';
import '../../../core/widget/segmented_toggle.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan/cubit/plan_cubit.dart';
import '../../plan/model/week_plan.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/model/user_profile.dart';
import '../cubit/catalogue_cubit.dart';
import '../cubit/recipe_browse_cubit.dart';
import '../cubit/recipe_cubit.dart';
import '../cubit/recipe_search_cubit.dart';
import '../model/recipe.dart';
import 'recipe_row.dart';
import 'recipe_search_results.dart';

/// "Remplacer par": picks the dish that replaces the planned meal [slot].
/// Searches like the recipes tab, whose search and filters it shares: typing
/// narrows the list, the search key asks the API, and the filters open over
/// the sheet.
class ReplaceSheet extends StatefulWidget {
  const ReplaceSheet({super.key, required this.slot});

  final PlanSlot slot;

  /// Shows the sheet; resolves to true once the meal was replaced.
  static Future<bool> show(BuildContext context, {required PlanSlot slot}) async =>
      await AppSheet.show<bool>(context, (_) => ReplaceSheet(slot: slot)) ?? false;

  @override
  State<ReplaceSheet> createState() => _ReplaceSheetState();
}

class _ReplaceSheetState extends State<ReplaceSheet> {
  /// The favourites toggle only lives while the sheet is open.
  bool _favouritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final profile = context.select<ProfileCubit, UserProfile>((c) => c.state.profile);
    final browse = context.watch<RecipeBrowseCubit>().state;
    final recipes = context.watch<RecipeCubit>().state;
    final searchState = context.watch<RecipeSearchCubit>().state;

    // API results for exactly this search; otherwise the catalogue plus saved
    // favourites the user may pick even if they left it.
    final found = searchState.resultsFor(browse);
    final pool = found ??
        {
          for (final r in context.watch<CatalogueCubit>().state.recipes) r.id: r,
          for (final r in recipes.savedFavourites) r.id: r,
        }.values.toList();
    final options = browse
        .apply(pool, store: profile.store, cravingLabel: l10n.cravingLabel, searched: found != null)
        .where((r) => !_favouritesOnly || recipes.isFavourite(r.id))
        .toList();
    final emptyText = _favouritesOnly ? l10n.replaceEmptyFavourites : null;

    Widget row(Recipe recipe) => RecipeRow(
      recipe: recipe,
      store: profile.store,
      country: profile.country,
      bordered: true,
      onTap: () => _choose(recipe),
    );

    return AppSheet(
      title: l10n.replaceTitle,
      subtitle: l10n.replaceSubtitleSlot(l10n.dayName(widget.slot.day)),
      child: RecipeSearchErrorListener(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RecipeSearchBar(compact: true),
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
              child: SingleChildScrollView(
                child: searchState.showsSearch(browse)
                    ? RecipeSearchResults(results: options, row: row, emptyText: emptyText)
                    : options.isEmpty
                        ? RecipeListEmpty(emptyText ?? l10n.filtersEmpty)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: withGaps([for (final r in options) row(r)], 10.h),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _choose(Recipe chosen) {
    Haptics.confirm();
    context.read<PlanCubit>().replace(widget.slot.key, chosen);
    Navigator.of(context).pop(true);
  }
}
