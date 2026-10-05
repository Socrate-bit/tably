import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/shopping_cubit.dart';
import '../model/shopping_item.dart';

/// Renames a shopping item or changes its amount, in its own unit.
class ShoppingItemDialog extends StatefulWidget {
  const ShoppingItemDialog({super.key, required this.item});

  final ShoppingItem item;

  static Future<void> show(BuildContext context, ShoppingItem item) =>
      showDialog<void>(context: context, builder: (_) => ShoppingItemDialog(item: item));

  @override
  State<ShoppingItemDialog> createState() => _ShoppingItemDialogState();
}

class _ShoppingItemDialogState extends State<ShoppingItemDialog> {
  late final _name = TextEditingController(text: widget.item.name);
  late final _amount = TextEditingController(
    text: widget.item.hasAmount ? _trim(widget.item.amount) : '',
  );

  static String _trim(double amount) =>
      amount == amount.roundToDouble() ? '${amount.toInt()}' : amount.toStringAsFixed(1);

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Haptics.confirm();
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.')) ?? 0;
    context.read<ShoppingCubit>().edit(update: [widget.item.copyWith(name: name, amount: amount)]);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final unit = l10n.unitLabel(widget.item.unit, 2);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      title: Text(l10n.shoppingEditTitle, style: AppTextStyles.sheetTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.searchInput,
            decoration: InputDecoration(hintText: l10n.shoppingEditName),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: AppTextStyles.searchInput,
            decoration: InputDecoration(hintText: l10n.shoppingEditAmount, suffixText: unit),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Haptics.tap();
            Navigator.of(context).pop();
          },
          child: Text(l10n.actionCancel, style: AppTextStyles.secondaryButton),
        ),
        TextButton(
          onPressed: _save,
          child: Text(l10n.actionSave, style: AppTextStyles.secondaryButton.copyWith(color: AppColors.brand)),
        ),
      ],
    );
  }
}
