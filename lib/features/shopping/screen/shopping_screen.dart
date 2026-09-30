import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/check_circle.dart';
import '../../../core/widget/primary_button.dart';
import '../../../core/widget/sub_screen_header.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../cubit/shopping_cubit.dart';
import '../model/shopping_item.dart';

/// The full shopping list, grouped by aisle. Ticking an item is optimistic.
class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ShoppingScreen()));

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
                    SubScreenHeader(
                      eyebrow: l10n.shoppingEyebrow,
                      title: l10n.shoppingList,
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        _Pill(text: store.displayName, tinted: true),
                        SizedBox(width: 10.w),
                        _Pill(text: l10n.shoppingDoneCount(state.checkedCount, state.total)),
                      ],
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
                          // Builder gives the button's own context to anchor the iPad popover.
                          child: Builder(
                            builder: (buttonContext) => SecondaryButton(
                              label: l10n.shoppingShare,
                              onPressed: () => _shareList(buttonContext),
                            ),
                          ),
                        ),
                      ],
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

  /// Puts the list on the clipboard.
  void _copyList(BuildContext context) {
    Haptics.confirm();
    Clipboard.setData(ClipboardData(text: context.read<ShoppingCubit>().asPlainText()));
  }

  /// Opens the native share sheet, anchored to the share button.
  Future<void> _shareList(BuildContext context) async {
    Haptics.confirm();
    final l10n = AppL10n.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final shared = await context.read<ShoppingCubit>().share(
          subject: l10n.shoppingList,
          origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        );
    if (!shared && context.mounted) showErrorBanner(context, l10n.errorShoppingShare);
  }
}

/// A rounded label: the store (tinted) or the done count (outlined).
class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.tinted = false});

  final String text;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: tinted ? AppColors.brandSoft : AppColors.surface,
        border: tinted ? null : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Text(
        text,
        style: AppTextStyles.storePill.copyWith(color: tinted ? AppColors.brandDark : AppColors.ink),
      ),
    );
  }
}

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
            Text(item.icon, style: AppTextStyles.emojiIcon.copyWith(fontSize: 22.sp)),
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
