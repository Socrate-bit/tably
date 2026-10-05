import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../model/chat_message.dart';
import 'chat_recipe_card.dart';

/// A message from the user (right, orange) or the chef (left, white), with
/// any recipes the chef suggested as cards beneath.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.role == ChatRole.user;
    return Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300.w),
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
          ),
        for (final recipe in message.recipes) ...[SizedBox(height: 8.h), ChatRecipeCard(recipe: recipe)],
      ],
    );
  }
}
