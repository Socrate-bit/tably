import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/ingredient_unit.dart';
import '../../../core/model/meal_slot.dart';
import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/model/weekday.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/util/quantity.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/widget/steps/language_step.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/model/user_profile.dart';
import '../../shopping/screen/shopping_screen.dart';
import '../cubit/chat_cubit.dart';
import '../model/chat_message.dart';
import 'chat_recipe_card.dart';

/// A change the chef proposed, spelled out from what will actually run,
/// with Approve and Decline while it waits, then how it went.
class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final action = message.action!;
    final country = context.select((ProfileCubit c) => c.state.profile.country);
    final (title, details) = _describe(l10n, action.tool, action.preview, country);
    return SurfaceCard(
      radius: AppDimens.radiusCardSmall,
      color: AppColors.surfaceTinted,
      borderColor: action.status == ActionStatus.pending ? AppColors.brandSoftBorder : AppColors.border,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.chatActionEyebrow, style: AppTextStyles.cardLabelInfo),
          SizedBox(height: 6.h),
          Text(title, style: AppTextStyles.listItemTitle),
          for (final line in details) ...[SizedBox(height: 4.h), Text(line, style: AppTextStyles.bodyMuted)],
          for (final recipe in message.recipes) ...[
            SizedBox(height: 10.h),
            ChatRecipeCard(recipe: recipe, inWeek: false),
          ],
          SizedBox(height: 14.h),
          _Footer(message: message),
        ],
      ),
    );
  }

  /// The card's title and detail lines for [tool], from its [preview].
  static (String, List<String>) _describe(AppL10n l10n, String tool, Map<String, Object?> preview, Country country) {
    String day(Object? id) => l10n.dayName(Weekday.fromId('$id'));
    String meal(Object? id) =>
        l10n.slotName(MealSlot.values.firstWhere((s) => s.id == id, orElse: () => MealSlot.dinner));
    Map<String, Object?> map(Object? value) => Map<String, Object?>.from(value as Map? ?? const {});
    List<Object?> list(Object? value) => value as List? ?? const [];

    return switch (tool) {
      'regenerate_week' => (l10n.chatActRegenerateWeek, [l10n.chatDetailRegenerateWeek]),
      // One meal reads as before; several list one line per meal. Cards
      // saved before change_meals carry a single meal at the top level.
      'change_meals' || 'change_meal' => switch (tool == 'change_meal' ? [preview] : [...list(preview['meals']).map(map)]) {
        [final one] when one['to'] == null => (
          l10n.chatActRerollMeal(day(one['day']), meal(one['meal'])),
          ['${one['title']}'],
        ),
        [final one] => (l10n.chatActChangeMeal(day(one['day']), meal(one['meal'])), ['${one['title']} → ${one['to']}']),
        final meals => (
          l10n.chatActChangeMeals(meals.length),
          [
            for (final m in meals)
              '${day(m['day'])} (${meal(m['meal'])}) : ${m['title']} → ${m['to'] ?? l10n.chatDetailRandomDish}',
          ],
        ),
      },
      'replace_recipe_everywhere' => (
        l10n.chatActReplaceEverywhere((preview['meals'] as num?)?.toInt() ?? 1),
        ['${preview['from']} → ${preview['to']}'],
      ),
      'swap_meals' => (
        l10n.chatActSwapMeals,
        [
          for (final side in [map(preview['a']), map(preview['b'])])
            '${day(side['day'])} (${meal(side['meal'])}) : ${side['title']}',
        ],
      ),
      'keep_current_recipes' => (l10n.chatActKeepRecipes, const []),
      'update_recipe' => (
        '${preview['title']}',
        [
          if (preview['favourite'] case final bool f) f ? l10n.chatDetailFavourite : l10n.chatDetailUnfavourite,
          if (preview['cooked'] case final bool c) c ? l10n.chatDetailCooked : l10n.chatDetailNotCooked,
          if (preview['rating'] case final num r) r > 0 ? l10n.chatDetailRating(r.toInt()) : l10n.chatDetailNoRating,
          if (preview['note'] case final String n) l10n.chatDetailNote(n),
        ],
      ),
      'set_preferences' => (
        l10n.chatActPreferences,
        [
          for (final MapEntry(:key, :value) in map(preview['changes']).entries)
            _preferenceLine(l10n, key, map(value), country),
          if (preview['recipes_outdated'] == true) l10n.chatDetailOutdated,
        ],
      ),
      'edit_shopping_list' => (
        l10n.chatActShopping,
        [
          for (final item in list(preview['add'])) '+ ${_item(l10n, map(item))}',
          for (final name in list(preview['remove'])) '− $name',
          for (final item in list(preview['update'])) '${map(item)['from']} → ${_item(l10n, map(item))}',
          for (final name in list(preview['check'])) '✓ $name',
          for (final name in list(preview['uncheck'])) '○ $name',
        ],
      ),
      'update_memory' => (
          l10n.chatActMemory,
          [
            '${preview['to']}'.isEmpty ? l10n.chatDetailMemoryCleared : '${preview['to']}',
            if ('${preview['from']}'.isNotEmpty) l10n.chatDetailMemoryWas('${preview['from']}'),
          ],
        ),
      'share_shopping_list' => (l10n.chatActShare, const []),
      'create_custom_recipe' => (
        l10n.chatActCreateRecipe,
        [if (preview['day'] != null) l10n.chatDetailInMeal(day(preview['day']))],
      ),
      'derive_recipe' => (
        l10n.chatActDeriveRecipe('${preview['base_title']}'),
        [if (preview['replace_in_week'] == true) l10n.chatDetailReplaceInWeek],
      ),
      _ => (tool, const []),
    };
  }

  /// "Régimes : + végétarien, − aucun" or "Taille du foyer : 2 → 4".
  static String _preferenceLine(AppL10n l10n, String field, Map<String, Object?> change, Country country) {
    String label(Object? value) => switch ((field, value)) {
      (_, null) => '—',
      ('days', _) => l10n.dayName(Weekday.fromId('$value')),
      ('variety', _) => l10n.varietyName(Variety.values.firstWhere((v) => v.id == value)),
      ('meals_per_day', final num n) => l10n.mealsPerDayDetail(n.toInt()),
      ('budget', final num n) => formatMoney(country, n.toDouble(), decimals: 0),
      ('store', _) => Store.fromId('$value').displayName,
      ('language', _) => languageFor('$value').name,
      ('cook_minutes', final num n) => n >= UserProfile.cookMinutesCeiling ? l10n.cookTimeNoLimit : l10n.cookTimeMinutes('${n.toInt()}'),
          ('name' || 'household', _) => '$value',
      _ => l10n.optionLabel('$value'),
    };
    final name = switch (field) {
      'name' => l10n.chatFieldName,
      'household' => l10n.prefsHousehold,
      'meals_per_day' => l10n.prefsMealsPerDay,
      'variety' => l10n.prefsVariety,
      'days' => l10n.prefsCookingDays,
      'budget' => l10n.prefsBudget,
      'store' => l10n.prefsStore,
      'language' => l10n.chatFieldLanguage,
      'cravings' => l10n.prefsCravings,
      'diets' => l10n.prefsDiet,
      'allergies' => l10n.prefsAllergens,
      'proteins' => l10n.prefsProteins,
      'appliances' => l10n.prefsAppliances,
      'cook_minutes' => l10n.cookTimeTitle,
      _ => field,
    };
    if (change.containsKey('from')) return l10n.chatFieldChange(name, '${label(change['from'])} → ${label(change['to'])}');
    final added = [for (final v in change['added'] as List? ?? const []) '+ ${label(v)}'];
    final removed = [for (final v in change['removed'] as List? ?? const []) '− ${label(v)}'];
    return l10n.chatFieldChange(name, [...added, ...removed].join(', '));
  }

  /// "citrons (2)" for a shopping line.
  static String _item(AppL10n l10n, Map<String, Object?> item) {
    final amount = (item['amount'] as num?)?.toDouble() ?? 0;
    final unit = IngredientUnit.fromId(item['unit'] as String?);
    final quantity = formatQuantity(amount, unit, l10n);
    return amount > 0 && quantity.isNotEmpty ? '${item['name']} ($quantity)' : '${item['name']}';
  }
}

