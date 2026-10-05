import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/circle_icon_button.dart';
import '../../../core/widget/input_bar.dart';
import '../../../core/widget/sub_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/chat_cubit.dart';
import '../model/chat_message.dart';
import '../widget/action_card.dart';
import '../widget/message_bubble.dart';
import '../widget/starter_prompts.dart';
import '../widget/typing_indicator.dart';

/// The conversation with the AI chef, pushed full-screen over the app.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChatScreen()));

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().refresh();
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppL10n.of(context);
    final cubit = context.read<ChatCubit>();
    final clear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
        title: Text(l10n.chatClearTitle, style: AppTextStyles.sheetTitle),
        content: Text(l10n.chatClearBody, style: AppTextStyles.settingsRowSub),
        actions: [
          TextButton(
            onPressed: () {
              Haptics.tap();
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(l10n.actionCancel, style: AppTextStyles.secondaryButton),
          ),
          TextButton(
            onPressed: () {
              Haptics.confirm();
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(l10n.chatClearConfirm, style: AppTextStyles.secondaryButton.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (clear == true) await cubit.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final cubit = context.read<ChatCubit>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: BlocConsumer<ChatCubit, ChatState>(
          // A failed turn shows inline with a retry; only other failures,
          // such as clearing, need a banner.
          listenWhen: (previous, current) =>
              current.error != null && previous.error != current.error && current.status != ChatStatus.failed,
          listener: (context, state) {
            showErrorBanner(context, l10n.chatErrorGeneric);
            cubit.errorShown();
          },
          builder: (context, state) {
            // Newest at the bottom, as the list is reversed.
            final items = <Widget>[
              if (state.status == ChatStatus.thinking) TypingIndicator(activity: state.activity),
              if (state.status == ChatStatus.failed) _FailedRow(onRetry: cubit.retry),
              for (final message in state.messages.reversed) _MessageItem(message: message),
            ];
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(AppDimens.pageH, 6.h, AppDimens.pageH, 12.h),
                  child: SubScreenHeader(
                    eyebrow: l10n.chatEyebrow,
                    title: l10n.chatTitle,
                    onBack: () => Navigator.of(context).pop(),
                    trailing: state.messages.isEmpty
                        ? null
                        : CircleIconButton(glyph: '🗑', fontSize: 16, onPressed: () => _confirmClear(context)),
                  ),
                ),
                Expanded(
                  child: state.messages.isEmpty && !state.busy
                      ? StarterPrompts(onPicked: cubit.send)
                      : ListView.separated(
                          reverse: true,
                          padding: EdgeInsets.symmetric(horizontal: AppDimens.pageH, vertical: 12.h),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => SizedBox(height: 12.h),
                          itemBuilder: (_, i) => items[i],
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(AppDimens.pageH, 8.h, AppDimens.pageH, 12.h),
                  child: InputBar(
                    hint: state.status == ChatStatus.confirming ? l10n.chatConfirmHint : l10n.chatHint,
                    glyph: '↑',
                    multiline: true,
                    enabled: !state.busy,
                    onSubmitted: cubit.send,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) =>
      message.role == ChatRole.action ? ActionCard(message: message) : MessageBubble(message: message);
}

/// Shown in place of the chef's answer when a turn failed.
class _FailedRow extends StatelessWidget {
  const _FailedRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(l10n.chatErrorTurn, style: AppTextStyles.bodyMuted.copyWith(color: AppColors.danger)),
        ),
        SizedBox(width: 12.w),
        GestureDetector(
          onTap: () {
            Haptics.tap();
            onRetry();
          },
          child: Text(l10n.chatRetry, style: AppTextStyles.link),
        ),
      ],
    );
  }
}
