import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/slide_in.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/screen/account_screen.dart';
import '../../chat/widget/chef_button.dart';
import '../../onboarding/screen/generating_screen.dart';
import '../../plan/cubit/plan_cubit.dart';
import '../../plan/screen/menu_screen.dart';
import '../../plan/screen/stores_screen.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/screen/preferences_screen.dart';
import '../../recipe/cubit/catalogue_cubit.dart';
import '../../recipe/screen/favourites_screen.dart';
import '../../recipe/screen/recipes_screen.dart';
import '../../recipe/widget/add_recipe_sheet.dart';
import '../cubit/home_cubit.dart';
import '../widget/tab_bar.dart';

/// The signed-in app shell: three tabs, the favourites, stores and account screens that
/// keep the tab bar, and the AI chef's button beside it.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, home) {
        final body = switch (home.sub) {
          HomeSub.favourites => const FavouritesScreen(),
          HomeSub.stores => const StoresScreen(),
          HomeSub.account => const AccountScreen(),
          HomeSub.none => switch (home.tab) {
            HomeTab.menu => const MenuScreen(),
            HomeTab.recipes => const RecipesScreen(),
            HomeTab.preferences => const PreferencesScreen(),
          },
        };

        final shell = Scaffold(
          backgroundColor: AppColors.scaffold,
          // Content scrolls beneath the floating glass bar.
          extendBody: true,
          body: SafeArea(
            bottom: false,
            // A fresh key per destination replays the slide and resets scroll.
            child: SlideIn(key: ValueKey(home), child: body),
          ),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(left: 9.w, right: 9.w, bottom: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppTabBar(current: home.tab, onSelected: context.read<HomeCubit>().select),
                ),
                SizedBox(width: 12.w),
                const ChefButton(),
                // Hidden for now.
                // _AddRecipeSlot(visible: home.tab == HomeTab.recipes && home.sub == HomeSub.none),
              ],
            ),
          ),
        );

        final regenerating = context.select<PlanCubit, bool>((c) => c.state.regenerating);
        return Stack(
          children: [
            shell,
            // Covers the whole shell, tab bar included, while a new week is fetched.
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: regenerating ? const _GeneratingOverlay() : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The onboarding build screen, shown over Home while the plan regenerates.
class _GeneratingOverlay extends StatelessWidget {
  const _GeneratingOverlay();

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueCubit>().state;
    final name = context.select<ProfileCubit, String>(
      (c) => c.state.profile.displayName(AppL10n.of(context).defaultChefName),
    );
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: GeneratingScreen(
          displayName: name,
          // Once the recipes are saved, only the new week is left to deal.
          generationStep: catalogue.isBuilding ? catalogue.step.index : CatalogueStep.values.length,
        ),
      ),
    );
  }
}

/// Reserves space beside the tab bar for the add-recipe button, collapsing its
/// width when hidden so the bar re-centres. An [OverflowBox] keeps the button
/// at full size throughout, so it slides out rather than shrinking.
class _AddRecipeSlot extends StatefulWidget {
  const _AddRecipeSlot({required this.visible});

  final bool visible;

  @override
  State<_AddRecipeSlot> createState() => _AddRecipeSlotState();
}

class _AddRecipeSlotState extends State<_AddRecipeSlot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: widget.visible ? 1 : 0,
  );
  late final Animation<double> _size = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

  @override
  void didUpdateWidget(_AddRecipeSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      widget.visible ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slot = AppDimens.fab + 12.w;
    return AnimatedBuilder(
      animation: _size,
      builder: (context, child) => SizedBox(
        width: slot * _size.value.clamp(0.0, 1.0),
        // A fixed height stops the OverflowBox from filling the screen, which
        // made the bottom bar full-height and pushed SnackBars off screen.
        height: AppDimens.fab,
        child: child,
      ),
      child: OverflowBox(
        minWidth: slot,
        maxWidth: slot,
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _size,
              child: _AddRecipeButton(onTap: () => AddRecipeSheet.show(context)),
            ),
          ),
        ),
      ),
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
        width: AppDimens.fab,
        height: AppDimens.fab,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.brand.withValues(alpha: 0.42), blurRadius: 24.r, offset: Offset(0, 10.h)),
          ],
        ),
        child: Icon(Icons.add_rounded, size: 60.r, color: AppColors.surface),
      ),
    );
  }
}
