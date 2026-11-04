import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/components/sticker.dart';
import '../../design/tokens.dart';
import '../../domain/enums.dart';
import '../../domain/recommendation_schedule.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';

/// "Weekly at 9:00 AM", for Settings and the Home header.
String recommendationSummary(
  BuildContext context,
  AppLocalizations l10n,
  RecommendationSchedule s,
) {
  final frequency = s.frequency.localized(l10n);
  if (!s.enabled) return frequency;
  final time = TimeOfDay(hour: s.hour, minute: s.minute).format(context);
  return l10n.recommendationSummary(frequency, time);
}

/// SPEC 16 controls: off / daily / weekly / every two weeks plus time of day.
/// Opened from Settings and from Home's "Room to experiment" header.
Future<void> showRecommendationSchedule(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => const _ScheduleSheet(),
);

class _ScheduleSheet extends ConsumerWidget {
  const _ScheduleSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final schedule = ref.watch(recommendationScheduleProvider).valueOrNull;
    final controller = ref.read(recommendationScheduleProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(PPSpace.gutter, 0, PPSpace.gutter, PPSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.recommendationTitle, style: PPType.title(size: 24)),
            const SizedBox(height: PPSpace.xs),
            Text(l10n.recommendationExplain, style: PPType.body(size: 14, color: PPColors.muted)),
            if (schedule != null) ...[
              const SizedBox(height: PPSpace.md),
              Text(l10n.recommendationHowOften.toUpperCase(), style: PPType.label()),
              const SizedBox(height: PPSpace.xs),
              Wrap(
                spacing: PPSpace.sm,
                runSpacing: PPSpace.sm,
                children: [
                  for (final f in RecommendationFrequency.values)
                    PPChip(
                      label: f.localized(l10n),
                      selected: f == schedule.frequency,
                      onTap: () => controller.choose(frequency: f),
                    ),
                ],
              ),
              const SizedBox(height: PPSpace.md),
              Text(l10n.recommendationTimeOfDay.toUpperCase(), style: PPType.label()),
              const SizedBox(height: PPSpace.xs),
              PPButton.secondary(
                label: TimeOfDay(hour: schedule.hour, minute: schedule.minute).format(context),
                icon: Icons.schedule_rounded,
                expand: true,
                onPressed: schedule.enabled
                    ? () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: schedule.hour, minute: schedule.minute),
                        );
                        if (picked != null) {
                          await controller.choose(hour: picked.hour, minute: picked.minute);
                        }
                      }
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
