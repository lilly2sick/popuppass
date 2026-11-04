import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../connectors/events/ics_codec.dart';
import '../../data/db/database.dart';
import '../../design/components/sticker.dart';
import '../../design/tokens.dart';
import '../../providers.dart';

Future<void> showEventsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FractionallySizedBox(heightFactor: 0.9, child: _EventsSheet()),
    );

class _EventsSheet extends ConsumerWidget {
  const _EventsSheet();

  Future<void> _importIcs(WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['ics'], withData: true);
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return;
    final ics = ref.read(icsConnectorProvider)..pendingText = utf8.decode(bytes);
    await ics.ingest();
  }

  Future<void> _exportIcs(List<ShopEvent> events) async {
    final dir = await getTemporaryDirectory();
    final file = await File('${dir.path}/popup-pass-events.ics').writeAsString(const IcsCodec().write(events));
    await Share.shareXFiles([XFile(file.path, mimeType: 'text/calendar')]);
  }

  Future<void> _newEvent(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (range == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Event name'),
        content: TextField(controller: name, autofocus: true),
        actions: [TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    await ref.read(eventRepoProvider).save(EventsCompanion.insert(
          name: name.text.trim(),
          startsAt: range.start,
          endsAt: range.end.add(const Duration(hours: 23, minutes: 59)),
        ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).valueOrNull ?? const [];
    final current = ref.watch(currentEventProvider).valueOrNull;
    final cons = ref.watch(conSourceProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(PPSpace.gutter, 0, PPSpace.gutter, PPSpace.xl),
      children: [
        Row(
          children: [
            Expanded(child: Text('Your events', style: PPType.title())),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
          ],
        ),
        const SizedBox(height: PPSpace.md),
        for (final e in events.reversed) ...[_EventRow(event: e, live: e.id == current?.id), const SizedBox(height: 10)],
        const SizedBox(height: PPSpace.md),
        Row(
          children: [
            Expanded(child: Text('Cons near you', style: PPType.heading())),
            Text(cons.attribution.toUpperCase(), style: PPType.label(size: 10, color: PPColors.muted)),
          ],
        ),
        const SizedBox(height: PPSpace.sm),
        FutureBuilder(
          future: cons.upcoming(),
          builder: (_, snap) => Column(
            children: [
              for (final c in snap.data ?? const <EventsCompanion>[])
                Padding(
                  padding: const EdgeInsets.only(bottom: PPSpace.sm),
                  child: StickerCard(
                    shadow: false,
                    radius: 16,
                    padding: const EdgeInsets.fromLTRB(PPSpace.md, PPSpace.sm, PPSpace.sm, PPSpace.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name.value, style: PPType.body(size: 15, weight: FontWeight.w700)),
                              Text(DateFormat('MMM d').format(c.startsAt.value), style: PPType.body(size: 12, color: PPColors.muted)),
                            ],
                          ),
                        ),
                        PPButton.secondary(
                          label: 'Add',
                          onPressed: () => ref.read(eventRepoProvider).importAll([c]),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text('Distance is worked out on your phone. Your location is never sent anywhere.', style: PPType.body(size: 12, color: PPColors.muted)),
        const SizedBox(height: PPSpace.lg),
        Row(
          children: [
            Expanded(child: PPButton(label: 'New event', onPressed: () => _newEvent(context, ref))),
            const SizedBox(width: PPSpace.sm),
            Expanded(child: PPButton.secondary(label: 'Import .ics', onPressed: () => _importIcs(ref))),
            const SizedBox(width: PPSpace.sm),
            Expanded(child: PPButton.secondary(label: 'Export', onPressed: () => _exportIcs(events))),
          ],
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.live});

  final ShopEvent event;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final fg = PPColors.text;
    final sub = live ? PPColors.muted : PPColors.muted;
    final sameDay = event.startsAt.day == event.endsAt.day && event.startsAt.month == event.endsAt.month;
    return StickerCard(
      fill: live ? PPColors.surface : PPColors.card,
      iridescent: live,
      radius: PPRadius.tile,
      padding: const EdgeInsets.symmetric(horizontal: PPSpace.md, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(14)), gradient: LinearGradient(colors: PPColors.badgeGradient)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('MMM').format(event.startsAt).toUpperCase(), style: PPType.label(size: 10, color: PPColors.onAccent)),
                Text(
                  sameDay ? '${event.startsAt.day}' : '${event.startsAt.day}-${event.endsAt.day}',
                  style: PPType.number(size: 18, color: PPColors.onAccent),
                ),
              ],
            ),
          ),
          const SizedBox(width: PPSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name, style: PPType.body(weight: FontWeight.w700, color: fg)),
                if (event.boothLabel != null) Text(event.boothLabel!, style: PPType.body(size: 12, color: sub)),
              ],
            ),
          ),
          if (live) Text('LIVE', style: PPType.label(color: sub)),
        ],
      ),
    );
  }
}
