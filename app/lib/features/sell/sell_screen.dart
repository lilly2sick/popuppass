import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/pp_scaffold.dart';
import '../../data/db/database.dart';
import '../../design/components/sticker.dart';
import '../../design/tokens.dart';
import '../../domain/enums.dart';
import '../../domain/money.dart';
import '../../providers.dart';
import '../../services/haptics_service.dart';
import '../search/search_sheet.dart';
import '../shop/product_editor.dart';

/// One big card per item; swipe between them. Pinch out (or tap the grid
/// button) for a Photos-style grid; tap a tile or pinch in to zoom back.
class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  final _pager = PageController(viewportFraction: 0.92);
  String _query = '';
  bool _grid = false;
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  List<Product> _visible(List<Product> all) => _query.isEmpty
      ? all
      : all.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();

  Future<void> _sell(Product p, int before) async {
    final id = await ref
        .read(salesRepoProvider)
        .recordQuickSale(
          product: p,
          method: ref.read(paymentMethodProvider),
          eventId: ref.read(currentEventProvider).valueOrNull?.id,
        );
    final stacks = ref.read(sessionSalesProvider.notifier);
    stacks.state = {
      ...stacks.state,
      p.id: [...?stacks.state[p.id], id],
    };
    final after = before - 1;
    await ref
        .read(hapticsProvider)
        .play(
          after <= 0
              ? HapticMoment.soldOut
              : after <= p.lowStockThreshold
              ? HapticMoment.lowStock
              : HapticMoment.sold,
        );
  }

  /// Takes back this item's most recent sale from this session.
  Future<void> _unsell(Product p) async {
    final stacks = ref.read(sessionSalesProvider.notifier);
    final mine = [...?stacks.state[p.id]];
    if (mine.isEmpty) return;
    final id = mine.removeLast();
    await ref.read(salesRepoProvider).voidSale(id);
    stacks.state = {...stacks.state, p.id: mine};
    await ref.read(hapticsProvider).play(HapticMoment.undo);
  }

  void _setGrid(bool grid) {
    if (grid == _grid) return;
    ref.read(hapticsProvider).play(HapticMoment.selection);
    setState(() => _grid = grid);
  }

  void _openFromGrid(int index) {
    setState(() {
      _grid = false;
      _page = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pager.hasClients) _pager.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(productsProvider).valueOrNull ?? const <Product>[];
    final items = _visible(all);
    final stock = ref.watch(stockProvider).valueOrNull ?? const {};
    final sold = ref.watch(soldCountsProvider).valueOrNull ?? const {};
    final method = ref.watch(paymentMethodProvider);
    final today = ref.watch(todayStatsProvider).valueOrNull ?? const TodayStats();
    final stacks = ref.watch(sessionSalesProvider);

    // Search results elsewhere can ask us to open a specific item.
    ref.listen(sellFocusProvider, (_, id) {
      if (id == null) return;
      final i = items.indexWhere((p) => p.id == id);
      if (i >= 0) _openFromGrid(i);
      ref.read(sellFocusProvider.notifier).state = null;
    });

    final page = items.isEmpty ? 0 : _page.clamp(0, items.length - 1);
    final current = items.isEmpty ? null : items[page];
    final currentLeft = current == null ? 0 : stock[current.id] ?? 0;

    Widget iconButton(IconData icon, String label, VoidCallback onTap, {bool primary = false}) =>
        Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: PPTap.min,
              height: PPTap.min,
              decoration: BoxDecoration(
                color: primary ? PPColors.violet : PPColors.card,
                borderRadius: BorderRadius.circular(14),
                border: primary ? null : Border.all(color: PPColors.lineStrong),
              ),
              child: Icon(icon, color: primary ? PPColors.onAccent : PPColors.text, size: 22),
            ),
          ),
        );

    return PPScaffold(
      title: 'Your table, in a tap.',
      searchHint: 'Search your items',
      onSearch: (q) => setState(() {
        _query = q.trim();
        _page = 0;
      }),
      onSearchSubmit: (_) {},
      scrollable: false,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconButton(
            _grid ? Icons.crop_portrait_rounded : Icons.grid_view_rounded,
            _grid ? 'Back to single item' : 'Zoom out to grid',
            () => _setGrid(!_grid),
          ),
          const SizedBox(width: 6),
          iconButton(
            Icons.add_rounded,
            'Add item',
            () => showProductEditor(context),
            primary: true,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PaymentMethod.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final m = PaymentMethod.values[i];
                return PPChip(
                  label: m.label,
                  selected: m == method,
                  onTap: () {
                    ref.read(hapticsProvider).play(HapticMoment.selection);
                    ref.read(paymentMethodProvider.notifier).state = m;
                  },
                );
              },
            ),
          ),
          const SizedBox(height: PPSpace.md),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    title: _query.isEmpty ? 'No items yet' : 'No match',
                    message: _query.isEmpty
                        ? 'Add your first item with the + button.'
                        : 'Nothing matches "$_query".',
                  )
                : GestureDetector(
                    onScaleUpdate: (d) {
                      if (d.pointerCount < 2) return;
                      if (d.scale < 0.85) _setGrid(true);
                      if (d.scale > 1.15) _setGrid(false);
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, a) => ScaleTransition(
                        scale: Tween(begin: 0.94, end: 1.0).animate(a),
                        child: FadeTransition(opacity: a, child: child),
                      ),
                      child: _grid
                          ? _ItemGrid(
                              key: const ValueKey('grid'),
                              items: items,
                              stock: stock,
                              sold: sold,
                              selected: page,
                              onOpen: _openFromGrid,
                            )
                          : Column(
                              key: const ValueKey('cards'),
                              children: [
                                Expanded(
                                  child: PageView.builder(
                                    controller: _pager,
                                    itemCount: items.length,
                                    onPageChanged: (i) {
                                      ref.read(hapticsProvider).play(HapticMoment.selection);
                                      setState(() => _page = i);
                                    },
                                    itemBuilder: (_, i) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: _ItemCard(
                                        product: items[i],
                                        left: stock[items[i].id] ?? 0,
                                        sold: sold[items[i].id] ?? 0,
                                        position: '${i + 1} / ${items.length}',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: PPSpace.sm),
                                _Dots(count: items.length, index: page),
                              ],
                            ),
                    ),
                  ),
          ),
          if (!_grid && current != null) ...[
            const SizedBox(height: PPSpace.md),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Take back one ${current.name} sale',
                    child: PPButton.secondary(
                      label: '-1',
                      height: 68,
                      onPressed: (stacks[current.id]?.isNotEmpty ?? false)
                          ? () => _unsell(current)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: PPSpace.sm),
                Expanded(
                  flex: 2,
                  child: Semantics(
                    label: 'Sell one ${current.name}',
                    child: PPButton(
                      label: currentLeft <= 0 ? 'Sold out' : '+1 sold',
                      height: 68,
                      onPressed: currentLeft <= 0 ? null : () => _sell(current, currentLeft),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: PPSpace.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'PAID WITH ${method.label}'.toUpperCase(),
                  style: PPType.label(size: 10, color: PPColors.muted),
                ),
              ),
              Text('${Money.format(today.grossCents)} gross', style: PPType.number(size: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.product,
    required this.left,
    required this.sold,
    required this.position,
  });

  final Product product;
  final int left;
  final int sold;
  final String position;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final out = left <= 0;
    final low = !out && left <= p.lowStockThreshold;
    final margin = p.priceCents == 0
        ? 0
        : ((p.priceCents - p.unitCostCents) * 100 / p.priceCents).round();
    return StickerCard(
      iridescent: true,
      fill: PPColors.surface,
      radius: 26,
      padding: const EdgeInsets.all(PPSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: PPColors.badgeGradient,
                ),
              ),
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: PPColors.bg,
                  borderRadius: BorderRadius.circular(PPRadius.chip),
                ),
                child: Text(position, style: PPType.label(size: 11)),
              ),
            ),
          ),
          const SizedBox(height: PPSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PPType.title(size: 26),
                ),
              ),
              const SizedBox(width: PPSpace.sm),
              Text(Money.format(p.priceCents), style: PPType.number(size: 26)),
            ],
          ),
          const SizedBox(height: PPSpace.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (out)
                const PPPill('Sold out', glyph: 'x')
              else if (low)
                PPPill('$left left', tone: PillTone.warn)
              else
                PPPill('$left in stock', glyph: '#'),
              PPPill(
                '$margin% margin',
                tone: margin >= 60 ? PillTone.good : PillTone.info,
                glyph: margin >= 60 ? '+' : '-',
              ),
              PPPill('$sold sold'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({
    super.key,
    required this.items,
    required this.stock,
    required this.sold,
    required this.selected,
    required this.onOpen,
  });

  final List<Product> items;
  final Map<String, int> stock;
  final Map<String, int> sold;
  final int selected;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: PPSpace.sm,
        crossAxisSpacing: PPSpace.sm,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        final left = stock[p.id] ?? 0;
        final low = left <= p.lowStockThreshold;
        return Semantics(
          button: true,
          label: 'Open ${p.name}, $left left, ${sold[p.id] ?? 0} sold',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => onOpen(i),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: PPColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: i == selected ? PPColors.violet : PPColors.line,
                  width: i == selected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        gradient: const LinearGradient(colors: PPColors.badgeGradient),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 22),
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: low ? PPColors.pink : PPColors.bg,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '$left',
                          style: PPType.label(
                            size: 11,
                            color: low ? PPColors.onAccent : PPColors.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PPType.body(size: 12, weight: FontWeight.w800),
                  ),
                  Text(
                    '${Money.format(p.priceCents)} / ${sold[p.id] ?? 0} sold',
                    style: PPType.body(size: 11, color: PPColors.muted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == index ? PPColors.violet : PPColors.raised,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
