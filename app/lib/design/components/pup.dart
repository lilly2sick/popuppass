import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../tokens.dart';
import 'sticker.dart';

class PupMark extends StatelessWidget {
  const PupMark({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/pup.svg',
    width: size,
    height: size * 188 / 220,
    semanticsLabel: 'PUP',
  );
}

List<(String, String)> _faqs(AppLocalizations l) => [
  (l.pupFaqOfflineQ, l.pupFaqOfflineA),
  (l.pupFaqDoubleTapQ, l.pupFaqDoubleTapA),
  (l.pupFaqAddEventQ, l.pupFaqAddEventA),
  (l.pupFaqDataQ, l.pupFaqDataA),
  (l.pupFaqProQ, l.pupFaqProA),
];

/// PUP's greeting and FAQs. Shown once on first launch, then from the corner.
Future<void> showPupSheet(BuildContext context, {bool greeting = false}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(PPSpace.gutter, 0, PPSpace.gutter, PPSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(colors: PPColors.badgeGradient),
                    ),
                    child: const PupMark(size: 74),
                  ),
                  const SizedBox(width: PPSpace.md),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(PPSpace.md),
                      decoration: const BoxDecoration(
                        color: PPColors.text,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting
                                ? AppLocalizations.of(sheetContext).pupGreetingTitle
                                : AppLocalizations.of(sheetContext).pupNeedHand,
                            style: PPType.title(size: 20, color: PPColors.onAccent),
                          ),
                          Text(
                            AppLocalizations.of(sheetContext).pupCornerHint,
                            style: PPType.body(size: 13, color: PPColors.onAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PPSpace.md),
              for (final (q, a) in _faqs(AppLocalizations.of(sheetContext)))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: StickerCard(
                    radius: 14,
                    padding: EdgeInsets.zero,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Text(q, style: PPType.body(size: 14, weight: FontWeight.w800)),
                          iconColor: PPColors.violet,
                          collapsedIconColor: PPColors.violet,
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          children: [Text(a, style: PPType.body(size: 13, color: PPColors.muted))],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: PPSpace.sm),
              Builder(
                builder: (ctx) => PPButton(
                  label: AppLocalizations.of(ctx).pupLetsGo,
                  onPressed: () => Navigator.pop(ctx),
                  expand: true,
                  height: 52,
                ),
              ),
            ],
          ),
        ),
      ),
    );

/// Floating corner button. On first launch it opens the greeting by itself.
class PupCornerButton extends ConsumerStatefulWidget {
  const PupCornerButton({super.key});

  @override
  ConsumerState<PupCornerButton> createState() => _PupCornerButtonState();
}

class _PupCornerButtonState extends ConsumerState<PupCornerButton> {
  static const _seenKey = 'pup_intro_seen';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final storage = ref.read(secureStorageProvider);
      if (await storage.read(key: _seenKey) != null || !mounted) return;
      await storage.write(key: _seenKey, value: '1');
      if (mounted) await showPupSheet(context, greeting: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).pupAskPup,
      child: GestureDetector(
        onTap: () => showPupSheet(context),
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PPColors.card,
            border: Border.all(color: PPColors.lilac, width: 2),
            boxShadow: [BoxShadow(color: PPColors.violet.withValues(alpha: 0.45), blurRadius: 22)],
          ),
          child: const PupMark(size: 42),
        ),
      ),
    );
  }
}
