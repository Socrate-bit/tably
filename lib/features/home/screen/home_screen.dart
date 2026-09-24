import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/slide_in.dart';
import '../../account/screen/account_screen.dart';
import '../../plan/screen/menu_screen.dart';
import '../../plan/screen/stores_screen.dart';
import '../../preferences/screen/preferences_screen.dart';
import '../../recipe/screen/favourites_screen.dart';
import '../../recipe/screen/recipes_screen.dart';
import '../../recipe/widget/add_recipe_sheet.dart';
import '../cubit/home_cubit.dart';
import '../widget/tab_bar.dart';

/// The signed-in app shell: four tabs, the favourites and stores screens that
/// keep the tab bar, and the add-recipe button on the recipes tab.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, home) {
        final body = switch (home.sub) {
          HomeSub.favourites => const FavouritesScreen(),
          HomeSub.stores => const StoresScreen(),
          HomeSub.none => switch (home.tab) {
              HomeTab.menu => const MenuScreen(),
              HomeTab.recipes => const RecipesScreen(),
              HomeTab.preferences => const PreferencesScreen(),
              HomeTab.account => const AccountScreen(),
            },
        };

        return Scaffold(
          backgroundColor: AppColors.scaffold,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // A fresh key per destination replays the slide and resets scroll.
                SlideIn(key: ValueKey(home), child: body),
                if (home.tab == HomeTab.recipes && home.sub == HomeSub.none)
                  Positioned(
                    right: 22.w,
                    bottom: 22.h,
                    child: _AddRecipeButton(onTap: () => AddRecipeSheet.show(context)),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: AppTabBar(current: home.tab, onSelected: context.read<HomeCubit>().select),
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
            BoxShadow(color: AppColors.brand.withValues(alpha: 0.42), blurRadius: 24.r, offset: Offset(0, 10.h)),
          ],
        ),
        child: Text('+', style: AppTextStyles.fabGlyph),
      ),
    );
  }
}
