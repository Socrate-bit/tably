import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/model/weekday.dart';
import '../../recipe/cubit/catalogue_cubit.dart';
import '../model/preference_change.dart';
import 'chat_tool.dart';
import 'chat_tools.dart';

/// Reading and changing the user's preferences.
List<ChatTool> preferenceTools(ChatTools t) {
  Schema ids(List<String> values) => Schema.array(items: Schema.enumString(enumValues: values));

  return [
    ChatTool(
      kind: ToolKind.read,
      declaration: NoArgsDeclaration('get_preferences', "All of the user's preferences."),
      run: (args, context) async {
        final p = t.profile.state.profile;
        return ToolResult({
          'name': p.name,
          'household': p.household,
          'meals_per_day': p.mealsPerDay,
          'variety': p.variety.id,
          'days': [for (final d in p.orderedDays) d.id],
          'budget_eur_per_week': p.budget,
          'store': p.store.id,
          'language': p.languageCode,
          'cravings': [for (final c in p.cravings) c.id],
          'diets': [for (final d in p.diets) d.id],
          'allergies': [for (final a in p.allergies) a.id],
          'proteins': [for (final x in p.proteins) x.id],
          'appliances': [for (final a in p.appliances) a.id],
          'cook_time': p.cookTime,
          'custom_preferences': p.customPreferences,
        });
      },
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: FunctionDeclaration(
        'set_preferences',
        'Changes any of the user\'s preferences in one go. Give only the fields that change; a list replaces '
            'the whole list, so include what stays. custom_preferences are the user\'s own rules in their words '
            '("no coriander", "kids hate spicy food"), applied as strictly as allergies. Changing diets, '
            'allergies, proteins, appliances, cook_time, language or custom_preferences makes the current '
            'recipes outdated: then offer regenerate_week or keep_current_recipes.',
        parameters: {
          'name': Schema.string(),
          'household': Schema.integer(description: 'People eating, 1-12.'),
          'meals_per_day': Schema.integer(description: '1 = dinner only, 2 = lunch and dinner.'),
          'variety': Schema.enumString(
            enumValues: [for (final v in Variety.values) v.id],
            description: 'high: a new dish every meal; balanced: one per two meals; low: one per four meals.',
          ),
          'days': ids([for (final d in Weekday.values) d.id]),
          'budget': Schema.number(description: 'Weekly budget in euros, 40-200.'),
          'store': Schema.enumString(enumValues: [for (final s in Store.values) s.id]),
          'language': Schema.enumString(enumValues: ['fr', 'en']),
          'cravings': ids([for (final c in Craving.values) c.id]),
          'diets': ids([for (final d in Diet.values) d.id]),
          'allergies': ids([for (final a in Allergy.values) a.id]),
          'proteins': ids([for (final p in Protein.values) p.id]),
          'appliances': ids([for (final a in Appliance.values) a.id]),
          'cook_time': Schema.enumString(enumValues: PreferenceChange.cookTimes),
          'custom_preferences': Schema.array(items: Schema.string()),
        },
        optionalParameters: [
          'name',
          'household',
          'meals_per_day',
          'variety',
          'days',
          'budget',
          'store',
          'language',
          'cravings',
          'diets',
          'allergies',
          'proteins',
          'appliances',
          'cook_time',
          'custom_preferences',
        ],
      ),
      run: (args, context) async {
        final current = t.profile.state.profile;
        final change = PreferenceChange.of(current, args);
        if (change.error != null) return ToolResult({'error': change.error});
        if (change.changes.isEmpty) return const ToolResult({'unchanged': true});
        final outdates = CatalogueCubit.keyFor(change.next) != CatalogueCubit.keyFor(current);
        return ToolProposal(
          preview: {'changes': change.changes, 'recipes_outdated': outdates},
          commit: () async {
            // Built on the latest profile, in case something else changed meanwhile.
            final latest = PreferenceChange.of(t.profile.state.profile, args);
            if (latest.error != null) return {'error': latest.error};
            await t.profile.apply(latest.next, changed: latest.changes.keys.join(','));
            return {'ok': true, 'recipes_outdated': t.catalogue.state.outdated, 'week': t.weekJson()};
          },
        );
      },
    ),
  ];
}
