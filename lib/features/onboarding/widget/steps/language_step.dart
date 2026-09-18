import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/util/haptics.dart';
import '../../../../core/widget/surface_card.dart';
import '../../../../l10n/app_localizations.dart';

/// The languages offered on the first screen.
const _languages = <({String code, String flag, String name, String? sub})>[
  (code: 'en', flag: '🇬🇧', name: 'English', sub: null),
  (code: 'de', flag: '🇩🇪', name: 'Deutsch', sub: 'German'),
  (code: 'sv', flag: '🇸🇪', name: 'Svenska', sub: 'Swedish'),
  (code: 'nl', flag: '🇳🇱', name: 'Nederlands', sub: 'Dutch'),
  (code: 'pt', flag: '🇵🇹', name: 'Português', sub: 'Portuguese'),
  (code: 'es', flag: '🇪🇸', name: 'Español', sub: 'Spanish'),
  (code: 'fr', flag: '🇫🇷', name: 'Français', sub: 'French'),
];

/// First onboarding screen. Tapping a language advances immediately.
class LanguageStep extends StatelessWidget {
  const LanguageStep({super.key, required this.onSelected});

  final void Function(String languageCode) onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Text(l10n.onbLanguageTitle, style: AppTextStyles.h1Large),
        ),
        for (final language in _languages)
          Padding(
            padding: EdgeInsets.only(bottom: 13.h),
            child: SurfaceCard(
              shadow: true,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
              onTap: () {
                Haptics.tap();
                onSelected(language.code);
              },
              child: Row(
                children: [
                  Text(language.flag, style: TextStyle(fontSize: 25.sp, height: 1)),
                  SizedBox(width: 18.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(language.name, style: AppTextStyles.languageName),
                      if (language.sub != null)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Text(language.sub!, style: AppTextStyles.metaMuted),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
