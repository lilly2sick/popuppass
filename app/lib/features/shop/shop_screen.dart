import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/pp_scaffold.dart';
import '../../data/db/database.dart';
import '../../design/components/sticker.dart';
import '../../design/tokens.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import 'product_editor.dart';

enum _Filter { all, low, margin }

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;

  Future<void> _importCsv() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return;
    final importer = ref.read(csvProductImportProvider)..pendingText = utf8.decode(bytes);
    await importer.ingest();
  }

  static int _margin(Product p) =>
      p.priceCents == 0 ? 0 : ((p.priceCents - p.unitCostCents) * 100 / p.priceCents).round();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(productsProvider).valueOrNull ?? const <Product>[];
    final stock = ref.watch(stockProvider).valueOrNull ?? const {};
    final units = stock.values.fold<int>(0, (a, b) => a + b);

    var shown = _query.isEmpty
        ? [...all]
        : all.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();
    if (_filter == _Filter.low) {
      shown = shown.where((p) => (stock[p.id] ?? 0) <= p.lowStockThreshold).toList();
    }
    if (_filter == _Filter.margin) shown.sort((a, b) => _margin(b).compareTo(_margin(a)));

    Widget dot(String g, Color c) => Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      child: Text(
        g,
        style: PPType.body(size: 12, weight: FontWeight.w900, color: PPColors.onAccent),
      ),
    );

    Widget segment(_Filter f, String label, [Widget? lead]) {
      final on = f == _filter;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: on ? PPColors.teal : PPColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (lead != null) ...[lead, const SizedBox(width: 6)],
                  Text(
                    label,
                    style: PPType.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: on ? PPColors.onAccent : PPColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return PPScaffold(
      eyebrow: l10n.shopEyebrow(all.length, units),
      title: l10n.shopTitle,
      searchHint: l10n.shopSearchHint,
      onSearch: (q) => setState(() => _query = q.trim()),
      onSearchSubmit: (_) {},
      action: PPButton(
        label: l10n.shopAddItem,
        icon: Icons.add_rounded,
        onPressed: () => showProductEditor(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: PPSurface.decoration(radius: 16),
            child: Row(
              children: [
                segment(_Filter.all, l10n.shopFilterAll),
                const SizedBox(width: 6),
                segment(_Filter.low, l10n.shopFilterLow, dot('!', PPColors.pink)),
                const SizedBox(width: 6),
                segment(_Filter.margin, l10n.shopFilterMargin, dot('+', PPColors.teal)),
              ],
            ),
          ),
          const SizedBox(height: PPSpace.md),
          for (final p in shown) ...[
            _ProductRow(product: p, inStock: stock[p.id] ?? 0, margin: _margin(p)),
            const SizedBox(height: PPSpace.sm),
          ],
          if (shown.isEmpty)
            EmptyState(
              title: all.isEmpty ? l10n.shopStartTitle : l10n.shopEmptyTitle,
              message: all.isEmpty ? l10n.shopStartMessage : l10n.shopEmptyMessage,
            ),
          const SizedBox(height: PPSpace.sm),
          PPButton(label: l10n.shopImportCsv, kind: PPButtonKind.dashed, onPressed: _importCsv),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.inStock, required this.margin});

  final Product product;
  final int inStock;
  final int margin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = product;
    final low = inStock <= p.lowStockThreshold;
    return StickerCard(
      radius: PPRadius.tile,
      padding: const EdgeInsets.symmetric(horizontal: PPSpace.md, vertical: 10),
      onTap: () => showProductEditor(context, product: p),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: PPColors.badgeGradient),
            ),
          ),
          const SizedBox(width: PPSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PPType.body(size: 15, weight: FontWeight.w800),
                      ),
                    ),
                    Text(Money.format(p.priceCents), style: PPType.number(size: 17)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    low
                        ? PPPill(l10n.shopLeft(inStock), tone: PillTone.warn)
                        : PPPill(l10n.shopInStock(inStock), glyph: '#'),
                    PPPill(
                      l10n.shopMarginPct(margin),
                      tone: margin >= 60 ? PillTone.good : PillTone.info,
                      glyph: margin >= 60 ? '+' : '-',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
