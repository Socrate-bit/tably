import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/store.dart';
import 'package:tably/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';

void main() {
  test('profiles saved with a brand name still resolve', () {
    expect(Store.fromId('Lidl'), Store.lidl);
    expect(Store.fromId('lidl'), Store.lidl);
    expect(Store.fromId('Super U'), Store.superU);
    expect(Store.fromId('unknown'), Store.fallback);
  });

  test('no switch is offered at the cheapest store', () {
    const state = OnboardingState(draft: UserProfile(store: Store.lidl));
    expect(state.hasCheaperStore, isFalse, reason: 'Leclerc costs more than Lidl');
  });

  test('a pricier store is offered the cheapest one, with the real saving', () {
    const state = OnboardingState(draft: UserProfile(store: Store.carrefour));
    expect(state.hasCheaperStore, isTrue);
    expect(state.cheaperStore, Store.lidl);
    expect(state.switchSavingPercent, 9);
    expect(state.previewWeek.totalAt(Store.lidl), lessThan(state.previewWeek.totalAt(Store.carrefour)));
  });
}
