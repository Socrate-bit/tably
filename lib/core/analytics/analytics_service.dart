import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Thin wrapper over PostHog so screens and cubits never touch the SDK directly
/// and every failure is swallowed rather than breaking a user flow.
class AnalyticsService {
  const AnalyticsService();

  /// Records a product event with optional properties.
  Future<void> capture(String event, {Map<String, Object>? properties}) async {
    try {
      await Posthog().capture(eventName: event, properties: properties);
    } catch (e) {
      debugPrint('[AnalyticsService] capture "$event" failed: $e');
    }
  }

  /// Records a screen view.
  Future<void> screen(String name) async {
    try {
      await Posthog().screen(screenName: name);
    } catch (e) {
      debugPrint('[AnalyticsService] screen "$name" failed: $e');
    }
  }

  /// Ties subsequent events to a user and attaches their profile properties.
  Future<void> identify(String userId, {Map<String, Object>? properties}) async {
    try {
      await Posthog().identify(userId: userId, userProperties: properties);
      debugPrint('[AnalyticsService] identified $userId');
    } catch (e) {
      debugPrint('[AnalyticsService] identify failed: $e');
    }
  }

  /// Clears the identity on sign-out.
  Future<void> reset() async {
    try {
      await Posthog().reset();
    } catch (e) {
      debugPrint('[AnalyticsService] reset failed: $e');
    }
  }
}

/// Event names, kept in one place so reporting stays consistent.
abstract final class AnalyticsEvents {
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStepCompleted = 'onboarding_step_completed';
  static const onboardingCompleted = 'onboarding_completed';
  static const planRegenerated = 'plan_regenerated';
  static const mealReplaced = 'meal_replaced';
  static const mealRegenerated = 'meal_regenerated';
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
  static const onboardingReplayed = 'onboarding_replayed';
}
