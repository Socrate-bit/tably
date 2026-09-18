import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/check_circle.dart';
import '../../../core/widget/circle_icon_button.dart';
import '../../../core/widget/primary_button.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../cubit/shopping_cubit.dart';
import '../model/shopping_item.dart';

/// The full shopping list, grouped by aisle. Ticking an item is optimistic.
class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: BlocListener<ShoppingCubit, ShoppingState>(
          listenWhen: (previous, current) =>
              current.error != null && previous.error != current.error,
          listener: (context, state) {
            showErrorBanner(context, l10n.errorShoppingUpdate);
            context.read<ShoppingCubit>().errorShown();
          },
          child: BlocBuilder<ShoppingCubit, ShoppingState>(
            builder: (context, state) {
              final store = context.select((ProfileCubit c) => c.state.profile.store);
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 26.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(onBack: () => Navigator.of(context).pop()),
                    SizedBox(height: 14.h),
                    Center(
                      child: _StorePill(
                        store: store,
                        checked: state.checkedCount,
                        total: state.total,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: l10n.shoppingCopyList,
                            onPressed: () => _copyList(context),
                          ),
                        ),
                        SizedBox(width: 11.w),
                        Expanded(
                          child: SecondaryButton(
                            label: l10n.shoppingShare,
                            onPressed: () => _copyList(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    PrimaryButton(
                      label: '+ ${l10n.shoppingAddItems}',
                      fontSize: 16,
                      verticalPadding: 17.h,
                      onPressed: () {},
                    ),
                    SizedBox(height: 24.h),
                    for (final category in state.categories)
                      Padding(
                        padding: EdgeInsets.only(bottom: 24.h),
                        child: _CategorySection(category: category),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Copy and share both put the list on the clipboard for now.
  void _copyList(BuildContext context) {
    Haptics.confirm();
    Clipboard.setData(ClipboardData(text: context.read<ShoppingCubit>().asPlainText()));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Row(
      children: [
        CircleIconButton(glyph: '←', onPressed: onBack),
        Expanded(
          child: Padding(
            // Balances the back button so the title stays optically centred.
            padding: EdgeInsets.only(right: 42.w),
            child: Column(
              children: [
                Text(l10n.shoppingEyebrow, style: AppTextStyles.eyebrow.copyWith(letterSpacing: 1.8.sp)),
                SizedBox(height: 2.h),
                Text(
                  l10n.shoppingList,
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 29.sp),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Lidl · 4/34 faits"
class _StorePill extends StatelessWidget {
  const _StorePill({required this.store, required this.checked, required this.total});

  final String store;
  final int checked;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(26.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(store, style: AppTextStyles.meta.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          )),
          SizedBox(width: 10.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.info,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              AppL10n.of(context).shoppingDoneCount(checked, total),
              style: AppTextStyles.meta.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.infoInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One aisle: a label above a card of rows.
class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});

  final ShoppingCategory category;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Text(category.name, style: AppTextStyles.groupLabel),
        ),
        SurfaceCard(
          clip: true,
          child: Column(
            children: [
              for (final (index, item) in category.items.indexed)
                _ItemRow(item: item, isLast: index == category.items.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.isLast});

  final ShoppingItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return GestureDetector(
      onTap: () {
        Haptics.toggle();
        context.read<ShoppingCubit>().toggle(item);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Text(item.icon, style: TextStyle(fontSize: 22.sp)),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.listItemTitle.copyWith(
                      color: item.checked ? AppColors.textDisabled : AppColors.ink,
                      decoration: item.checked ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textDisabled,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(l10n.shoppingNeeded(item.needed), style: AppTextStyles.metaMuted),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              item.quantity,
              style: AppTextStyles.secondaryButton.copyWith(
                fontSize: 16.sp,
                color: AppColors.inkMuted,
              ),
            ),
            SizedBox(width: 12.w),
            CheckCircle(checked: item.checked),
          ],
        ),
      ),
    );
  }
}
