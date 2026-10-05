import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/line_icon.dart';
import '../../../core/widget/search_field.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan/widget/regenerate_button.dart';
import '../cubit/recipe_browse_cubit.dart';
import '../cubit/recipe_search_cubit.dart';
import '../model/recipe.dart';
import '../screen/filters_screen.dart';
import 'filter_button.dart';
import 'quota_dialog.dart';

/// Asks the API for the current search text and filters. [reload] always asks
/// again, for new results.
void searchRecipes(BuildContext context, {bool reload = false}) =>
    context.read<RecipeSearchCubit>().search(context.read<RecipeBrowseCubit>().state, reload: reload);

/// [children] with a [gap] between each.
List<Widget> withGaps(List<Widget> children, double gap) => [
  for (final (i, child) in children.indexed) ...[if (i > 0) SizedBox(height: gap), child],
];

/// Shows a failed search once: the quota pop-up, or a banner.
class RecipeSearchErrorListener extends BlocListener<RecipeSearchCubit, RecipeSearchState> {
  RecipeSearchErrorListener({super.key, super.child})
      : super(
          listenWhen: (previous, current) => current.error != null && previous.error != current.error,
          listener: (context, state) {
            showSearchError(context, state.error);
            context.read<RecipeSearchCubit>().errorShown();
          },
        );
}

/// The search box and the filter button, then "Réinitialiser les filtres"
/// while any narrows the search. Shared by the recipes tab and the replace
/// sheet, whose [compact] variant sits on white.
class RecipeSearchBar extends StatelessWidget {
  const RecipeSearchBar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final canReset = context.select<RecipeBrowseCubit, bool>((c) => c.state.canReset);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SearchField(
                hint: l10n.exploreSearchPlaceholder,
                compact: compact,
                initialValue: context.read<RecipeBrowseCubit>().state.query,
                // Typing narrows the cached pool; the search key asks the
                // API. Emptied, it falls back to the filters' own search.
                onChanged: (value) {
                  context.read<RecipeBrowseCubit>().search(value);
                  if (value.trim().isEmpty) searchRecipes(context);
                },
                onSubmitted: (_) => searchRecipes(context),
              ),
            ),
            SizedBox(width: compact ? 9.w : 10.w),
            // Opens over a sheet too, which stays open underneath.
            FilterButton(compact: compact, onPressed: () => FiltersScreen.open(context)),
          ],
        ),
        if (canReset)
          Align(
            alignment: Alignment.centerRight,
            child: _LinkButton(
              label: l10n.filtersResetAll,
              onPressed: () {
                context.read<RecipeBrowseCubit>().resetFilters();
                searchRecipes(context);
              },
            ),
          ),
      ],
    );
  }
}

/// A search's list: a prompt to search typed text, or the result count; then
/// placeholder rows while it runs, [results] built by [row], or why there are
/// none; and "Relancer la recherche" at the bottom, like the menu's regenerate.
class RecipeSearchResults extends StatelessWidget {
  const RecipeSearchResults({super.key, required this.results, required this.row, this.emptyText});

  /// What to show once searched, already filtered.
  final List<Recipe> results;
  final Widget Function(Recipe recipe) row;

  /// Replaces the default "nothing matches" text.
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final browse = context.watch<RecipeBrowseCubit>().state;
    final searchState = context.watch<RecipeSearchCubit>().state;
    final searching = searchState.isSearchingFor(browse);
    // Text typed but not searched yet (or its search failed): the pool's
    // matches under a prompt to search, never "no results" before asking.
    final pending = browse.isSearching && searchState.resultsFor(browse) == null && !searching;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending)
          _SearchPrompt(query: browse.query.trim(), onTap: () => searchRecipes(context))
        else
          Text(
            searching ? l10n.searchLoading : l10n.searchResultCount(results.length),
            style: AppTextStyles.resultCount,
          ),
        SizedBox(height: 12.h),
        if (searching)
          const _SearchingRows()
        else if (results.isNotEmpty)
          ...withGaps([for (final r in results) row(r)], 11.h)
        else if (!pending)
          RecipeListEmpty(emptyText ?? (browse.isSearching ? l10n.searchEmpty(browse.query.trim()) : l10n.filtersEmpty)),
        if (browse.canSearch && !searching && !pending)
          Padding(
            padding: EdgeInsets.only(top: 36.h, bottom: 18.h),
            child: Center(
              child: RegenerateButton(
                label: l10n.searchReload,
                regenerating: false,
                onPressed: () => searchRecipes(context, reload: true),
              ),
            ),
          ),
      ],
    );
  }
}

/// Why a recipe list is empty.
class RecipeListEmpty extends StatelessWidget {
  const RecipeListEmpty(this.text, {super.key});

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

/// A tappable link, such as "Réinitialiser les filtres".
class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onPressed();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Text(label, style: AppTextStyles.link.copyWith(fontSize: 15.sp)),
      ),
    );
  }
}

/// "Rechercher « … »": asks the API for typed text not searched yet.
class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      radius: 20.r,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
      child: Row(
        children: [
          LineIcon(LineGlyph.search, size: 20.r, color: AppColors.brand),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              AppL10n.of(context).searchPrompt(query),
              style: AppTextStyles.recipeRowTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          LineIcon(LineGlyph.chevronRight, size: 18.r, color: AppColors.chevron),
        ],
      ),
    );
  }
}

/// Shown while a search runs (the API call, then Gemini): placeholder rows
/// shaped like the results, pulsing.
class _SearchingRows extends StatefulWidget {
  const _SearchingRows();

  /// Title widths, so the placeholders don't look stamped.
  static const _widths = [0.82, 0.6, 0.74, 0.52];

  @override
  State<_SearchingRows> createState() => _SearchingRowsState();
}

class _SearchingRowsState extends State<_SearchingRows> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
    lowerBound: 0.5,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget block(double width, double height, double radius) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(radius)),
    );
    Widget bar(double widthFactor, double height) =>
        FractionallySizedBox(widthFactor: widthFactor, child: block(double.infinity, height, height / 2));

    return FadeTransition(
      opacity: _pulse,
      child: Column(
        children: withGaps([
          for (final width in _SearchingRows._widths)
            SurfaceCard(
              radius: 20.r,
              padding: EdgeInsets.all(11.r),
              child: Row(
                children: [
                  block(62.r, 62.r, 14.r),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(width, 15.h),
                        SizedBox(height: 9.h),
                        bar(0.32, 12.h),
                        SizedBox(height: 9.h),
                        bar(0.45, 11.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ], 11.h),
      ),
    );
  }
}
