import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/model/preference_option.dart';
import '../../../../core/model/store.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/util/haptics.dart';
import '../../../../core/util/option_labels.dart';
import '../../../../core/widget/app_logo.dart';
import '../../../../core/widget/primary_button.dart';
import '../../../../core/widget/recipe_photo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../recipe/model/recipe.dart';
import '../../../recipe/widget/craving_badge.dart';
import 'language_step.dart';

/// The branded welcome screen: language pill, wordmark and the phone mock-up.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({
    super.key,
    required this.languageCode,
    required this.store,
    required this.country,
    required this.onOpenLanguage,
    required this.onNext,
    required this.onEnterCode,
    required this.codeApplied,
  });

  final String languageCode;
  final Store store;
  final Country country;
  final VoidCallback onOpenLanguage;
  final VoidCallback onNext;
  final VoidCallback onEnterCode;

  /// True once a referral code has been redeemed, which is the only signal the
  /// user gets here that their code took effect.
  final bool codeApplied;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _LanguagePill(language: languageFor(languageCode), onTap: onOpenLanguage),
        ),
        SizedBox(height: 24.h),
        AppLogo(size: 64.r),
        SizedBox(height: 2.h),
        Text(l10n.appName, textAlign: TextAlign.center, style: AppTextStyles.wordmarkLarge),
        SizedBox(height: 16.h),
        Text(l10n.tagline, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
        SizedBox(height: 18.h),
        _PhoneMockup(store: store, country: country),
        SizedBox(height: 20.h),

        const Spacer(),
        PrimaryButton(label: l10n.actionStart, onPressed: onNext),
        SizedBox(height: 16.h),
        if (codeApplied)
          Text(
            l10n.haveACodeApplied,
            textAlign: TextAlign.center,
            style: AppTextStyles.metaSmall.copyWith(fontSize: 14.sp, color: AppColors.brand),
          )
        else
          GestureDetector(
            onTap: () {
              Haptics.tap();
              onEnterCode();
            },
            behavior: HitTestBehavior.opaque,
            child: Text(
              l10n.haveACode,
              textAlign: TextAlign.center,
              style: AppTextStyles.metaSmall.copyWith(
                fontSize: 14.sp,
                color: AppColors.brand,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.brand,
              ),
            ),
          ),
      ],
    );
  }
}

/// Flag, language name and a chevron — opens the language picker.
class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.language, required this.onTap});

  final AppLanguage language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(language.flag, style: AppTextStyles.emojiIcon.copyWith(fontSize: 19.sp)),
            SizedBox(width: 8.w),
            Text(language.name, style: AppTextStyles.languagePill),
            SizedBox(width: 8.w),
            Text('⌄', style: AppTextStyles.languagePill.copyWith(color: AppColors.chevron, fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }
}

/// A miniature of the "Semaine" tab, flanked by two faded side panels.
class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({required this.store, required this.country});

  final Store store;
  final Country country;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    Widget bar(double widthFactor, {double height = 8}) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: height.h,
            decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(3.r)),
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SidePanel(left: true, children: [
          RecipePhoto(photoKey: Cuisine.indian.photoKey, height: 62.h, width: double.infinity, radius: 8.r),
          bar(0.8),
          RecipePhoto(photoKey: Cuisine.mexican.photoKey, height: 62.h, width: double.infinity, radius: 8.r),
          bar(0.7),
        ]),
        SizedBox(width: 10.w),
        Container(
          width: 164.w,
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.ink, width: 7.r),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.16), blurRadius: 30.r, offset: Offset(0, 12.h))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38.w,
                  height: 5.h,
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(5.r)),
                ),
              ),
              SizedBox(height: 7.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppLogo(size: 14.r),
                  SizedBox(width: 4.w),
                  Text(l10n.appName, style: AppTextStyles.mock(15, letterSpacing: -0.7)),
                ],
              ),
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(20.r)),
                child: Text(
                  l10n.plannedFor(store.displayName),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.mock(8, color: AppColors.brandDark),
                ),
              ),
              SizedBox(height: 6.h),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _MockCostCard(country: country)),
                    SizedBox(width: 5.w),
                    const Expanded(child: _MockShoppingCard()),
                  ],
                ),
              ),
              // Illustration only: three dishes drawn from the bundled photos.
              for (final (title, photoKey, craving) in [
                (l10n.mockMealCajun, 'cajun', Craving.quick),
                (l10n.mockMealSatay, 'noodle', Craving.highProtein),
                (l10n.mockMealSweetChilli, 'handi', Craving.quick),
              ]) ...[
                SizedBox(height: 6.h),
                _MockMealRow(title: title, photoKey: photoKey, craving: craving),
              ],
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.only(top: 5.h),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(l10n.tabMenu, style: AppTextStyles.mock(6, color: AppColors.brand)),
                    for (final label in [l10n.tabRecipes, l10n.prefsTitle, l10n.tabAccount])
                      Text(label.toLowerCase(), style: AppTextStyles.mock(6, color: AppColors.textDisabled)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        _SidePanel(left: false, children: [
          RecipePhoto(photoKey: 'noodle', height: 78.h, width: double.infinity, radius: 8.r),
          bar(0.85),
          bar(0.55),
          bar(1, height: 26),
        ]),
      ],
    );
  }
}

