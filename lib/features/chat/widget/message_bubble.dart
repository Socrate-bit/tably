import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/app_logo.dart';
import '../model/chat_message.dart';
import 'chat_recipe_card.dart';

/// A message from the user (right, orange) or the chef (left, white, beside
/// the Tably logo), with any recipes the chef suggested as cards beneath.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.role == ChatRole.user;
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: mine ? 300.w : 270.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: mine ? AppColors.brand : AppColors.surface,
          border: mine ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(mine ? 20.r : 6.r),
            bottomRight: Radius.circular(mine ? 6.r : 20.r),
          ),
        ),
        child: SelectableText(
          message.text,
          style: AppTextStyles.body.copyWith(color: mine ? AppColors.surface : AppColors.inkBody),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty) mine ? bubble : ChefAvatarRow(child: bubble),
        for (final recipe in message.recipes) ...[SizedBox(height: 8.h), ChatRecipeCard(recipe: recipe)],
      ],
    );
  }
}

/// The Tably logo as the chef's avatar, beside what the chef says.
class ChefAvatarRow extends StatelessWidget {
  const ChefAvatarRow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppLogo(size: 34.r),
        SizedBox(width: 6.w),
        Flexible(child: child),
      ],
    );
  }
}
