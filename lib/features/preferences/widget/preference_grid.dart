import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/option_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/model/onboarding_step.dart';

/// Heading + optional subtitle used before every preferences section.
class PreferenceSectionHeader extends StatelessWidget {
  const PreferenceSectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.settingsSectionTitle),
        if (subtitle != null) ...[
          SizedBox(height: 2.h),
          Text(subtitle!, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}

/// Two-column grid of multi-select option cards, driven by an enum.
class PreferenceGrid<T extends Enum> extends StatelessWidget {
  const PreferenceGrid({
    super.key,
    required this.values,
    required this.idOf,
    required this.iconOf,
    required this.selected,
    required this.onToggle,
  });

  final List<T> values;
  final String Function(T) idOf;
  final String Function(T) iconOf;
  final Set<T> selected;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Otherwise the grid pads itself with the tab bar inset from MediaQuery.
      padding: EdgeInsets.zero,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.42,
      children: [
        for (final value in values)
          OptionCard(
            label: l10n.optionLabel(idOf(value)),
            icon: iconOf(value),
            layout: OptionLayout.grid,
            selected: selected.contains(value),
            onTap: () => onToggle(value),
          ),
      ],
    );
  }
}
