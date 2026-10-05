import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/chat_cubit.dart';
import '../tool/chat_tool.dart';

/// "The chef is thinking…", or what the tool running now is doing.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key, this.activity});

  /// The tool running now, if any.
  final String? activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final kind = activity == null ? null : context.read<ChatCubit>().kindOf(activity!);
    final label = switch ((activity, kind)) {
      ('create_custom_recipe' || 'derive_recipe', _) => l10n.chatActivityWriting,
      (_, ToolKind.quota) => l10n.chatActivitySearching,
      (_, ToolKind.read) => l10n.chatActivityReading,
      (_, ToolKind.write) => l10n.chatActivityPreparing,
      _ => l10n.chatThinking,
    };
    return Row(
      children: [
        SizedBox(
          width: 16.r,
          height: 16.r,
          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
        ),
        SizedBox(width: 10.w),
        Flexible(child: Text(label, style: AppTextStyles.metaMuted)),
      ],
    );
  }
}
