import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';

/// The three destinations in the bottom bar.
enum HomeTab { menu, recipes, preferences }

/// Screens shown in place of a tab while keeping the tab bar visible.
/// Recipe, shopping list and filters are pushed full-screen instead.
enum HomeSub { none, favourites, stores, account }

class HomeState extends Equatable {
  const HomeState({this.tab = HomeTab.menu, this.sub = HomeSub.none});

  final HomeTab tab;
  final HomeSub sub;

  @override
  List<Object?> get props => [tab, sub];
}

/// Tracks where the user is in the app shell.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required AnalyticsService analytics})
      : _analytics = analytics,
        super(const HomeState());

  final AnalyticsService _analytics;

  /// Selecting a tab always lands on its root, closing any sub-screen.
  void select(HomeTab tab) {
    if (tab == state.tab && state.sub == HomeSub.none) return;
    emit(HomeState(tab: tab));
    _analytics.capture(AnalyticsEvents.tabSelected, properties: {'tab': tab.name});
    _analytics.screen(tab.name);
  }

  void open(HomeSub sub) {
    emit(HomeState(tab: state.tab, sub: sub));
    _analytics.screen(sub.name);
  }

  void closeSub() => emit(HomeState(tab: state.tab));

  /// Back to the first tab, so a new account doesn't land where the old one left off.
  void reset() => emit(const HomeState());
}
