import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../design/components/sticker.dart';
import '../../design/tokens.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/haptics_service.dart';

/// Create / edit / delete a product, with the Price Helper built in.
Future<void> showProductEditor(BuildContext context, {Product? product}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: _ProductEditor(product: product),
      ),
    );

class _ProductEditor extends ConsumerStatefulWidget {
  const _ProductEditor({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<_ProductEditor> {
  late final _name = TextEditingController(text: widget.product?.name);
  late final _price = TextEditingController(text: _dollars(widget.product?.priceCents));
  late final _cost = TextEditingController(text: _dollars(widget.product?.unitCostCents));
  late final _minutes = TextEditingController(text: widget.product?.minutesToMake?.toString());
  final _qty = TextEditingController();

  static String? _dollars(int? cents) => cents == null ? null : (cents / 100).toStringAsFixed(2);
  static int _cents(String s) => ((double.tryParse(s.replaceAll(r'$', '')) ?? 0) * 100).round();

  @override
  void dispose() {
    for (final c in [_name, _price, _cost, _minutes, _qty]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final repo = ref.read(productRepoProvider);
    final id = await repo.save(
      ProductsCompanion(
        id: widget.product == null ? const Value.absent() : Value(widget.product!.id),
        name: Value(_name.text.trim()),
        priceCents: Value(_cents(_price.text)),
        unitCostCents: Value(_cents(_cost.text)),
        minutesToMake: Value(int.tryParse(_minutes.text)),
      ),
    );
    final qty = int.tryParse(_qty.text) ?? 0;
    if (qty > 0) await ref.read(inventoryRepoProvider).restock(id, qty);
    await ref.read(hapticsProvider).play(HapticMoment.success);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(productRepoProvider).softDelete(widget.product!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = ref.watch(currentEventProvider).valueOrNull;
    final suggestion = ref
        .watch(pricingProvider)
        .suggest(
          materialCents: _cents(_cost.text),
          minutes: int.tryParse(_minutes.text) ?? 0,
          boothFeeCents: event?.boothFeeCents ?? 0,
        );

    Widget field(TextEditingController c, String label, {TextInputType? type}) => Padding(
      padding: const EdgeInsets.only(bottom: PPSpace.md),
      child: TextField(
        controller: c,
        keyboardType: type,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: label),
      ),
    );

    const money = TextInputType.numberWithOptions(decimal: true);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(PPSpace.gutter, 0, PPSpace.gutter, PPSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.product == null ? l10n.editorNewItem : l10n.editorEditItem,
            style: PPType.title(),
          ),
          const SizedBox(height: PPSpace.lg),
          field(_name, l10n.editorName),
          field(_cost, l10n.editorMaterialsPerItem, type: money),
          field(_minutes, l10n.editorMinutesToMake, type: TextInputType.number),
          StickerCard(
            fill: PPColors.violetSoft,
            shadow: false,
            padding: const EdgeInsets.all(PPSpace.md),
            child: Text(
              l10n.editorPriceSuggestion(
                    Money.format(suggestion.lowCents),
                    Money.format(suggestion.highCents),
                  ) +
                  (suggestion.breakEvenUnits > 0
                      ? l10n.editorPriceSuggestionBreakEven(suggestion.breakEvenUnits)
                      : ''),
              style: PPType.body(size: 14, weight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: PPSpace.md),
          field(_price, l10n.editorPrice, type: money),
          field(
            _qty,
            widget.product == null ? l10n.editorStartingStock : l10n.editorAddStock,
            type: TextInputType.number,
          ),
          PPButton(label: l10n.editorSave, onPressed: _save, expand: true),
          if (widget.product != null) ...[
            const SizedBox(height: PPSpace.sm),
            PPButton(
              label: l10n.editorDeleteItem,
              kind: PPButtonKind.dashed,
              onPressed: _delete,
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}
