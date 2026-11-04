import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../tokens.dart';
import 'pup.dart';

/// PUP's mini pass on a short lanyard, as on the Home artboard. Swings
/// gently from its top; holds still when the OS asks for reduced motion.
class SwingingPass extends StatefulWidget {
  const SwingingPass({super.key});

  @override
  State<SwingingPass> createState() => _SwingingPassState();
}

class _SwingingPassState extends State<SwingingPass> with SingleTickerProviderStateMixin {
  late final _swing = AnimationController(vsync: this, duration: const Duration(seconds: 5));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _swing.stop();
    } else if (!_swing.isAnimating) {
      _swing.repeat();
    }
  }

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const ink = Color(0xFF211A35);
    const faint = Color(0xFF615575);
    final pass = SizedBox(
      width: 118,
      child: Column(
        children: [
          Container(
            width: 10,
            height: 36,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [PPColors.violet, PPColors.violet, PPColors.pink, PPColors.pink],
                stops: [0, 0.5, 0.5, 1],
                tileMode: TileMode.repeated,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -2),
            child: Container(
              width: 16,
              height: 12,
              decoration: BoxDecoration(
                border: Border.all(color: PPColors.lilac, width: 3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Container(
            width: 118,
            height: 152,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.5),
                  const Color(0xFFD7CFFF).withValues(alpha: 0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(color: PPColors.violet.withValues(alpha: 0.22), blurRadius: 40),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFAFF), Color(0xFFF0E9FF), Color(0xFFE3F6FF)],
                  stops: [0, 0.48, 1],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.passHeaderLeft, style: PPType.label(size: 5, color: faint)),
                      Text(l10n.passHeaderRight, style: PPType.label(size: 5, color: faint)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFD9CCFF), Color(0xFFF9DFF2), Color(0xFFD4F3FF)],
                          stops: [0, 0.58, 1],
                        ),
                      ),
                      child: const PupMark(size: 66),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.passRole, style: PPType.title(size: 15, color: ink)),
                  const SizedBox(height: 4),
                  Text(
                    l10n.passAccess,
                    style: PPType.label(size: 5, color: const Color(0xFF6D5AA2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _swing,
        builder: (_, child) => Transform.rotate(
          angle: sin(_swing.value * 2 * pi) * 4 * pi / 180,
          alignment: Alignment.topCenter,
          child: child,
        ),
        child: pass,
      ),
    );
  }
}