/// Approve / Decline while pending, then how it went.
class _Footer extends StatelessWidget {
  const _Footer({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final action = message.action!;
    final cubit = context.read<ChatCubit>();
    switch (action.status) {
      case ActionStatus.pending:
        return Row(
          children: [
            Expanded(
              child: _Button(
                label: l10n.chatDecline,
                onTap: () {
                  Haptics.tap();
                  cubit.decline(message.id);
                },
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              // Builder gives the button's own context to anchor the share popover.
              child: Builder(
                builder: (buttonContext) => _Button(
                  label: l10n.chatApprove,
                  primary: true,
                  onTap: () {
                    Haptics.confirm();
                    cubit.approve(
                      message.id,
                      run: action.tool == 'share_shopping_list'
                          ? () async =>
                                await ShoppingScreen.share(buttonContext) ? {'ok': true} : {'error': 'not_shared'}
                          : null,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      case ActionStatus.running:
        return Row(
          children: [
            SizedBox(
              width: 16.r,
              height: 16.r,
              child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
            ),
            SizedBox(width: 10.w),
            Text(l10n.chatStatusRunning, style: AppTextStyles.metaMuted),
          ],
        );
      case ActionStatus.approved || ActionStatus.declined || ActionStatus.failed || ActionStatus.expired:
        final (text, color) = switch (action.status) {
          ActionStatus.approved => (l10n.chatStatusApproved, AppColors.brandDark),
          ActionStatus.declined => (l10n.chatStatusDeclined, AppColors.textTertiary),
          ActionStatus.failed => (l10n.chatStatusFailed, AppColors.danger),
          _ => (l10n.chatStatusExpired, AppColors.textTertiary),
        };
        return Text(text, style: AppTextStyles.secondaryButton.copyWith(color: color));
    }
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onTap, this.primary = false});

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? AppColors.brand : AppColors.surface,
          border: primary ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimens.radiusTile),
        ),
        child: Text(
          label,
          style: AppTextStyles.secondaryButton.copyWith(color: primary ? AppColors.surface : AppColors.ink),
        ),
      ),
    );
  }
}
