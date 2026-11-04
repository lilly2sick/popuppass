import 'package:flutter/material.dart';

import '../design/components/event_bar.dart';
import '../design/components/grid_background.dart';
import '../design/tokens.dart';
import '../features/search/search_sheet.dart';

/// The base template every tab uses:
///   0. Grid background (dim so content reads first)
///   1. Event bar (always)
///   2. Page header: eyebrow, title, at most one primary action
///   3. Slim search field directly under the title
///   4. Content built from shared, opaque components
/// The tab bar and PUP's corner button live in AppShell.
class PPScaffold extends StatelessWidget {
  const PPScaffold({
    super.key,
    required this.title,
    required this.body,
    this.eyebrow,
    this.action,
    this.searchHint = 'Search',
    this.onSearch,
    this.onSearchSubmit,
    this.scrollable = true,
  });

  final String title;
  final String? eyebrow;

  /// The single primary action for this page. Keep it to one.
  final Widget? action;
  final Widget body;
  final String searchHint;

  /// Live filter as the user types (e.g. Shop, Sell).
  final ValueChanged<String>? onSearch;

  /// Called on submit; defaults to the app-wide results sheet.
  final ValueChanged<String>? onSearchSubmit;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(PPSpace.gutter, PPSpace.xs, PPSpace.gutter, PPSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) Text(eyebrow!.toUpperCase(), style: PPType.label(color: PPColors.muted)),
                    Text(title, style: PPType.title()),
                  ],
                ),
              ),
              if (action != null) ...[const SizedBox(width: PPSpace.md), action!],
            ],
          ),
          const SizedBox(height: PPSpace.sm),
          PPSearchField(hint: searchHint, onChanged: onSearch, onSubmitted: onSearchSubmit),
        ],
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(PPSpace.gutter, 0, PPSpace.gutter, 96),
      child: body,
    );

    return GridBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const EventBar(),
            header,
            Expanded(child: scrollable ? SingleChildScrollView(child: content) : content),
          ],
        ),
      ),
    );
  }
}

/// Slim rounded search field shown under every page title.
class PPSearchField extends StatelessWidget {
  const PPSearchField({super.key, required this.hint, this.onChanged, this.onSubmitted});

  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        onChanged: onChanged,
        onSubmitted: onSubmitted ?? (q) => showSearchResults(context, q),
        textInputAction: TextInputAction.search,
        style: PPType.body(size: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: PPType.body(size: 14, color: PPColors.muted),
          isDense: true,
          filled: true,
          fillColor: PPColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: PPColors.muted),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(PPRadius.chip), borderSide: const BorderSide(color: PPColors.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(PPRadius.chip), borderSide: const BorderSide(color: PPColors.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(PPRadius.chip), borderSide: const BorderSide(color: PPColors.violet)),
        ),
      ),
    );
  }
}
