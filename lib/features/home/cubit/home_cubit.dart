import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';

/// The four destinations in the bottom bar.
enum HomeTab { menu, recipes, preferences, account }

/// Tracks the selected tab. Pushed screens (recipe, shopping list) are routed
/// through Navigator rather than held here.
class HomeCubit extends Cubit<HomeTab> {
  HomeCubit({required AnalyticsService analytics})
      : _analytics = analytics,
        super(HomeTab.menu);

  final AnalyticsService _analytics;

  void select(HomeTab tab) {
    if (tab == state) return;
    emit(tab);
    _analytics.capture(AnalyticsEvents.tabSelected, properties: {'tab': tab.name});
    _analytics.screen(tab.name);
  }
}
