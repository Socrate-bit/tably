import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/sub_screen_header.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/cubit/home_cubit.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/model/user_profile.dart';
import '../cubit/plan_cubit.dart';
import '../model/week_plan.dart';

/// "Supermarché": this week's plan priced at every store; tap one to switch.
class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final profile = context.select<ProfileCubit, UserProfile>((c) => c.state.profile);
    final week = context.select<PlanCubit, WeekPlan>((c) => c.state.week);
    final home = context.read<HomeCubit>();
    final current = week.totalAt(profile.store);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 26.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SubScreenHeader(title: l10n.storesTitle, subtitle: l10n.storesSubtitle, onBack: home.closeSub),
          SizedBox(height: 26.h),
          for (final store in Store.values) ...[
            _StoreRow(
              store: store,
              price: week.totalAt(store),
              currentPrice: current,
              currentStore: profile.store,
              country: profile.country,
              onTap: () {
                context.read<ProfileCubit>().setStore(store);
                home.closeSub();
              },
            ),
            SizedBox(height: 11.h),
          ],
          SizedBox(height: 7.h),
          Text(l10n.storesFootnote(week.recipeCount), style: AppTextStyles.subScreenSubtitle.copyWith(height: 1.5, fontSize: 13.sp)),
        ],
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.store,
    required this.price,
    required this.currentPrice,
    required this.currentStore,
    required this.country,
    required this.onTap,
  });

  final Store store;
  final double price;
  final double currentPrice;
  final Store currentStore;
  final Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final isCurrent = store == currentStore;
    final diff = price - currentPrice;
    final cheaper = !isCurrent && diff < 0;
    final delta = isCurrent
        ? l10n.storesCurrent
        : cheaper
            ? l10n.storesCheaper(formatMoney(country, diff.abs()), currentStore.displayName)
            : l10n.storesPricier(formatMoney(country, diff));

    return SurfaceCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.r),
      borderColor: isCurrent ? AppColors.brand : AppColors.border,
      borderWidth: isCurrent ? 2.5 : 1,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Image.asset(store.logoAsset, width: 52.r, height: 52.r, fit: BoxFit.cover),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.displayName, style: AppTextStyles.listItemTitle),
                SizedBox(height: 3.h),
                Text(delta, style: AppTextStyles.storeDelta.copyWith(color: cheaper ? AppColors.brandDark : null)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatMoney(country, price), style: AppTextStyles.storePrice.copyWith(color: cheaper ? AppColors.brand : null)),
              if (isCurrent) ...[
                SizedBox(height: 2.h),
                Text(l10n.storesCurrentTag, style: AppTextStyles.savings.copyWith(fontSize: 12.sp, letterSpacing: 0.5.sp)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
