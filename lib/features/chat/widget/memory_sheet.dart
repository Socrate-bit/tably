import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widget/app_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/widget/custom_instructions_field.dart';

/// What the chef remembers about the user: their custom instructions, the
/// same text as in Preferences, to read and edit from the chat.
class MemorySheet extends StatelessWidget {
  const MemorySheet({super.key});

  static Future<void> show(BuildContext context) => AppSheet.show<void>(context, (_) => const MemorySheet());

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final instructions = context.select<ProfileCubit, String>((c) => c.state.profile.customInstructions);
    return AppSheet(
      title: l10n.chatMemoryTitle,
      subtitle: l10n.chatMemorySub,
      child: SingleChildScrollView(
        child: CustomInstructionsField(
          text: instructions,
          onSaved: context.read<ProfileCubit>().setCustomInstructions,
        ),
      ),
    );
  }
}
