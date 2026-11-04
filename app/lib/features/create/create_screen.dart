import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/pp_scaffold.dart';
import '../../connectors/ai/ai_provider.dart';
import '../../data/db/database.dart';
import '../../design/components/sticker.dart';
import '../../design/components/tiles.dart';
import '../../design/tokens.dart';
import '../../domain/enums.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../render/capture.dart';
import '../../render/post_format.dart';
import '../../render/post_template.dart';
import '../../services/entitlements.dart';
import '../../services/haptics_service.dart';

/// The look the vendor picks. Each share destination then exports at its own
/// platform size for that look.
enum PostShape {
  post(PostFormat.instagramPortrait),
  story(PostFormat.story),
  wide(PostFormat.facebookLink);

  const PostShape(this.preview);
  final PostFormat preview;

  String label(AppLocalizations l10n) => switch (this) {
    PostShape.post => l10n.createShapePost,
    PostShape.story => l10n.createShapeStory,
    PostShape.wide => l10n.createShapeWide,
  };

  String noun(AppLocalizations l10n) => switch (this) {
    PostShape.post => l10n.createNounPost,
    PostShape.story => l10n.createNounStory,
    PostShape.wide => l10n.createNounWide,
  };
}

enum ShareTarget {
  png('PNG'),
  instagram('IG'),
  facebook('FB'),
  linkedin('IN'),
  more('...');

  const ShareTarget(this.mark);

  /// Short glyph in the row badge. Brand abbreviations, not translated.
  final String mark;

  String label(AppLocalizations l10n) => switch (this) {
    ShareTarget.png => l10n.createTargetPng,
    ShareTarget.instagram => l10n.createTargetInstagram,
    ShareTarget.facebook => l10n.createTargetFacebook,
    ShareTarget.linkedin => l10n.createTargetLinkedin,
    ShareTarget.more => l10n.createTargetMore,
  };

