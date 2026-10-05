import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/theme/app_theme.dart';
import 'package:tably/features/chat/cubit/chat_cubit.dart';
import 'package:tably/features/chat/model/chat_message.dart';
import 'package:tably/features/chat/screen/chat_screen.dart';
import 'package:tably/features/chat/service/chat_agent_service.dart';
import 'package:tably/features/chat/service/chat_service.dart';
import 'package:tably/features/chat/tool/chat_tools.dart';
import 'package:tably/features/plan/cubit/plan_cubit.dart';
import 'package:tably/features/plan/service/plan_service.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/cubit/recipe_cubit.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/features/recipe/service/recipe_service.dart';
import 'package:tably/features/shopping/cubit/shopping_cubit.dart';
import 'package:tably/features/shopping/service/shopping_ai_service.dart';
import 'package:tably/features/shopping/service/shopping_service.dart';
import 'package:tably/l10n/app_localizations.dart';

import 'fixtures/recipe_fixtures.dart';

class _ScriptedAgent extends ChatAgentService {
  _ScriptedAgent(this.replies);

  final List<AgentReply> replies;
  bool _started = false;

  @override
  bool get isStarted => _started;

  @override
  void start({required String system, required List<Content> history, required List<FunctionDeclaration> tools}) =>
      _started = true;

  @override
  void reset() => _started = false;

  @override
  Future<AgentReply> send(String text) async => replies.removeAt(0);

  @override
  Future<AgentReply> respond(List<FunctionResponse> responses) async => replies.removeAt(0);
}

/// Writes the first fixture as the chef's recipe instead of calling Gemini.
class _WriterAi extends FakeAi {
  @override
  Future<Recipe> write(String request, UserProfile profile, {Recipe? base}) async =>
      Recipe.fromMap('custom_1', RecipeFixtures.recipes.first.withOrigin(RecipeOrigin.chef).toMap());
}

void main() {
  testWidgets('every kind of proposal renders as a card the user can answer', (tester) async {
    tester.view.physicalSize = const Size(804, 1720);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    const analytics = AnalyticsService();
    final profile = ProfileCubit(service: ProfileService(), analytics: analytics);
    final catalogue = seededCatalogue(profile);
    final recipes = RecipeCubit(service: RecipeService(), analytics: analytics);
    final plan = PlanCubit(
      service: PlanService(),
      profileCubit: profile,
      catalogueCubit: catalogue,
      recipeCubit: recipes,
      analytics: analytics,
    );
    final shopping = ShoppingCubit(
      service: ShoppingService(),
      ai: ShoppingAiService(),
      planCubit: plan,
      profileCubit: profile,
      analytics: analytics,
    );
    final quota = unboundQuota(profile);
    await profile.completeOnboarding(const UserProfile());
    await tester.pump();

    final week = plan.state.week;
    final first = week.slots.first;
    final other = RecipeFixtures.recipes.firstWhere((r) => week.slots.every((s) => s.recipe.id != r.id));
    final writes = <(String, Map<String, Object?>)>[
      ('regenerate_week', {}),
      ('change_meal', {'slot_key': first.key, 'recipe_id': other.id}),
      ('change_meal', {'slot_key': week.slots[1].key}),
      ('replace_recipe_everywhere', {'old_recipe_id': first.recipe.id, 'new_recipe_id': other.id}),
      ('swap_meals', {'slot_a': first.key, 'slot_b': week.slots.last.key}),
      ('update_recipe', {'recipe_id': other.id, 'favourite': true, 'cooked': true, 'rating': 4, 'note': 'Top'}),
      (
        'set_preferences',
        {
          'name': 'Lucas',
          'household': 4,
          'meals_per_day': 1,
          'variety': 'low',
          'days': ['monday', 'friday'],
          'budget': 80,
          'store': 'aldi',
          'language': 'en',
          'cravings': ['indulgent'],
          'diets': ['vegan'],
          'allergies': ['nut_free'],
          'proteins': ['no_meat'],
          'appliances': ['oven'],
          'cook_time': '15_30',
          'custom_preferences': ['pas de coriandre'],
        },
      ),
      (
        'edit_shopping_list',
        {
          'add': [
            {'name': 'citron', 'amount': 2, 'unit': 'piece'},
            {'name': 'lait', 'amount': 1, 'unit': 'l'},
          ],
        },
      ),
      ('share_shopping_list', {}),
      ('update_memory', {'text': 'Pas de coriandre. Les enfants détestent le piquant.'}),
      ('create_custom_recipe', {'request': 'des pâtes crémeuses', 'slot_key': first.key}),
      ('derive_recipe', {'recipe_id': first.recipe.id, 'changes': "à l'huile d'olive", 'replace_in_week': true}),
    ];
    final chat = ChatCubit(
      service: ChatService(),
      agent: _ScriptedAgent([
        (text: '', calls: [FunctionCall('show_recipes', {'recipe_ids': [other.id]}, id: 's')]),
        (
          text: 'Voici ce que je te propose.',
          calls: [for (final (i, (name, args)) in writes.indexed) FunctionCall(name, args, id: '$i')],
        ),
      ]),
      tools: ChatTools(
        profile: profile,
        catalogue: catalogue,
        plan: plan,
        recipes: recipes,
        shopping: shopping,
        search: FakeSearch(),
        ai: _WriterAi(),
        quota: quota,
        analytics: analytics,
      ),
      analytics: analytics,
    );
    for (final c in [chat, shopping, plan, recipes, catalogue, quota, profile]) {
      addTearDown(c.close);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: profile),
          BlocProvider.value(value: catalogue),
          BlocProvider.value(value: recipes),
          BlocProvider.value(value: plan),
          BlocProvider.value(value: shopping),
          BlocProvider.value(value: quota),
          BlocProvider.value(value: chat),
        ],
        child: ScreenUtilInit(
          designSize: const Size(AppDimens.designWidth, AppDimens.designHeight),
          minTextAdapt: true,
          builder: (context, _) => MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: const [
              AppL10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppL10n.supportedLocales,
            home: const ChatScreen(),
          ),
        ),
      ),
    );
    expect(find.text('Que veux-tu cuisiner ?'), findsOneWidget);

    await tester.runAsync(() => chat.send('Surprends-moi'));
    await tester.pump();

    expect(chat.state.status, ChatStatus.confirming);
    expect(chat.state.messages.where((m) => m.action?.status == ActionStatus.pending), hasLength(writes.length));
    expect(find.text('Accepter'), findsWidgets);

    // Scrolling up to the chef's text builds every card on the way.
    await tester.scrollUntilVisible(find.text('Voici ce que je te propose.'), 400, scrollable: find.byType(Scrollable).first);
    expect(find.text(other.title), findsWidgets, reason: 'the shown recipe is a card under the text');

    await tester.tap(find.text('Refuser').hitTestable().first);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text('Refusé'), findsOneWidget);
    expect(chat.state.messages.where((m) => m.action?.status == ActionStatus.pending), hasLength(writes.length - 1));
  });
}
