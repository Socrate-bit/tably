import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/features/chat/cubit/chat_cubit.dart';
import 'package:tably/features/chat/model/chat_message.dart';
import 'package:tably/features/chat/service/chat_agent_service.dart';
import 'package:tably/features/chat/tool/chat_tool.dart';
import 'package:tably/features/chat/tool/chat_tools.dart';
import 'package:tably/features/plan/cubit/plan_cubit.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/recipe/cubit/search_quota_cubit.dart';
import 'package:tably/features/recipe/model/recipe.dart';

import 'fixtures/chat_fixtures.dart';
import 'fixtures/recipe_fixtures.dart';

/// Plays scripted model replies and records what the cubit sent back.
class _FakeAgent extends ChatAgentService {
  _FakeAgent(this.replies);

  final List<AgentReply> replies;

  /// The user's texts and the tool answers, in order.
  final sent = <Object>[];
  bool _started = false;

  @override
  bool get isStarted => _started;

  /// The history the last conversation started with.
  List<Content> history = const [];

  @override
  void start({required String system, required List<Content> history, required List<FunctionDeclaration> tools}) {
    _started = true;
    this.history = history;
  }

  @override
  void reset() => _started = false;

  @override
  Future<AgentReply> send(String text) async {
    sent.add(text);
    return replies.removeAt(0);
  }

  @override
  Future<AgentReply> respond(List<FunctionResponse> responses) async {
    sent.add(responses);
    return replies.removeAt(0);
  }
}

const _noContext = ToolContext(recipe: _none, remember: _ignore, show: _ignore);
Recipe? _none(String id) => null;
void _ignore(List<Recipe> recipes) {}

