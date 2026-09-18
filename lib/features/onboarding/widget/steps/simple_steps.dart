import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/model/preference_option.dart';
import '../../../../core/model/weekday.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/util/haptics.dart';
import '../../../../core/util/option_labels.dart';
import '../../../../core/widget/surface_card.dart';
import '../../../../l10n/app_localizations.dart';

/// "comment tu t'appelles ?" — a single rounded text field.
class NameStep extends StatefulWidget {
  const NameStep({super.key, required this.initialValue, required this.onChanged});

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 26.h),
          child: Text(l10n.onbNameTitle, style: AppTextStyles.h1),
        ),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          textCapitalization: TextCapitalization.words,
          style: AppTextStyles.input,
          decoration: InputDecoration(
            hintText: l10n.onbNamePlaceholder,
            hintStyle: AppTextStyles.input.copyWith(color: AppColors.textDisabled),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: EdgeInsets.all(20.r),
            border: _border,
            enabledBorder: _border,
            focusedBorder: _border,
          ),
        ),
      ],
    );
  }

  OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: BorderRadius.circular(22.r),
        borderSide: const BorderSide(color: AppColors.border),
      );
}

/// "pour combien tu cuisines ?" — the household stepper.
class CounterStep extends StatelessWidget {
  const CounterStep({
    super.key,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.onbHouseholdTitle, style: AppTextStyles.h1),
        SizedBox(height: 10.h),
        Text(l10n.onbHouseholdSubtitle, style: AppTextStyles.subtitleTight),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepperButton(
                    glyph: '−',
                    size: 56,
                    enabled: count > 1,
                    onTap: onDecrement,
                  ),
                  SizedBox(width: 36.w),
                  SizedBox(
                    width: 64.w,
                    child: Text('$count', textAlign: TextAlign.center, style: AppTextStyles.numeral),
                  ),
                  SizedBox(width: 36.w),
                  _StepperButton(glyph: '+', size: 56, enabled: true, onTap: onIncrement),
                ],
              ),
              SizedBox(height: 14.h),
              Text(
                l10n.peopleCount(count),
                style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textQuaternary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Round grey +/− control. Disabled state only dims the glyph, as in the design.
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.glyph,
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  final String glyph;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              Haptics.toggle();
              onTap();
            }
          : null,
      child: Container(
        width: size.r,
        height: size.r,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.fill, shape: BoxShape.circle),
        child: Text(
          glyph,
          style: TextStyle(
            fontSize: (size * 0.46).sp,
            height: 1,
            color: enabled ? AppColors.inkStrong : AppColors.chevron,
          ),
        ),
      ),
    );
  }
}

/// "quels jours tu cuisines ?" — wrapped day cards.
class DaysStep extends StatelessWidget {
  const DaysStep({super.key, required this.selected, required this.onToggle});

  final Set<Weekday> selected;
  final ValueChanged<Weekday> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.onbDaysTitle, style: AppTextStyles.h1),
        SizedBox(height: 10.h),
        Text(l10n.onbDaysSubtitle, style: AppTextStyles.subtitleTight),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Text(
                  l10n.daysSelected(selected.length),
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.textQuaternary),
                ),
              ),
              Wrap(
                spacing: 13.w,
                runSpacing: 13.h,
                alignment: WrapAlignment.center,
                children: [
                  for (final day in Weekday.values)
                    _DayCard(
                      label: l10n.dayName(day),
                      selected: selected.contains(day),
                      onTap: () => onToggle(day),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.toggle();
        onTap();
      },
      child: Container(
        width: 156.w,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 20.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.dayCard.copyWith(
            color: selected ? AppColors.ink : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}

/// "quel est ton budget hebdo ?" — the big number plus slider.
class BudgetStep extends StatelessWidget {
  const BudgetStep({
    super.key,
    required this.budget,
    required this.minBudget,
    required this.maxBudget,
    required this.country,
    required this.onChanged,
  });

  final double budget;
  final double minBudget;
  final double maxBudget;
  final Country country;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.onbBudgetTitle, style: AppTextStyles.h1),
        SizedBox(height: 10.h),
        Text(l10n.onbBudgetSubtitle, style: AppTextStyles.subtitleTight),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                formatMoney(country, budget),
                textAlign: TextAlign.center,
                style: AppTextStyles.numeralCurrency,
              ),
              SizedBox(height: 2.h),
              Padding(
                padding: EdgeInsets.only(bottom: 22.h),
                child: Text(
                  l10n.thisWeek,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textQuaternary),
                ),
              ),
              BudgetSlider(
                budget: budget,
                minBudget: minBudget,
                maxBudget: maxBudget,
                country: country,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The slider itself, reused on the preferences screen.
class BudgetSlider extends StatelessWidget {
  const BudgetSlider({
    super.key,
    required this.budget,
    required this.minBudget,
    required this.maxBudget,
    required this.country,
    required this.onChanged,
    this.labelStyle,
  });

  final double budget;
  final double minBudget;
  final double maxBudget;
  final Country country;
  final ValueChanged<double> onChanged;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 7.h,
              activeTrackColor: AppColors.trackDark,
              inactiveTrackColor: AppColors.trackDark,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 17.r, elevation: 2),
              thumbColor: AppColors.brand,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: budget.clamp(minBudget, maxBudget),
              min: minBudget,
              max: maxBudget,
              // 0.2 steps, matching the design's slider granularity.
              divisions: ((maxBudget - minBudget) / 0.2).round(),
              onChanged: (value) {
                Haptics.toggle();
                onChanged(value);
              },
            ),
          ),
        ),
        SizedBox(width: 14.w),
        Text(
          formatMoney(country, maxBudget),
          style: labelStyle ??
              AppTextStyles.subtitleLarge.copyWith(color: AppColors.textQuaternary),
        ),
      ],
    );
  }
}

