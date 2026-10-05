import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/model/ingredient_unit.dart';
import 'package:tably/features/plan/cubit/plan_cubit.dart';
import 'package:tably/features/plan/model/plan_settings.dart';
import 'package:tably/features/plan/service/plan_service.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/cubit/recipe_cubit.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/features/recipe/service/recipe_service.dart';
import 'package:tably/features/shopping/cubit/shopping_cubit.dart';
import 'package:tably/features/shopping/model/shopping_item.dart';
import 'package:tably/features/shopping/service/shopping_ai_service.dart';
import 'package:tably/features/shopping/service/shopping_service.dart';

import 'fixtures/recipe_fixtures.dart';

class _FakePlanService extends PlanService {
  @override
  Stream<PlanSettings> watch(String uid) => Stream.value(const PlanSettings());

  @override
  Future<void> save(String uid, PlanSettings settings) async {}
}

/// Starts with an empty stored list and records every write.
class _FakeShoppingService extends ShoppingService {
  final writes = <({List<ShoppingItem> items, List<String> removed})>[];

  @override
  Stream<List<ShoppingItem>> watch(String uid) => Stream.value(const []);

  @override
  Future<void> replaceList(String uid, List<ShoppingItem> items, Iterable<String> removedIds) async =>
      writes.add((items: items, removed: removedIds.toList()));
}

/// Merges nothing, so each line is its own item, stamped with the source.
class _FakeShoppingAi extends ShoppingAiService {
  @override
  Future<List<ShoppingItem>> aggregate(List<Ingredient> lines, String languageCode, String source) async =>
      ShoppingAiService.merge(lines, const {}, source);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ShoppingCubit, ProfileCubit, _FakeShoppingService)> build() async {
    const analytics = AnalyticsService();
    final profile = ProfileCubit(service: ProfileService(), analytics: analytics);
    final catalogue = seededCatalogue(profile);
    final recipes = RecipeCubit(service: RecipeService(), analytics: analytics);
    final plan = PlanCubit(
      service: _FakePlanService(),
      profileCubit: profile,
      catalogueCubit: catalogue,
      recipeCubit: recipes,
      analytics: analytics,
    );
    final service = _FakeShoppingService();
    final shopping = ShoppingCubit(
      service: service,
      ai: _FakeShoppingAi(),
      planCubit: plan,
      profileCubit: profile,
      analytics: analytics,
    );
    for (final c in [shopping, plan, recipes, catalogue, profile]) {
      addTearDown(c.close);
    }
    await profile.completeOnboarding(const UserProfile());
    plan.bind('u');
    shopping.bind('u');
    await pumpEventQueue();
    return (shopping, profile, service);
  }

  test("the user's additions, deletions and edits survive a rebuild of the list", () async {
    final (shopping, profile, _) = await build();
    final derived = shopping.state.items;
    expect(derived, isNotEmpty);
    final deleted = derived[0];
    final renamed = derived[1];

    await shopping.edit(
      add: [ShoppingCubit.newItem(name: 'lait', amount: 1, unit: IngredientUnit.l)],
      remove: {deleted.id},
      update: [renamed.copyWith(name: 'mon nom', amount: 99)],
      check: {derived[2].id},
    );
    expect(shopping.state.visibleItems.map((i) => i.id), isNot(contains(deleted.id)));

    // A household change rebuilds the list from the week.
    await profile.setHousehold(3);
    await pumpEventQueue();

    final items = {for (final i in shopping.state.items) i.id: i};
    expect(items.values.where((i) => i.manual).single.name, 'lait');
    expect(items[deleted.id]!.removed, isTrue, reason: 'still hidden while the week needs it');
    expect(items[renamed.id]!.name, 'mon nom');
    expect(items[renamed.id]!.amount, 99);
    expect(items[derived[2].id]!.checked, isTrue);
    expect(items[derived[3].id]!.amount, isNot(derived[3].amount), reason: 'untouched items follow the household');
  });

  test('a manual item is deleted, a derived one only hidden', () async {
    final (shopping, _, service) = await build();
    await shopping.addItem('pain');
    final manual = shopping.state.items.firstWhere((i) => i.manual);
    final derived = shopping.state.items.first;

    await shopping.edit(remove: {manual.id, derived.id});

    expect(service.writes.last.removed, [manual.id]);
    expect(service.writes.last.items.single.removed, isTrue);
    expect(shopping.state.total, shopping.state.items.length - 1);
  });

  test('a list holding only manual items is still rebuilt for the week', () async {
    final (shopping, profile, service) = await build();
    final writes = service.writes.length;
    await shopping.addItem('pain');
    await profile.setHousehold(2);
    await pumpEventQueue();
    expect(service.writes.length, greaterThan(writes + 1));
    expect(shopping.state.items.where((i) => i.manual), hasLength(1));
  });
}

Future<void> pumpEventQueue() => Future<void>.delayed(const Duration(milliseconds: 10));