AgentReply _calls(List<FunctionCall> calls) => (text: '', calls: calls);
AgentReply _text(String text) => (text: text, calls: const []);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileCubit profile;
  late PlanCubit plan;

  late ChatTools tools;

  Future<(ChatCubit, _FakeAgent)> build(
    List<AgentReply> replies, {
    int searchesUsed = 0,
    FakeSearch? search,
    FakeAi? ai,
  }) async {
    final agent = _FakeAgent(replies);
    final harness = await ChatHarness.start(agent, searchesUsed: searchesUsed, search: search, ai: ai);
    addTearDown(harness.close);
    profile = harness.profile;
    plan = harness.plan;
    tools = harness.tools;
    return (harness.chat, agent);
  }

  List<FunctionResponse> answersAt(_FakeAgent agent, int index) => agent.sent[index] as List<FunctionResponse>;

  test('a read runs at once and its answer goes back to the model', () async {
    final (chat, agent) = await build([
      _calls([const FunctionCall('get_week_plan', {}, id: 'w')]),
      _text('Voici ta semaine.'),
    ]);

    await chat.send('Ma semaine ?');

    expect(chat.state.status, ChatStatus.idle);
    expect(chat.state.messages.map((m) => m.role), [ChatRole.user, ChatRole.assistant]);
    final answer = answersAt(agent, 1).single;
    expect(answer.name, 'get_week_plan');
    expect(answer.id, 'w');
    expect(answer.response['meals'], hasLength(plan.state.week.slots.length));
  });

  test('a change waits for approval, then runs and the conversation goes on', () async {
    final (chat, agent) = await build([]);
    final slot = plan.state.week.slots.first;
    final other = RecipeFixtures.recipes.firstWhere((r) => plan.state.week.slots.every((s) => s.recipe.id != r.id));
    agent.replies.addAll([
      _calls([
        FunctionCall('change_meals', {
          'changes': [
            {'slot_key': slot.key, 'recipe_id': other.id},
          ],
        }, id: 'c'),
      ]),
      _text("C'est fait."),
    ]);

    await chat.send('Change mon dîner de lundi');

    expect(chat.state.status, ChatStatus.confirming);
    final card = chat.state.messages.last;
    expect(card.action!.status, ActionStatus.pending);
    expect(plan.state.week.slotByKey(slot.key)!.recipe, isNot(other), reason: 'nothing runs before approval');

    await chat.approve(card.id);

    expect(plan.state.week.slotByKey(slot.key)!.recipe, other);
    expect(chat.state.messages.firstWhere((m) => m.id == card.id).action!.status, ActionStatus.approved);
    expect(answersAt(agent, 1).single.response['ok'], true);
    expect(chat.state.messages.last.text, "C'est fait.");
    expect(chat.state.status, ChatStatus.idle);
  });

  test('several meals change in one card, all at once on approval', () async {
    final (chat, agent) = await build([]);
    final week = plan.state.week.slots.where((s) => !s.isLeftover).toList();
    final unused = RecipeFixtures.recipes.where((r) => week.every((s) => s.recipe.id != r.id)).toList();
    final (a, b, c) = (week[0], week[1], week[2]);
    agent.replies.addAll([
      _calls([
        FunctionCall('change_meals', {
          'changes': [
            {'slot_key': a.key, 'recipe_id': unused[0].id},
            {'slot_key': b.key, 'recipe_id': unused[1].id},
            {'slot_key': c.key},
          ],
        }, id: 'c'),
      ]),
      _text('Voilà.'),
    ]);

    await chat.send('Change mes trois premiers repas');

    final cards = chat.state.messages.where((m) => m.role == ChatRole.action).toList();
    expect(cards, hasLength(1));
    expect(cards.single.action!.preview['meals'], hasLength(3));
    expect(cards.single.recipes, [unused[0], unused[1]]);

    await chat.approve(cards.single.id);

    expect(plan.state.week.slotByKey(a.key)!.recipe, unused[0]);
    expect(plan.state.week.slotByKey(b.key)!.recipe, unused[1]);
    expect(
      plan.state.week.slotByKey(c.key)!.recipe.id,
      isNot(anyOf(a.recipe.id, b.recipe.id, c.recipe.id)),
      reason: 'the random pick is a new dish, not one these meals just gave up',
    );
    expect(answersAt(agent, 1).single.response['ok'], true);
  });

  test('a batch with an unknown or repeated meal is sent back, without a card', () async {
    final (chat, agent) = await build([]);
    final slot = plan.state.week.slots.first;
    agent.replies.addAll([
      _calls([
        FunctionCall('change_meals', {
          'changes': [
            {'slot_key': slot.key},
            {'slot_key': 'someday|dinner'},
          ],
        }, id: '1'),
        FunctionCall('change_meals', {
          'changes': [
            {'slot_key': slot.key},
            {'slot_key': slot.key},
          ],
        }, id: '2'),
      ]),
      _text('Oups.'),
    ]);

    await chat.send('Change tout');

    final answers = answersAt(agent, 1);
    expect(answers.first.response['error'], 'unknown_slot_key');
    expect(answers.last.response['error'], 'duplicate_slot_key');
    expect(chat.state.messages.where((m) => m.role == ChatRole.action), isEmpty);
  });

  test('random picks the pool cannot fill without repeats are sent back', () async {
    await build(const []);
    final every = [
      for (final s in plan.state.week.slots) {'slot_key': s.key},
    ];

    final result = await tools.byName['change_meals']!.run({'changes': every}, _noContext);

    expect((result as ToolResult).json['error'], 'too_few_new_recipes_in_pool');
  });

  test("find_recipes matches any word of the query, best matches first", () async {
    await build(const []);

    final result = await tools.byName['find_recipes']!.run(const {'query': 'poulet rôti'}, _noContext);

    final found = (result as ToolResult).json['recipes'] as List;
    final chicken = RecipeFixtures.recipes.where((r) => r.title.toLowerCase().contains('poulet'));
    expect(found.map((r) => (r as Map)['id']), containsAll(chicken.map((r) => r.id)));
  });

  test('search_recipes makes one search, in English', () async {
    final search = FakeSearch();
    await build(const [], search: search);

    await tools.byName['search_recipes']!.run(const {'query': 'poulet'}, _noContext);

    expect(search.agentQueries, ['en:poulet']);
  });

  test('a declined change never runs and the model is told', () async {
    final (chat, agent) = await build([
      _calls([const FunctionCall('set_preferences', {'household': 4}, id: 'p')]),
      _text("D'accord, je ne change rien."),
    ]);

    await chat.send('On est 4');
    await chat.decline(chat.state.messages.last.id);

    expect(profile.state.profile.household, 2);
    expect(answersAt(agent, 1).single.response, {'declined_by_user': true});
    expect(chat.state.status, ChatStatus.idle);
  });

  test('reads and changes in one reply answer together, in order', () async {
    final (chat, agent) = await build([
      _calls([
        const FunctionCall('get_preferences', {}, id: '1'),
        const FunctionCall('set_preferences', {'household': 3, 'cook_minutes': 30}, id: '2'),
      ]),
      _text('Noté.'),
    ]);

    await chat.send('On est 3, et 30 minutes max');
    expect(chat.state.status, ChatStatus.confirming);
    await chat.approve(chat.state.messages.last.id);

    final answers = answersAt(agent, 1);
    expect(answers.map((a) => a.id), ['1', '2']);
    expect(answers.first.response['household'], 2);
    expect(answers.last.response['ok'], true);
    expect(profile.state.profile.household, 3);
    expect(profile.state.profile.cookMinutes, 30);
  });

  test('made-up ids and tools are answered with an error, without a card', () async {
    final (chat, agent) = await build([
      _calls([
        const FunctionCall('change_meals', {
          'changes': [
            {'slot_key': 'monday|dinner', 'recipe_id': 'nope'},
          ],
        }, id: '1'),
        const FunctionCall('launch_rocket', {}, id: '2'),
      ]),
      _text('Oups.'),
    ]);

    await chat.send('Mets nope lundi');

    final answers = answersAt(agent, 1);
    expect(answers.first.response['error'], 'unknown_recipe_id');
    expect(answers.last.response['error'], 'unknown_tool');
    expect(chat.state.messages.where((m) => m.role == ChatRole.action), isEmpty);
  });

  test('shown recipes appear as cards under the next reply', () async {
    final recipe = RecipeFixtures.recipes.first;
    final (chat, _) = await build([
      _calls([FunctionCall('show_recipes', {'recipe_ids': [recipe.id]}, id: 's')]),
      _text('Que dis-tu de celle-ci ?'),
    ]);

    await chat.send('Une idée ?');

    expect(chat.state.messages.last.recipes, [recipe]);
    expect(chat.state.recipeById(recipe.id), recipe);
  });

  test('a card written out as text shows as cards, without the text', () async {
    final recipe = RecipeFixtures.recipes.first;
    final (chat, _) = await build([
      _text('Voici une idée.\n[shown recipes: ${recipe.id} "${recipe.title}"]'),
    ]);

    await chat.send('Une idée ?');

    expect(chat.state.messages.last.text, 'Voici une idée.');
    expect(chat.state.messages.last.recipes, [recipe]);
  });

  test('a reopened chat remembers the cards in notes, never in the chef\'s own words', () async {
    final recipe = RecipeFixtures.recipes.first;
    final (chat, agent) = await build([
      _calls([FunctionCall('show_recipes', {'recipe_ids': [recipe.id]}, id: 's')]),
      _text('Que dis-tu de celle-ci ?'),
      _text('Bien sûr.'),
    ]);
    await chat.send('Une idée ?');

    chat.refresh();
    await chat.send('Une autre ?');

    final said = [
      for (final c in agent.history)
        if (c.role == 'model') ...c.parts.whereType<TextPart>().map((p) => p.text),
    ];
    expect(said, ['Que dis-tu de celle-ci ?']);
    expect(agent.sent.last, allOf(contains('Note from the app'), contains(recipe.id), endsWith('Une autre ?')));
  });

  test('a search outside the rules sets them aside, but never the allergies', () async {
    final ai = FakeAi();
    final harness = await ChatHarness.start(
      _FakeAgent([]),
      user: const UserProfile(
        household: 2,
        diets: {Diet.vegetarian},
        allergies: {Allergy.nutFree},
        customInstructions: 'Pas de poisson.',
      ),
      ai: ai,
    );
    addTearDown(harness.close);
    final search = harness.tools.byName['search_recipes']!;

    await search.run(const {'query': 'beef'}, _noContext);
    final kept = ai.checkedFor.last;
    await search.run(const {'query': 'beef', 'ignore_rules': true}, _noContext);
    final outside = ai.checkedFor.last;

    expect(kept.diets, {Diet.vegetarian});
    expect(kept.customInstructions, 'Pas de poisson.');
    expect(outside.diets, {Diet.none});
    expect(outside.customInstructions, isEmpty);
    expect(outside.allergies, {Allergy.nutFree});
  });

  test('one message spends at most two Spoonacular searches', () async {
    final search = FakeSearch();
    final (chat, agent) = await build([
      _calls([
        for (var i = 0; i < 3; i++) FunctionCall('search_recipes', {'query': 'q$i'}, id: '$i'),
      ]),
      _text('Voilà.'),
    ], search: search);

    await chat.send('Des idées ?');

    expect(search.agentQueries, hasLength(ChatCubit.maxSearchesPerMessage));
    expect(answersAt(agent, 1).last.response['error'], 'enough_searches_for_this_message');
  });

  test('a model that never stops calling tools fails the turn', () async {
    final (chat, _) = await build([
      for (var i = 0; i <= ChatCubit.maxRounds; i++) _calls([FunctionCall('get_week_plan', const {}, id: '$i')]),
    ]);

    await chat.send('Boucle');

    expect(chat.state.status, ChatStatus.failed);
    expect(chat.state.error, isA<ChatLoopException>());
  });

  test('the memory is rewritten whole, only once the user approves', () async {
    final (chat, agent) = await build([
      _calls([const FunctionCall('update_memory', {'text': 'Pas de coriandre. Les enfants détestent le piquant.'}, id: 'm')]),
      _text('Je retiens.'),
    ]);
    await profile.setCustomInstructions('Pas de coriandre.');

    await chat.send('Mes enfants détestent le piquant');
    final card = chat.state.messages.last;
    expect(card.action!.preview, {'from': 'Pas de coriandre.', 'to': 'Pas de coriandre. Les enfants détestent le piquant.'});
    expect(profile.state.profile.customInstructions, 'Pas de coriandre.');

    await chat.approve(card.id);
    expect(profile.state.profile.customInstructions, 'Pas de coriandre. Les enfants détestent le piquant.');
    expect(answersAt(agent, 1).single.response['memory'], 'Pas de coriandre. Les enfants détestent le piquant.');
  });

  test('a memory over the limit is sent back to be shortened', () async {
    final (chat, agent) = await build([
      _calls([FunctionCall('update_memory', {'text': 'x' * (UserProfile.customInstructionsMax + 1)}, id: 'm')]),
      _text('Je raccourcis.'),
    ]);
    await chat.send('Retiens tout ça');
    expect(answersAt(agent, 1).single.response['error'], 'too_long');
    expect(chat.state.messages.where((m) => m.role == ChatRole.action), isEmpty);
  });

  test('no message goes out once the day\'s searches are spent', () async {
    final (chat, agent) = await build([_text('Salut')], searchesUsed: 30);

    await chat.send('Bonjour');

    expect(agent.sent, isEmpty);
    expect(chat.state.messages, isEmpty);
  });

  test('a Spoonacular tool never runs without a search left', () async {
    await build(const [], searchesUsed: 30);
    final search = tools.byName['search_recipes']!;

    await expectLater(search.run(const {'query': 'curry'}, _noContext), throwsA(isA<SearchLimitException>()));
    expect(ChatTools.reasonFor(const SearchLimitException()), 'quota_exhausted');
  });
}
