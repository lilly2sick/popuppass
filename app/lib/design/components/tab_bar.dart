import 'package:flutter/material.dart';

import '../tokens.dart';

class PPTabBar extends StatelessWidget {
  const PPTabBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    (Icons.home_outlined, 'Home'),
    (Icons.sell_outlined, 'Shop'),
    (Icons.add_rounded, 'Sell'),
    (Icons.photo_outlined, 'Create'),
    (Icons.bar_chart_rounded, 'Insights'),
  ];

  static const _sellIndex = 2;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PPColors.surface,
        border: Border(top: BorderSide(color: PPColors.lineStrong)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(child: i == _sellIndex ? _sellBadge(i) : _tab(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int i) {
    final active = i == currentIndex;
    final color = active ? PPColors.violet : PPColors.muted;
    return Semantics(
      button: true,
      selected: active,
      label: _tabs[i].$2,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => onTap(i),
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_tabs[i].$1, color: color),
              const SizedBox(height: 4),
              Text(
                _tabs[i].$2,
                style: PPType.body(
                  size: 12,
                  color: color,
                  weight: active ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sellBadge(int i) {
    final active = i == currentIndex;
    final fill = active ? PPColors.violet : PPColors.pink;
    return Semantics(
      button: true,
      selected: active,
      label: 'Sell',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => onTap(i),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(PPRadius.card),
                boxShadow: [BoxShadow(color: fill.withValues(alpha: 0.45), blurRadius: 24)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: PPColors.onAccent),
                  Text('Sell', style: PPType.title(size: 13, color: PPColors.onAccent)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