  PostFormat formatFor(PostShape s) => switch ((this, s)) {
    (_, PostShape.post) => PostFormat.instagramPortrait,
    (_, PostShape.story) => PostFormat.story,
    (ShareTarget.instagram, PostShape.wide) => PostFormat.square,
    (ShareTarget.linkedin, PostShape.wide) => PostFormat.linkedin,
    (_, PostShape.wide) => PostFormat.facebookLink,
  };
}

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final _boundary = GlobalKey();
  final _caption = TextEditingController();
  Product? _product;
  String _query = '';
  PostShape _shape = PostShape.post;

  /// What the RepaintBoundary is currently laid out at. Swapped briefly
  /// during export when a destination needs a different size.
  PostFormat? _renderFormat;
  String? _aiJobId;
  bool _showAi = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(Product p) async {
    final brand = ref.read(brandProvider).valueOrNull;
    final input = {
      'product': p.name,
      'price': Money.format(p.priceCents),
      'booth': brand?.boothLabel,
      'shop': brand?.shopName,
    };
    _caption.text = await const LocalTemplateProvider().run(AiJobKind.caption, input);
    String? jobId;
    if (ref.read(entitlementsProvider).can(Feature.aiCaption)) {
      jobId = await ref.read(jobRunnerProvider).enqueue(AiJobKind.caption, input);
    }
    setState(() {
      _product = p;
      _aiJobId = jobId;
      _showAi = false;
    });
  }

  /// Lays the template out at [f], waits a frame, and captures exactly
  /// f.width pixels wide.
  Future<File> _render(PostFormat f) async {
    setState(() => _renderFormat = f);
    await WidgetsBinding.instance.endOfFrame;
    final bytes = await capturePng(_boundary, targetWidth: f.width);
    setState(() => _renderFormat = null);
    final dir = await getTemporaryDirectory();
    final name =
        '${(_product?.name ?? 'post').replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').toLowerCase()}-${f.sizeLabel}.png';
    return File('${dir.path}/$name').writeAsBytes(bytes, flush: true);
  }

  Future<void> _send(ShareTarget t) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    final f = t.formatFor(_shape);
    final file = await _render(f);
    if (t == ShareTarget.png) {
      try {
        if (!await Gal.hasAccess()) await Gal.requestAccess();
        await Gal.putImage(file.path, album: l10n.appTitle);
        await ref.read(hapticsProvider).play(HapticMoment.success);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.createSavedToPhotos(f.width, f.height))),
        );
      } on GalException {
        await ref.read(hapticsProvider).play(HapticMoment.error);
        messenger.showSnackBar(SnackBar(content: Text(l10n.createSaveFailed)));
      }
      return;
    }
    // TODO(share): Instagram Stories / Facebook direct share intents need a
    // Meta app id; until then every social target opens the system share
    // sheet with the right-size image and caption attached.
    await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], text: _caption.text);
  }

  void _openShare() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(PPSpace.gutter, 0, PPSpace.gutter, PPSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(ctx).createShareShape(_shape.noun(AppLocalizations.of(ctx))),
                style: PPType.title(size: 24),
              ),
              const SizedBox(height: PPSpace.md),
              for (final t in ShareTarget.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: PPSpace.sm),
                  child: _ShareRow(target: t, format: t.formatFor(_shape), onTap: () => _send(t)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(productsProvider).valueOrNull ?? const <Product>[];
    final products = _query.isEmpty
        ? all
        : all.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();
    final brand = ref.watch(brandProvider).valueOrNull;
    final p = _product;
    if (p == null && all.isNotEmpty) {
      // The artboard opens with the first item already chosen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _product == null) _pick(all.first);
      });
    }
    final format = _renderFormat ?? _shape.preview;

    final content = PostContent(
      headline: p == null ? l10n.createPickItem : l10n.createBackSoon(p.name),
      shopName: brand?.shopName ?? l10n.createDefaultShopName,
      priceLabel: p == null ? null : Money.format(p.priceCents),
      handle: brand?.handle,
      boothLabel: brand?.boothLabel,
    );

    return PPScaffold(
      title: l10n.createTitle,
      searchHint: l10n.createSearchHint,
      onSearch: (q) => setState(() => _query = q.trim()),
      onSearchSubmit: (_) {},
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => PPChip(
                label: products[i].name,
                selected: products[i].id == p?.id,
                onTap: () => _pick(products[i]),
              ),
            ),
          ),
          const SizedBox(height: PPSpace.md),
          Expanded(
            child: StickerCard(
              fill: PPColors.surface,
              padding: const EdgeInsets.all(PPSpace.md),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        child: RepaintBoundary(
                          key: _boundary,
                          child: postTemplates.first.build(content, format),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: PPSpace.sm),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: PPColors.bg,
                      borderRadius: BorderRadius.circular(PPRadius.chip),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final s in PostShape.values)
                          Semantics(
                            selected: s == _shape,
                            button: true,
                            child: GestureDetector(
                              onTap: () => setState(() => _shape = s),
                              child: Container(
                                width: 78,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: s == _shape ? PPColors.violet : PPColors.bg,
                                  borderRadius: BorderRadius.circular(PPRadius.chip),
                                ),
                                child: Text(
                                  s.label(l10n),
                                  style: PPType.body(
                                    size: 13,
                                    weight: FontWeight.w800,
                                    color: s == _shape ? PPColors.onAccent : PPColors.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PPSpace.md),
          StickerCard(
            radius: 16,
            padding: const EdgeInsets.fromLTRB(PPSpace.md, 10, PPSpace.md, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.createCaptionLabel,
                        style: PPType.label(size: 10, color: PPColors.muted),
                      ),
                    ),
                    if (_aiJobId != null)
                      GestureDetector(
                        onTap: () => setState(() => _showAi = !_showAi),
                        child: Text(
                          _showAi ? l10n.createUseMine : l10n.createAiVersion,
                          style: PPType.label(size: 10, color: PPColors.violet),
                        ),
                      ),
                  ],
                ),
                if (_showAi && _aiJobId != null)
                  StreamBuilder(
                    stream: ref.watch(jobRunnerProvider).watch(_aiJobId!),
                    builder: (_, snap) {
                      final job = snap.data;
                      if (job?.status != JobStatus.done) return const PendingAi();
                      return SelectableText(job!.result ?? '', style: PPType.body(size: 14));
                    },
                  )
                else
                  TextField(
                    controller: _caption,
                    maxLines: 2,
                    style: PPType.body(size: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: l10n.createCaptionHint,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: PPSpace.md),
          PPButton(
            label: l10n.createShareOrSave,
            icon: Icons.ios_share_rounded,
            height: 56,
            expand: true,
            onPressed: p == null ? null : _openShare,
          ),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.target, required this.format, required this.onTap});

  final ShareTarget target;
  final PostFormat format;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = target == ShareTarget.png;
    final fg = primary ? PPColors.onAccent : PPColors.text;
    final sub = switch (target) {
      ShareTarget.png => l10n.createTargetPngSubtitle(format.width, format.height),
      ShareTarget.more => l10n.createTargetMoreSubtitle,
      _ => l10n.createTargetSizeSubtitle(format.width, format.height),
    };
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: primary ? PPColors.violet : PPColors.card,
            borderRadius: BorderRadius.circular(16),
            border: primary ? null : Border.all(color: PPColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary ? PPColors.text : PPColors.lilac,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(target.mark, style: PPType.label(size: 11, color: PPColors.onAccent)),
              ),
              const SizedBox(width: PPSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.label(l10n),
                      style: PPType.body(size: 15, weight: FontWeight.w800, color: fg),
                    ),
                    Text(
                      sub,
                      style: PPType.body(
                        size: 12,
                        color: primary ? PPColors.onAccent : PPColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
