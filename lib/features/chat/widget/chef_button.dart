import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/app_logo.dart';
import '../screen/chat_screen.dart';

/// The round orange button with the Tably chef beside the tab bar, as tall
/// as the bar, opening the AI chef's chat.
class ChefButton extends StatelessWidget {
  const ChefButton({super.key});

  @override
  Widget build(BuildContext context) {
    final size = AppDimens.tabBarHeight;
    return GestureDetector(
      onTap: () {
        Haptics.confirm();
        ChatScreen.open(context);
      },
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brandLight, AppColors.brandDeep],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.brand.withValues(alpha: 0.42), blurRadius: 24.r, offset: Offset(0, 10.h)),
          ],
        ),
        child: AppLogo(size: size * 0.86),
      ),
    );
  }
}
