import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../tokens.dart';

/// Bottom of Home: the "YOUR POCKET PUP" banner, a pup that wags and blinks,
/// and a pup that walks across. Same frames as the landing page. Freezes on
/// reduced motion.
class AsciiPups extends StatefulWidget {
  const AsciiPups({super.key});

  @override
  State<AsciiPups> createState() => _AsciiPupsState();
}

class _AsciiPupsState extends State<AsciiPups> with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _frame = 0;
  late final _walk = AnimationController(vsync: this, duration: const Duration(seconds: 14));

  static const _font = {
    'C': ['.###', '#...', '#...', '#...', '.###'],
    'E': ['####', '#...', '###.', '#...', '####'],
    'K': ['#..#', '#.#.', '##..', '#.#.', '#..#'],
    'O': ['.##.', '#..#', '#..#', '#..#', '.##.'],
    'P': ['###.', '#..#', '###.', '#...', '#...'],
    'R': ['###.', '#..#', '###.', '#.#.', '#..#'],
    'T': ['####', '.##.', '.##.', '.##.', '.##.'],
    'U': ['#..#', '#..#', '#..#', '#..#', '.##.'],
    'Y': ['#..#', '#..#', '.##.', '.##.', '.##.'],
    ' ': ['..', '..', '..', '..', '..'],
  };
  static const _ramp = '#@%&8\$';
  static final _rows = [
    for (var r = 0; r < 5; r++) 'YOUR POCKET PUP'.split('').map((c) => _font[c]![r]).join('.'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    _timer?.cancel();
    if (still) {
      _walk.stop();
    } else {
      _timer = Timer.periodic(const Duration(milliseconds: 140), (_) => setState(() => _frame++));
      if (!_walk.isAnimating) _walk.repeat();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _walk.dispose();
    super.dispose();
  }

  String get _tagline => [
    for (var y = 0; y < _rows.length; y++)
      [
        for (var x = 0; x < _rows[y].length; x++)
          _rows[y][x] != '#'
              ? ' '
              : _ramp[((sin(x * .45 + y * .7 - _frame * .5) + 1) / 2 * (_ramp.length - 1)).round()],
      ].join(),
  ].join('\n');

  String get _wagPup {
    final eyes = _frame % 32 >= 30 ? '- -' : '0 0';
    final tail = (_frame ~/ 3).isOdd ? '/' : '~';
    return [
      '  /^ ^\\',
      ' / $eyes \\',
      ' V\\ Y /V',
      '  / - \\',
      ' /    |',
      'V__) ||$tail',
    ].join('\n');
  }

  String get _walkPup {
    final step = (_frame ~/ 2).isOdd;
    return [
      '        __',
      '${step ? ' ~' : ' /'}\\___/ o\\_',
      '   |      __>',
      step ? '   /\\   /\\' : '   |\\   |\\',
    ].join('\n');
  }

  TextStyle _mono(double size, Color color) => TextStyle(
    fontFamily: 'monospace',
    fontSize: size,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: color,
  );

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        children: [
          FittedBox(child: Text(_tagline, style: _mono(7, PPColors.violet))),
          const SizedBox(height: PPSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_wagPup, style: _mono(12, PPColors.pink)),
              const SizedBox(width: PPSpace.lg),
              SizedBox(
                width: 150,
                child: Text(
                  'Free mode keeps your data on this phone. We never sell your sales data.',
                  style: PPType.body(size: 12, color: PPColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: PPSpace.md),
          LayoutBuilder(
            builder: (_, c) => SizedBox(
              height: 64,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _walk,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(-110 + _walk.value * (c.maxWidth + 110), 0),
                    child: child,
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(_walkPup, style: _mono(12, PPColors.teal)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
