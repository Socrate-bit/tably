import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/theme/app_theme.dart';
import 'package:tably/core/widget/note_field.dart';
import 'package:tably/features/home/cubit/home_cubit.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/screen/preferences_screen.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/l10n/app_localizations.dart';

void main() {
  testWidgets('custom instructions save when the user leaves the box', (tester) async {
    tester.view.physicalSize = const Size(804, 1748);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    const analytics = AnalyticsService();
    final profileCubit = ProfileCubit(service: ProfileService(), analytics: analytics);
    addTearDown(profileCubit.close);
    await profileCubit.completeOnboarding(const UserProfile());

    // The test font is wider than the app's, so some option labels overflow.
    final onError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.toString().contains('overflowed')) onError?.call(details);
    };

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: profileCubit),
        BlocProvider(create: (_) => HomeCubit(analytics: analytics)),
      ],
      child: ScreenUtilInit(
        designSize: const Size(AppDimens.designWidth, AppDimens.designHeight),
        builder: (context, _) => MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppL10n.supportedLocales,
          home: const Scaffold(body: PreferencesScreen()),
        ),
      ),
    ));

    final box = find.byType(NoteField);
    await tester.scrollUntilVisible(box, 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Instructions personnalisées'), findsOneWidget);
    await tester.enterText(box, 'pas de champignons ');
    await tester.pump();
    expect(profileCubit.state.profile.customInstructions, isEmpty, reason: 'not saved while typing');

    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();
    FlutterError.onError = onError;
    expect(profileCubit.state.profile.customInstructions, 'pas de champignons');
  });
}