/// A faded panel hinting at the screens beside the phone.
class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.left, required this.children});

  final bool left;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: AppColors.border);
    return Opacity(
      opacity: 0.75,
      child: Container(
        width: 46.w,
        height: 200.h,
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: side, bottom: side, left: left ? side : BorderSide.none, right: left ? BorderSide.none : side),
          borderRadius: left
              ? BorderRadius.horizontal(left: Radius.circular(16.r))
              : BorderRadius.horizontal(right: Radius.circular(16.r)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, child) in children.indexed) ...[if (i > 0) SizedBox(height: 6.h), child],
          ],
        ),
      ),
    );
  }
}

/// A miniature of the real [CostCard]: spend against budget and the savings line.
/// The illustrative figures are part of the artwork, not the user's data.
class _MockCostCard extends StatelessWidget {
  const _MockCostCard({required this.country});

  final Country country;

  static const _total = 33.70;
  static const _budget = 55.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderSoft),
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mockCostShort, style: AppTextStyles.mock(5, color: AppColors.textPlaceholder, letterSpacing: 0.4)),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(formatMoney(country, _total), style: AppTextStyles.mock(9, letterSpacing: -0.3)),
                Text(
                  ' / ${formatMoney(country, _budget, decimals: 0)}',
                  style: AppTextStyles.mock(6, color: AppColors.textDisabled, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          _MockProgress(value: _total / _budget, track: AppColors.divider),
          SizedBox(height: 3.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.budgetSavings(formatMoney(country, _budget - _total, decimals: 0)),
              style: AppTextStyles.mock(6, color: AppColors.brandDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// A miniature of the real [ShoppingSummaryCard].
class _MockShoppingCard extends StatelessWidget {
  const _MockShoppingCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(color: AppColors.info, borderRadius: BorderRadius.circular(9.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mockTapShort, style: AppTextStyles.mock(5, color: AppColors.infoLabel, letterSpacing: 0.4)),
          SizedBox(height: 2.h),
          Text(l10n.shoppingList, style: AppTextStyles.mock(8, height: 1.15, letterSpacing: -0.3)),
          SizedBox(height: 2.h),
          Text(l10n.shoppingBoughtCount(0, 25), style: AppTextStyles.mock(6, color: AppColors.inkBody, weight: FontWeight.w700)),
          const Spacer(),
          const _MockProgress(value: 0, track: AppColors.infoTrack),
        ],
      ),
    );
  }
}

/// The thin brand progress bar used by both summary cards.
class _MockProgress extends StatelessWidget {
  const _MockProgress({required this.value, required this.track});

  final double value;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3.r),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 3.h,
        backgroundColor: track,
        valueColor: const AlwaysStoppedAnimation(AppColors.brand),
      ),
    );
  }
}

class _MockMealRow extends StatelessWidget {
  const _MockMealRow({required this.title, required this.photoKey, required this.craving});

  final String title;
  final String photoKey;
  final Craving craving;

  @override
  Widget build(BuildContext context) {
    final (background, ink) = CravingBadge.colorsFor(craving);
    return Container(
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderSoft),
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Row(
        children: [
          RecipePhoto(photoKey: photoKey, height: 30.r, width: 30.r, radius: 8.r),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.mock(8, height: 1.2)),
                SizedBox(height: 3.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20.r)),
                  child: Text(AppL10n.of(context).cravingLabel(craving), style: AppTextStyles.mock(6, color: ink)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
