import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../account/screen/account_screen.dart';
import '../../plan/screen/menu_screen.dart';
import '../../preferences/screen/preferences_screen.dart';
import '../../recipe/screen/explore_screen.dart';
import '../../recipe/widget/add_recipe_sheet.dart';
import '../cubit/home_cubit.dart';
import '../widget/tab_bar.dart';

/// The signed-in app shell: four tabs plus the add-recipe button that only
/// appears on the recipes tab.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeTab>(
      builder: (context, tab) {
        return Scaffold(
          backgroundColor: AppColors.scaffold,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // IndexedStack keeps each tab's scroll position.
                IndexedStack(
                  index: tab.index,
                  children: const [
                    MenuScreen(),
                    ExploreScreen(),
                    PreferencesScreen(),
                    AccountScreen(),
                  ],
                ),
                if (tab == HomeTab.recipes)
                  Positioned(
                    right: 22.w,
                    bottom: 22.h,
                    child: _AddRecipeButton(onTap: () => AddRecipeSheet.show(context)),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: AppTabBar(
            current: tab,
            onSelected: context.read<HomeCubit>().select,
          ),
        );
      },
    );
  }
}

/// The blue floating "+" on the recipes tab.
class _AddRecipeButton extends StatelessWidget {
  const _AddRecipeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.confirm();
        onTap();
      },
      child: Container(
        width: 62.r,
        height: 62.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.42),
              blurRadius: 24.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Text(
          '+',
          style: TextStyle(
            fontSize: 32.sp,
            color: AppColors.surface,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
    );
  }
}
