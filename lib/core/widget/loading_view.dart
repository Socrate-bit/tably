import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

/// Full-screen spinner shown while auth or the profile is still resolving.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 28.r,
          height: 28.r,
          child: const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brand),
        ),
      ),
    );
  }
}
