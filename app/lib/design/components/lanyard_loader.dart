import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../tokens.dart';
import 'grid_background.dart';
import 'pup.dart';

/// Startup screen: PUP's pass swinging on its lanyard while the database
/// opens and the sample shop loads.
class LanyardLoader extends StatefulWidget {
  const LanyardLoader({super.key, this.hasError = false});

  final bool hasError;

  @override
  State<LanyardLoader> createState() => _LanyardLoaderState();
}

class _LanyardLoaderState extends State<LanyardLoader> with TickerProviderStateMixin {
  late final _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      _swing.stop();
      _dots.stop();
    } else {
      if (!_swing.isAnimating) _swing.repeat();
      if (!_dots.isAnimating) _dots.repeat();
    }
  }

  @override
  void dispose() {
    _swing.dispose();
    _dots.dispose();
    super.dispose();
  }

  Widget _dot(Color color, double delay) => AnimatedBuilder(
    animation: _dots,
    builder: (_, __) {
      final t = _reducedMotion ? 1.0 : (_dots.value + delay) % 1.0;
      final opacity = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * 2 * pi));
      return Opacity(
        opacity: opacity,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      );
    },
  );

  Widget _strap(List<Color> colors, double skew) => Transform(
    transform: Matrix4.skewX(skew),
    child: Container(
      width: 22,
      height: 230,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [for (var i = 0; i < 12; i++) colors[i % 2]],
          stops: [for (var i = 0; i < 12; i++) (i ~/ 2 * 2 + (i.isOdd ? 2 : 0)) / 12],
          tileMode: TileMode.repeated,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final badge = Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _strap(const [PPColors.violet, PPColors.pink], 0.14),
            const SizedBox(width: 46),
            _strap(const [PPColors.pink, PPColors.violet], -0.14),
          ],
        ),
        Container(
          width: 30,
          height: 24,
          decoration: BoxDecoration(
            border: Border.all(color: PPColors.lilac, width: 4),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Container(
          width: 14,
          height: 18,
          decoration: BoxDecoration(color: PPColors.muted, borderRadius: BorderRadius.circular(4)),
        ),
        Container(
          width: 200,
          height: 252,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFAFF), Color(0xFFF0E9FF), Color(0xFFE3F6FF)],
            ),
            boxShadow: [BoxShadow(color: PPColors.violet.withValues(alpha: 0.25), blurRadius: 60)],
          ),
          child: Column(
            children: [
              Text(
                'POP UP PASS  /  NO. 1',
                style: PPType.label(size: 8, color: const Color(0xFF615575)),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(colors: PPColors.badgeGradient),
                  ),
                  child: const PupMark(size: 112),
                ),
              ),
              const SizedBox(height: 6),
              Text('PUP', style: PPType.title(size: 26, color: const Color(0xFF211A35))),
              const SizedBox(height: 5),
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0x4D544575))),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.passRole,
                        style: PPType.label(size: 7, color: const Color(0xFF776D8A)),
                      ),
                      Text(
                        l10n.passAccess,
                        style: PPType.label(size: 7, color: const Color(0xFF776D8A)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      body: GridBackground(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _swing,
                builder: (_, child) => Transform.rotate(
                  angle: sin(_swing.value * 2 * pi) * 9 * pi / 180,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
                child: badge,
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 120,
              child: Column(
                children: [
                  Text(l10n.appTitle, style: PPType.title(size: 30)),
                  const SizedBox(height: PPSpace.sm),
                  if (widget.hasError)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.loaderError,
                        textAlign: TextAlign.center,
                        style: PPType.body(size: 14, color: PPColors.pink),
                      ),
                    )
                  else
                    Semantics(
                      liveRegion: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.loaderSettingUp,
                            style: PPType.body(size: 14, color: PPColors.muted),
                          ),
                          const SizedBox(width: 6),
                          _dot(PPColors.violet, 0),
                          const SizedBox(width: 4),
                          _dot(PPColors.pink, 0.2),
                          const SizedBox(width: 4),
                          _dot(PPColors.teal, 0.4),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
