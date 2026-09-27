import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widget/circle_icon_button.dart';
import '../../../../core/widget/surface_card.dart';
import '../../../../l10n/app_localizations.dart';

/// A language offered by the picker. Names are shown in their own language.
typedef AppLanguage = ({String code, String flag, String name});

/// Languages offered by the picker — only those that ship translations.
const appLanguages = <AppLanguage>[
  (code: 'fr', flag: '🇫🇷', name: 'Français'),
  (code: 'en', flag: '🇬🇧', name: 'English'),
];

AppLanguage languageFor(String code) => appLanguages.firstWhere((l) => l.code == code, orElse: () => appLanguages.first);

/// "Choose your language", opened from the welcome screen's language pill.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, required this.onSelected, required this.onBack});

  final ValueChanged<String> onSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: CircleIconButton(glyph: '←', onPressed: onBack)),
        Padding(
          padding: EdgeInsets.only(top: 24.h, bottom: 24.h),
          child: Text(AppL10n.of(context).onbLanguageTitle, style: AppTextStyles.h1Large),
        ),
        for (final language in appLanguages)
          Padding(
            padding: EdgeInsets.only(bottom: 13.h),
            child: SurfaceCard(
              shadow: true,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
              onTap: () => onSelected(language.code),
              child: Row(
                children: [
                  Text(language.flag, style: AppTextStyles.emojiIcon.copyWith(fontSize: 25.sp)),
                  SizedBox(width: 18.w),
                  Text(language.name, style: AppTextStyles.languageName),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
