import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/util/option_labels.dart';
import '../../../../core/widget/option_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../model/onboarding_step.dart';

/// Renders any options step — rows, grid or tiles — from its declaration.
class OptionsStep extends StatelessWidget {
  const OptionsStep({
    super.key,
    required this.step,
    required this.isSelected,
    required this.onSelect,
  });

  final OnboardingStep step;
  final bool Function(String optionId) isSelected;
  final void Function(String optionId) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final title = _title(l10n);
    final subtitle = _subtitle(l10n);
    final hint = _hint(l10n);
    final isRows = step.layout == OptionLayout.rows;

    final options = [
      for (final option in step.options)
        OptionCard(
          label: l10n.optionLabel(option.id),
          icon: option.icon,
          chip: option.chip,
          logoAsset: option.logoAsset,
          layout: step.layout,
          serif: step.serif,
          selected: isSelected(option.id),
          onTap: () => onSelect(option.id),
        ),
    ];

    final grid = isRows
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, option) in options.indexed) ...[
                option,
                if (index < options.length - 1) SizedBox(height: 13.h),
              ],
            ],
          )
        : _Grid(
            columns: step.layout == OptionLayout.tiles ? 3 : 2,
            spacing: step.layout == OptionLayout.tiles ? 12.w : 13.w,
            aspectRatio: step.layout == OptionLayout.tiles ? 1 : 1.32,
            children: options,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTextStyles.h1),
        if (subtitle != null) ...[
          SizedBox(height: 10.h),
          Text(subtitle, style: AppTextStyles.subtitleTight),
        ],
        // Row layouts sit right under the title; grids centre in the remaining space.
        if (isRows)
          Padding(padding: EdgeInsets.only(top: 20.h), child: grid)
        else
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hint != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: Text(hint, style: AppTextStyles.hint),
                  ),
                grid,
              ],
            ),
          ),
      ],
    );
  }

  String _title(AppL10n l10n) => switch (step.id) {
        StepIds.age => l10n.onbAgeTitle,
        StepIds.goal => l10n.onbGoalTitle,
        StepIds.blocker => l10n.onbBlockerTitle,
        StepIds.cookTime => l10n.onbCookTimeTitle,
        StepIds.country => l10n.onbCountryTitle,
        StepIds.europeCountry => l10n.onbEuropeTitle,
        StepIds.store => l10n.onbStoreTitle,
        StepIds.cravings => l10n.onbCravingsTitle,
        StepIds.diet => l10n.onbDietTitle,
        StepIds.allergies => l10n.onbAllergiesTitle,
        StepIds.proteins => l10n.onbProteinsTitle,
        StepIds.appliances => l10n.onbAppliancesTitle,
        _ => '',
      };

  String? _subtitle(AppL10n l10n) => switch (step.id) {
        StepIds.age => l10n.onbAgeSubtitle,
        StepIds.cookTime => l10n.onbCookTimeSubtitle,
        StepIds.country => l10n.onbCountrySubtitle,
        StepIds.europeCountry => l10n.onbEuropeSubtitle,
        StepIds.store => l10n.onbStoreSubtitle,
        _ => null,
      };

  String? _hint(AppL10n l10n) => switch (step.id) {
        StepIds.cravings => l10n.chooseUpToThree,
        StepIds.diet || StepIds.allergies => l10n.chooseAllThatApply,
        StepIds.proteins => l10n.onbProteinsHint,
        StepIds.appliances => l10n.onbAppliancesHint,
        _ => null,
      };
}

/// Fixed-column grid built from rows, so it supports intrinsic sizing (unlike GridView).
class _Grid extends StatelessWidget {
  const _Grid({
    required this.columns,
    required this.spacing,
    required this.aspectRatio,
    required this.children,
  });

  final int columns;
  final double spacing;
  final double aspectRatio;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < children.length; start += columns) ...[
          if (start > 0) SizedBox(height: spacing),
          Row(
            children: [
              for (var i = start; i < start + columns; i++) ...[
                if (i > start) SizedBox(width: spacing),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: i < children.length ? children[i] : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
