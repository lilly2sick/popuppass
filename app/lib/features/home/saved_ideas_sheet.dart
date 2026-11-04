import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/components/sticker.dart';
import '../../design/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';

/// The inspiration board's second half: every card the vendor swiped right
/// on, newest first, with where the idea came from.
Future<void> showSavedIdeas(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => const FractionallySizedBox(heightFactor: 0.8, child: _SavedIdeasSheet()),
);

class _SavedIdeasSheet extends ConsumerWidget {
  const _SavedIdeasSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ideas = ref.watch(savedIdeasProvider).valueOrNull ?? const [];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(PPSpace.gutter, 0, PPSpace.gutter, PPSpace.lg),
        children: [
          Text(l10n.homeSavedIdeas, style: PPType.title(size: 24)),
          const SizedBox(height: PPSpace.md),
          if (ideas.isEmpty)
            EmptyState(title: l10n.savedIdeasEmptyTitle, message: l10n.savedIdeasEmptyMessage),
          for (final t in ideas)
            Padding(
              padding: const EdgeInsets.only(bottom: PPSpace.sm),
              child: StickerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.niche.toUpperCase(), style: PPType.label(color: PPColors.violet)),
                    const SizedBox(height: 4),
                    Text(t.title, style: PPType.heading()),
                    const SizedBox(height: PPSpace.xs),
                    Text(t.why, style: PPType.body(size: 14, color: PPColors.muted)),
                    const SizedBox(height: PPSpace.xs),
                    Text(
                      l10n.savedIdeasSources(t.sources.join(', ')),
                      style: PPType.label(size: 11, color: PPColors.muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
