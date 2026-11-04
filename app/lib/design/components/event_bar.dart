import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/money.dart';
import '../../features/events/events_sheet.dart';
import '../../providers.dart';
import '../tokens.dart';

/// Mini lanyard pass at the top of every screen. Tap opens the Events sheet.
class EventBar extends ConsumerWidget {
  const EventBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(eventBarProvider);
    final up = s.netTodayCents >= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(PPSpace.gutter, PPSpace.md, PPSpace.gutter, PPSpace.sm),
      child: Semantics(
        button: true,
        label: 'Open events. ${s.eventName}',
        child: GestureDetector(
          onTap: () => showEventsSheet(context),
          child: Container(
            height: 88,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              gradient: PPSurface.iridescentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              decoration: BoxDecoration(
                color: PPColors.surface,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Row(
                children: [
                  // The badge tab with its lanyard slot.
                  Container(
                    width: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: PPColors.badgeGradient,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 14,
                          height: 5,
                          decoration: BoxDecoration(
                            color: PPColors.onAccent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            'PASS',
                            style: PPType.label(size: 8, color: PPColors.onAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: PPSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: s.isLive ? PPColors.teal : PPColors.lilac,
                                borderRadius: BorderRadius.circular(PPRadius.chip),
                              ),
                              child: Text(
                                s.statusLabel.toUpperCase(),
                                style: PPType.label(size: 10, color: PPColors.onAccent),
                              ),
                            ),
                            const SizedBox(width: PPSpace.sm),
                            if (s.boothLabel != null)
                              Flexible(
                                child: Text(
                                  s.boothLabel!.toUpperCase(),
                                  overflow: TextOverflow.ellipsis,
                                  style: PPType.label(size: 10, color: PPColors.muted),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s.eventName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PPType.title(size: 20),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.cloud_outlined, size: 14, color: PPColors.teal),
                            const SizedBox(width: 6),
                            Text(
                              s.connectionLabel,
                              style: PPType.body(size: 12, color: PPColors.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('NET TODAY', style: PPType.label(size: 10, color: PPColors.muted)),
                      Text(
                        Money.signed(s.netTodayCents),
                        style: PPType.number(size: 26, color: up ? PPColors.teal : PPColors.pink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
