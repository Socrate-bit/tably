import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/model/weekday.dart';
import '../../recipe/cubit/catalogue_cubit.dart';
import '../../preferences/model/user_profile.dart';
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
          'cook_minutes_max': p.hasCookLimit ? p.cookMinutes : null,
          'custom_instructions': p.customInstructions,
        });
      },
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: FunctionDeclaration(
        'set_preferences',
        'Changes any of the user\'s preferences in one go. Give only the fields that change; a list replaces '
            'the whole list, so include what stays. Changing diets, allergies, proteins, appliances, '
            'cook_minutes or language makes the current '
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
          'cook_minutes': Schema.integer(description: 'Longest a recipe may take, 15-90; 90 means no limit.'),
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
          'cook_minutes',
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
    ChatTool(
      kind: ToolKind.write,
      declaration: FunctionDeclaration(
        'update_memory',
        "Rewrites the user's custom instructions: your long-term memory of them, which they can read and edit "
            'in the app, and which also guides every recipe they get. Use it when they share something lasting '
            '(tastes, dislikes, who they cook for, goals, kitchen quirks) or ask you to remember or forget '
            'something. Give the whole new text: keep what still holds and change only what is new, in their '
            'language, as short notes, ${UserProfile.customInstructionsMax} characters at most. Saving it makes the '
            'current recipes outdated: then offer regenerate_week or keep_current_recipes.',
        parameters: {'text': Schema.string(description: 'The complete new instructions; empty forgets everything.')},
      ),
      run: (args, context) async {
        final text = (args['text'] as String? ?? '').trim();
        if (text.length > UserProfile.customInstructionsMax) {
          return ToolResult({'error': 'too_long', 'max_characters': UserProfile.customInstructionsMax, 'length': text.length});
        }
        final current = t.profile.state.profile.customInstructions;
        if (text == current) return const ToolResult({'unchanged': true});
        return ToolProposal(
          preview: {'from': current, 'to': text},
          commit: () async {
            await t.profile.setCustomInstructions(text);
            return {'ok': true, 'memory': t.profile.state.profile.customInstructions, 'recipes_outdated': t.catalogue.state.outdated};
          },
        );
      },
    ),
  ];
}