/// Generic emoji + copy screen ("planifier les repas, c'est chronophage…").
class InfoStep extends StatelessWidget {
  const InfoStep({super.key, required this.emoji, required this.title, required this.subtitle});

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 22.h),
          child: Text(title, textAlign: TextAlign.center, style: AppTextStyles.h1Center),
        ),
        Expanded(
          child: Center(child: Text(emoji, style: TextStyle(fontSize: 112.sp, height: 1))),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300.w),
          child: Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.subtitleLarge),
        ),
        const Spacer(),
      ],
    );
  }
}

/// The time-saving bar chart screen.
class InfoBarsStep extends StatelessWidget {
  const InfoBarsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 10.h, bottom: 12.h),
          child: Text(l10n.onbInfoBarsTitle, textAlign: TextAlign.center, style: AppTextStyles.h1Center),
        ),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 310.w),
            child: Text(
              l10n.onbInfoBarsSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitleTight.copyWith(height: 1.4),
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Bar(
                    value: l10n.onbInfoBarsWithUsValue,
                    label: l10n.onbInfoBarsWithUs,
                    height: 22,
                    color: AppColors.brand,
                    valueColor: AppColors.brand,
                  ),
                  SizedBox(width: 56.w),
                  _Bar(
                    value: l10n.onbInfoBarsWithoutUsValue,
                    label: l10n.onbInfoBarsWithoutUs,
                    height: 170,
                    color: AppColors.neutralBar,
                    valueColor: AppColors.inkStrong,
                  ),
                ],
              ),
              SizedBox(height: 34.h),
              Text(
                l10n.onbInfoBarsFooter,
                textAlign: TextAlign.center,
                style: AppTextStyles.h2Bars,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.label,
    required this.height,
    required this.color,
    required this.valueColor,
  });

  final String value;
  final String label;
  final double height;
  final Color color;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w800, color: valueColor),
        ),
        SizedBox(height: 10.h),
        Container(
          width: 70.w,
          height: height.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
          ),
        ),
        SizedBox(height: 10.h),
        Text(label, style: AppTextStyles.meta.copyWith(color: AppColors.textQuaternary)),
      ],
    );
  }
}

/// The savings screen.
class InfoMoneyStep extends StatelessWidget {
  const InfoMoneyStep({super.key, required this.country});

  final Country country;

  /// Figures shown in the design: €20 a week, €1040 a year.
  static const _weeklySaving = 20.0;
  static const _yearlySaving = 1040.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🤯', style: TextStyle(fontSize: 96.sp, height: 1)),
          SizedBox(height: 22.h),
          Text(
            l10n.onbInfoMoneyTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.h1Center.copyWith(fontSize: 29.sp, height: 1.2),
          ),
          SizedBox(height: 22.h),
          Text(formatMoney(country, _weeklySaving, decimals: 0), style: AppTextStyles.numeralBrand),
          SizedBox(height: 4.h),
          Text(
            l10n.onbInfoMoneySubtitle,
            style: AppTextStyles.subtitleTight.copyWith(color: AppColors.textQuaternary),
          ),
          SizedBox(height: 26.h),
          Text(
            l10n.onbInfoMoneyFooter(formatMoney(country, _yearlySaving, decimals: 0)),
            style: AppTextStyles.h2,
          ),
        ],
      ),
    );
  }
}

/// The review wall shown at the end of onboarding.
class TestimonialStep extends StatelessWidget {
  const TestimonialStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final reviews = <({String name, String title, String body})>[
      (name: l10n.reviewOneName, title: l10n.reviewOneTitle, body: l10n.reviewOneBody),
      (name: l10n.reviewTwoName, title: l10n.reviewTwoTitle, body: l10n.reviewTwoBody),
      (name: l10n.reviewThreeName, title: l10n.reviewThreeTitle, body: l10n.reviewThreeBody),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.onbTestimonialTitle, style: AppTextStyles.h1Center.copyWith(height: 1.13)),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.only(bottom: 20.h),
          child: Text(l10n.onbTestimonialSubtitle, style: AppTextStyles.subtitleTight),
        ),
        for (final review in reviews)
          Padding(
            padding: EdgeInsets.only(bottom: 13.h),
            child: SurfaceCard(
              radius: 20.r,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(review.name, style: AppTextStyles.reviewName),
                      Text('★★★★★', style: AppTextStyles.stars),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(review.title, style: AppTextStyles.reviewName),
                  SizedBox(height: 3.h),
                  Text(review.body, style: AppTextStyles.reviewBody),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
