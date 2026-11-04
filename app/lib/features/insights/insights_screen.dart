import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/pp_scaffold.dart';
import '../../design/components/sticker.dart';
import '../../design/components/stats.dart';
import '../../design/tokens.dart';
import '../../domain/analytics_service.dart';
import '../../domain/enums.dart';
import '../../domain/money.dart';
import '../../domain/summary_writer.dart';
import '../../export/export_service.dart';
import '../../export/exporter.dart';
import '../../providers.dart';

final _reportProvider = FutureProvider.autoDispose<EventReport>((ref) async {
  ref.watch(todayStatsProvider); // recompute whenever sales change
  final event = ref.watch(currentEventProvider).valueOrNull;
  final products = ref.watch(productsProvider).valueOrNull;
  final names = <String, String>{for (final p in products ?? []) p.id: p.name};
  return ref.watch(analyticsProvider).report(event: event, names: names);
});

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref, EventReport r) async {
    final svc = ref.read(exportServiceProvider);
    final event = ref.read(currentEventProvider).valueOrNull;
    final format = await showModalBottomSheet<ExportFormat>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in ExportFormat.values)
              ListTile(
                minTileHeight: PPTap.min,
                title: Text(f.label, style: PPType.body(weight: FontWeight.w700)),
                trailing: svc.allowed(f)
                    ? null
                    : Text('PRO', style: PPType.label(color: PPColors.violet)),
                onTap: () => Navigator.pop(context, f),
              ),
          ],
        ),
      ),
    );
    if (format == null || format == ExportFormat.png) return; // PNG: long-press any card (TODO)
    final rows = await ref.read(salesRepoProvider).linesFor(eventId: event?.id);
    try {
      await svc.share(
        format,
        ExportRequest(
          title: '${event?.name ?? 'All sales'} report',
          report: r,
          salesRows: [
            ['Sold at', 'Item', 'Qty', 'Unit price', 'Unit cost', 'Paid with', 'Source'],
            for (final (s, l) in rows)
              [
                s.soldAt,
                l.externalName ?? l.productId,
                l.qty,
                l.unitPriceCents / 100,
                l.unitCostCents / 100,
                s.paymentMethod.label,
                s.source.name,
              ],
          ],
        ),
      );
    } on ExportLocked {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF and Excel exports are part of Pro.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(_reportProvider).valueOrNull;
    final event = ref.watch(currentEventProvider).valueOrNull;

    return PPScaffold(
      title: 'Look what you did.',
      action: PPButton(
        label: 'Export',
        onPressed: report == null ? null : () => _export(context, ref, report),
      ),
      body: report == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoneyDelta(
                  cents: report.netCents,
                  eyebrow: 'Net profit',
                  large: true,
                  caption:
                      '${Money.format(report.grossCents)} gross, ${Money.format(report.costCents)} cost, '
                      '${Money.format(report.boothFeeCents)} booth. ${report.units} sold.',
                ),
                const SizedBox(height: PPSpace.md),
                _PerItem(report: report),
                const SizedBox(height: PPSpace.md),
                _PaidWith(report: report),
                const SizedBox(height: PPSpace.md),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PPColors.surface,
                    border: Border.all(color: PPColors.violet.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(PPRadius.tile),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR RECAP', style: PPType.label(color: PPColors.lilac)),
                      const SizedBox(height: 6),
                      Text(
                        const RuleSummaryWriter().write(
                          report,
                          eventName: event?.name ?? 'this event',
                        ),
                        style: PPType.body(size: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _PerItem extends StatelessWidget {
  const _PerItem({required this.report});

  final EventReport report;

  @override
  Widget build(BuildContext context) {
    final rows = report.ranked;
    final max = rows.fold<int>(1, (m, p) => p.profitCents.abs() > m ? p.profitCents.abs() : m);
    return StickerCard(
      shadow: false,
      radius: PPRadius.tile,
      padding: const EdgeInsets.all(PPSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Profit by item', style: PPType.body(weight: FontWeight.w700)),
          const SizedBox(height: PPSpace.sm),
          for (final p in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PPType.body(size: 13, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: PPSpace.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p.profitCents.abs() / max,
                        minHeight: 14,
                        backgroundColor: PPColors.bg,
                        color: p.profitCents < 0 ? PPColors.pink : PPColors.violet,
                      ),
                    ),
                  ),
                  const SizedBox(width: PPSpace.sm),
                  Text(
                    '${p.units} / ${Money.signed(p.profitCents)}',
                    style: PPType.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: p.profitCents < 0 ? PPColors.pink : PPColors.text,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PaidWith extends StatelessWidget {
  const _PaidWith({required this.report});

  final EventReport report;

  // Told apart by lightness as well as hue.
  static const _colors = [
    PPColors.text,
    PPColors.violet,
    PPColors.pink,
    PPColors.pink,
    PPColors.muted,
    PPColors.violetSoft,
    PPColors.line,
  ];

  @override
  Widget build(BuildContext context) {
    final entries = report.byMethod.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (a, e) => a + e.value);
    if (total == 0) return const SizedBox.shrink();
    Color color(PaymentMethod m) => _colors[entries.indexWhere((e) => e.key == m) % _colors.length];
    return StickerCard(
      shadow: false,
      radius: PPRadius.tile,
      padding: const EdgeInsets.all(PPSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How they paid', style: PPType.body(weight: FontWeight.w700)),
          const SizedBox(height: PPSpace.sm),
          Container(
            height: 16,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: PPColors.text, width: 2),
            ),
            child: Row(
              children: [
                for (final e in entries)
                  Expanded(
                    flex: e.value,
                    child: ColoredBox(color: color(e.key)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: PPSpace.sm),
          Wrap(
            spacing: 14,
            children: [
              for (final e in entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, color: color(e.key)),
                    const SizedBox(width: 6),
                    Text('${e.key.label} ${Money.format(e.value)}', style: PPType.body(size: 12)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
