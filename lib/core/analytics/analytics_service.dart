import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

/// Thin wrapper over Mixpanel so screens and cubits never touch the SDK directly
/// and every failure is swallowed rather than breaking a user flow.
class AnalyticsService {
  const AnalyticsService();

  /// Mixpanel project token. Override at build time:
  /// `flutter run --dart-define=MIXPANEL_TOKEN=...`
  static const _token = String.fromEnvironment('MIXPANEL_TOKEN', defaultValue: '2d21ebcf30c96eb0f7ac5ac86a7f9419');

  /// Set once by [init]; every call is a no-op while it is null.
  static Mixpanel? _mixpanel;

  /// Starts Mixpanel; the app runs fine if this fails.
  static Future<void> init() async {
    try {
      _mixpanel = await Mixpanel.init(_token, trackAutomaticEvents: true);
      await _mixpanel!.registerSuperProperties({'platform': defaultTargetPlatform.name});
      debugPrint('[AnalyticsService] Mixpanel initialised');
    } catch (e) {
      debugPrint('[AnalyticsService] Mixpanel initialisation failed: $e');
    }
  }

  /// Records a product event with optional properties.
  Future<void> capture(String event, {Map<String, Object>? properties}) async {
    try {
      await _mixpanel?.track(event, properties: properties);
    } catch (e) {
      debugPrint('[AnalyticsService] capture "$event" failed: $e');
    }
  }

  /// Records a screen view (Mixpanel has no screen API, so it is an event).
  Future<void> screen(String name) async {
    try {
      await _mixpanel?.track(AnalyticsEvents.screenViewed, properties: {'screen_name': name});
    } catch (e) {
      debugPrint('[AnalyticsService] screen "$name" failed: $e');
    }
  }

  /// Ties subsequent events to a user and attaches their profile properties.
  Future<void> identify(String userId, {Map<String, Object>? properties}) async {
    final mixpanel = _mixpanel;
    if (mixpanel == null) return;
    try {
      await mixpanel.identify(userId);
      properties?.forEach(mixpanel.getPeople().set);
      debugPrint('[AnalyticsService] identified $userId');
    } catch (e) {
      debugPrint('[AnalyticsService] identify failed: $e');
    }
  }

  /// Clears the identity on sign-out.
  Future<void> reset() async {
    try {
      await _mixpanel?.reset();
    } catch (e) {
      debugPrint('[AnalyticsService] reset failed: $e');
    }
  }
}

/// Event names, kept in one place so reporting stays consistent.
abstract final class AnalyticsEvents {
  static const screenViewed = 'screen_viewed';
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStepCompleted = 'onboarding_step_completed';
  static const onboardingCompleted = 'onboarding_completed';
  static const catalogueBuilt = 'catalogue_built';
  static const catalogueBuildFailed = 'catalogue_build_failed';
  static const catalogueKept = 'catalogue_kept';
  static const recipeSearched = 'recipe_searched';
  static const recipeSearchFailed = 'recipe_search_failed';
  static const planRegenerated = 'plan_regenerated';
  static const mealReplaced = 'meal_replaced';
  static const mealRegenerated = 'meal_regenerated';
  static const mealMoved = 'meal_moved';
  static const storeSwitchAccepted = 'store_switch_accepted';
  static const storeSwitchDeclined = 'store_switch_declined';
  static const recipeOpened = 'recipe_opened';
  static const recipeCookedToggled = 'recipe_cooked_toggled';
  static const recipeFavouriteToggled = 'recipe_favourite_toggled';
  static const shoppingItemToggled = 'shopping_item_toggled';
  static const shoppingListOpened = 'shopping_list_opened';
  static const shoppingListShared = 'shopping_list_shared';
  static const preferenceChanged = 'preference_changed';
  static const tabSelected = 'tab_selected';
  static const recipeFiltersChanged = 'recipe_filters_changed';
  static const addRecipeSheetOpened = 'add_recipe_sheet_opened';
  static const signInStarted = 'sign_in_started';
  static const signInCompleted = 'sign_in_completed';
  static const referralRedeemAttempt = 'referral_redeem_attempt';
  static const referralRedeemSuccess = 'referral_redeem_success';
  static const referralRedeemFailed = 'referral_redeem_failed';
  static const paywallShown = 'paywall_shown';
  static const paywallBypassed = 'paywall_bypassed';
  static const subscriptionActivated = 'subscription_activated';
  static const subscriptionLost = 'subscription_lost';
}
