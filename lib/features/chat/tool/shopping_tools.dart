import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/model/aisle.dart';
import '../../../core/model/ingredient_unit.dart';
import '../../shopping/cubit/shopping_cubit.dart';
import '../../shopping/model/shopping_item.dart';
import 'chat_tool.dart';
import 'chat_tools.dart';
import 'tool_payloads.dart';

/// Reading, editing and sharing the shopping list.
List<ChatTool> shoppingTools(ChatTools t) {
  final units = [for (final u in IngredientUnit.values) u.id];
  final aisles = [for (final a in Aisle.values) a.id];

  return [
    ChatTool(
      kind: ToolKind.read,
      declaration: NoArgsDeclaration(
        'get_shopping_list',
        "The week's shopping list: every item with its id, amount, aisle and whether it is ticked.",
      ),
      run: (args, context) async => ToolResult({'items': ToolPayloads.shopping(t.shopping.state.visibleItems)}),
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: FunctionDeclaration(
        'edit_shopping_list',
        'Changes the shopping list in one go: add items, remove items the user already has, change an '
            "item's name or amount, tick or untick items. Item ids come from get_shopping_list. Items stay "
            'edited when the week changes, as long as the week still needs them.',
        parameters: {
          'add': Schema.array(
            items: Schema.object(
              properties: {
                'name': Schema.string(description: "In the user's language, lower case."),
                'amount': Schema.number(description: '0 when no amount.'),
                'unit': Schema.enumString(enumValues: units),
                'aisle': Schema.enumString(enumValues: aisles),
                'icon': Schema.string(description: 'One emoji.'),
              },
              optionalProperties: ['amount', 'unit', 'aisle', 'icon'],
            ),
          ),
          'remove': Schema.array(items: Schema.string(), description: 'Item ids.'),
          'update': Schema.array(
            items: Schema.object(
              properties: {
                'id': Schema.string(),
                'name': Schema.string(),
                'amount': Schema.number(),
                'unit': Schema.enumString(enumValues: units),
              },
              optionalProperties: ['name', 'amount', 'unit'],
            ),
          ),
          'check': Schema.array(items: Schema.string(), description: 'Item ids to tick.'),
          'uncheck': Schema.array(items: Schema.string(), description: 'Item ids to untick.'),
        },
        optionalParameters: ['add', 'remove', 'update', 'check', 'uncheck'],
      ),
      run: (args, context) async {
        final items = {for (final i in t.shopping.state.visibleItems) i.id: i};
        final ids = [
          ...?args.strings('remove'),
          ...?args.strings('check'),
          ...?args.strings('uncheck'),
          for (final u in args.objects('update')) ?u.string('id'),
        ];
        final unknown = ids.where((id) => !items.containsKey(id)).toSet();
        if (unknown.isNotEmpty) return ToolResult({'error': 'unknown_item_ids', 'ids': unknown.toList()});

        final add = [
          for (final a in args.objects('add'))
            if (a.string('name') case final name?)
              ShoppingCubit.newItem(
                name: name,
                amount: a.number('amount') ?? 0,
                unit: IngredientUnit.fromId(a.string('unit')),
                aisle: Aisle.fromId(a.string('aisle')),
                icon: a.string('icon') ?? '🛒',
              ),
        ];
        final update = [
          for (final u in args.objects('update'))
            items[u.string('id')]!.copyWith(
              name: u.string('name'),
              amount: u.number('amount'),
              unit: u.string('unit') == null ? null : IngredientUnit.fromId(u.string('unit')),
            ),
        ];
        final remove = {...?args.strings('remove')};
        final check = {...?args.strings('check')};
        final uncheck = {...?args.strings('uncheck')};
        if (add.isEmpty && update.isEmpty && remove.isEmpty && check.isEmpty && uncheck.isEmpty) {
          return const ToolResult({'unchanged': true});
        }
        List<String> names(Iterable<String> ids) => [for (final id in ids) items[id]!.name];
        return ToolProposal(
          preview: {
            'add': [for (final i in add) _line(i)],
            'remove': names(remove),
            'update': [
              for (final u in update) {..._line(u), 'from': items[u.id]!.name},
            ],
            'check': names(check),
            'uncheck': names(uncheck),
          },
          commit: () async {
            final done = await t.shopping.edit(
              add: add,
              remove: remove,
              update: update,
              check: check,
              uncheck: uncheck,
            );
            return done ? {'ok': true} : {'error': 'save_failed'};
          },
        );
      },
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: NoArgsDeclaration(
        'share_shopping_list',
        "Opens the phone's share sheet with the shopping list as text, to send it by message or email.",
      ),
      // The card shares it itself: the share sheet needs the screen.
      run: (args, context) async => ToolProposal(preview: const {}, commit: () async => {'error': 'not_shared'}),
    ),
  ];
}

/// A line the card shows: the item's name and amount, in ids it localises.
Map<String, Object?> _line(ShoppingItem item) => {'name': item.name, 'amount': item.amount, 'unit': item.unit.id};
