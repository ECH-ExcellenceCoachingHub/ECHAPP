import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../services/infrastructure/api_client.dart';

/// One row in the suggestion list.
class SearchSuggestion {
  const SearchSuggestion({required this.id, required this.title, this.subtitle, this.thumbnail, this.icon = Icons.play_lesson_outlined, this.data});
  final String id;
  final String title;
  final String? subtitle;
  final String? thumbnail;
  final IconData icon;
  /// The original item (a course map, a Course…), for the caller.
  final Object? data;
}

typedef SuggestionLoader = Future<List<SearchSuggestion>> Function(String query);

/// Shows suggestions under an existing search [child] (a TextField using
/// [controller]) while the user types, so a few letters are enough:
/// "bio" → "Biology S3", "Biology for beginners"…
///
/// Wrap the field, do not replace it: the screen keeps its own look,
/// `onChanged` and `onSubmitted`.
class SearchSuggestions extends StatefulWidget {
  const SearchSuggestions({
    super.key,
    required this.controller,
    required this.load,
    required this.onSelected,
    required this.child,
    this.onSearchAll,
    this.minChars = 1,
    this.maxHeight = 380,
    this.fillOnSelect = false,
    this.noMatchText = 'No course matches',
  });

  final TextEditingController controller;
  final SuggestionLoader load;
  final void Function(SearchSuggestion s) onSelected;
  /// "See all results for …" at the bottom of the list.
  final void Function(String query)? onSearchAll;
  final Widget child;
  final int minChars;
  final double maxHeight;
  /// Put the chosen title in the field (for filters), instead of leaving it.
  final bool fillOnSelect;
  final String noMatchText;

  @override
  State<SearchSuggestions> createState() => _SearchSuggestionsState();
}

class _SearchSuggestionsState extends State<SearchSuggestions> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  Timer? _debounce;
  Timer? _hideTimer;
  int _request = 0;
  List<SearchSuggestion> _items = const [];
  bool _loading = false;
  bool _searched = false;
  bool _focused = false;
  bool _ignoreNextChange = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(SearchSuggestions old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _debounce?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onText() {
    final q = widget.controller.text.trim();
    if (q == _query) return;
    _query = q;
    if (_ignoreNextChange) {
      _ignoreNextChange = false;
      return;
    }
    _debounce?.cancel();
    if (q.length < widget.minChars) {
      _request++;
      setState(() {
        _items = const [];
        _loading = false;
        _searched = false;
      });
      _sync();
      return;
    }
    setState(() => _loading = true);
    _sync();
    _debounce = Timer(const Duration(milliseconds: 220), () => _fetch(q));
  }

  Future<void> _fetch(String q) async {
    final id = ++_request;
    try {
      final items = await widget.load(q);
      if (!mounted || id != _request) return;
      setState(() {
        _items = items;
        _loading = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted || id != _request) return;
      setState(() {
        _items = const [];
        _loading = false;
        _searched = true;
      });
    }
    _sync();
  }

  void _sync() {
    final show = _focused && _query.length >= widget.minChars && (_loading || _searched);
    if (show && !_portal.isShowing) _portal.show();
    if (!show && _portal.isShowing) _portal.hide();
  }

  void _onFocus(bool focused) {
    _hideTimer?.cancel();
    if (focused) {
      _focused = true;
      _sync();
    } else {
      // Small delay so a tap on a suggestion still lands.
      _hideTimer = Timer(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        _focused = false;
        _sync();
      });
    }
  }

  void _choose(SearchSuggestion s) {
    if (widget.fillOnSelect) {
      _ignoreNextChange = true;
      widget.controller.text = s.title;
      widget.controller.selection = TextSelection.collapsed(offset: s.title.length);
    }
    _focused = false;
    _sync();
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSelected(s);
  }

  void _searchAll() {
    final q = widget.controller.text.trim();
    _focused = false;
    _sync();
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSearchAll?.call(q);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _onFocus,
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(controller: _portal, overlayChildBuilder: _overlay, child: widget.child),
      ),
    );
  }

  Widget _overlay(BuildContext overlayContext) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const SizedBox.shrink();
    final mq = MediaQuery.of(overlayContext);
    final top = box.localToGlobal(Offset.zero).dy + box.size.height + 6;
    final room = mq.size.height - mq.viewInsets.bottom - top - 12;
    final maxH = room.clamp(120.0, widget.maxHeight);
    final muted = AppTheme.getSecondaryTextColor(context);

    final rows = <Widget>[
      if (_loading && _items.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: LinearProgressIndicator(minHeight: 2))
      else if (_items.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(children: [
            Icon(Icons.search_off_rounded, size: 20, color: muted),
            const SizedBox(width: 10),
            Expanded(child: Text('${widget.noMatchText} "$_query"', style: TextStyle(color: muted))),
          ]),
        ),
      for (final s in _items) _SuggestionRow(s: s, query: _query, onTap: () => _choose(s)),
      if (widget.onSearchAll != null && _items.isNotEmpty) ...[
        Divider(height: 1, color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
        InkWell(
          onTap: _searchAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 20, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('See all results for "$_query"', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ],
    ];

    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        offset: const Offset(0, 6),
        child: SizedBox(
          width: box.size.width,
          // Taps here count as taps on the text field: it keeps focus.
          child: TextFieldTapRegion(
            child: Material(
              elevation: 10,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: ListView(padding: const EdgeInsets.symmetric(vertical: 6), shrinkWrap: true, children: rows),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.s, required this.query, required this.onTap});
  final SearchSuggestion s;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppTheme.getTextColor(context);
    final muted = AppTheme.getSecondaryTextColor(context);
    final placeholder = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Icon(s.icon, size: 22, color: AppTheme.primary),
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          if (s.thumbnail != null && s.thumbnail!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(s.thumbnail!, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
            )
          else
            placeholder,
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(
                TextSpan(children: highlightMatches(s.title, query, TextStyle(color: text, fontSize: 14.5), TextStyle(color: text, fontSize: 14.5, fontWeight: FontWeight.w800))),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (s.subtitle != null && s.subtitle!.isNotEmpty)
                Text(s.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: muted)),
            ]),
          ),
          Icon(Icons.north_west_rounded, size: 16, color: muted),
        ]),
      ),
    );
  }
}

String _fold(String s) {
  const from = 'àáâäãåèéêëìíîïòóôöõùúûüçñ';
  const to = 'aaaaaaeeeeiiiiooooouuuucn';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

List<String> _words(String q) => _fold(q).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(6).toList();

/// Bold every part of [text] that matches a word of [query].
List<TextSpan> highlightMatches(String text, String query, TextStyle normal, TextStyle bold) {
  final words = _words(query);
  if (words.isEmpty) return [TextSpan(text: text, style: normal)];
  final folded = _fold(text);
  final mark = List<bool>.filled(text.length, false);
  for (final w in words) {
    var from = 0;
    while (true) {
      final i = folded.indexOf(w, from);
      if (i < 0) break;
      for (var k = i; k < i + w.length && k < mark.length; k++) {
        mark[k] = true;
      }
      from = i + w.length;
    }
  }
  final spans = <TextSpan>[];
  var start = 0;
  for (var i = 1; i <= text.length; i++) {
    if (i == text.length || mark[i] != mark[start]) {
      spans.add(TextSpan(text: text.substring(start, i), style: mark[start] ? bold : normal));
      start = i;
    }
  }
  return spans;
}

/// How well [title] (+ [extra]) matches [query]; 0 = not at all. Every query
/// word must match. Same rules as the backend `/courses/suggest`.
int searchRelevance(String query, String title, [String extra = '']) {
  final words = _words(query);
  if (words.isEmpty) return 0;
  final t = _fold(title);
  final e = _fold(extra);
  final titleWords = t.split(RegExp(r'[^a-z0-9]+')).where((w) => w.isNotEmpty);
  var score = 0;
  for (final w in words) {
    if (titleWords.any((tw) => tw.startsWith(w))) {
      score += 3;
    } else if (t.contains(w)) {
      score += 2;
    } else if (e.contains(w)) {
      score += 1;
    } else {
      return 0;
    }
  }
  if (t.startsWith(words.join(' '))) score += 4;
  return score;
}

/// Best matches of a list already in memory, for [SearchSuggestions.load].
List<T> rankByQuery<T>(Iterable<T> items, String query, String Function(T) title, {String Function(T)? extra, int limit = 8}) {
  final scored = <(T, int)>[];
  for (final it in items) {
    final s = searchRelevance(query, title(it), extra?.call(it) ?? '');
    if (s > 0) scored.add((it, s));
  }
  scored.sort((a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : title(a.$1).toLowerCase().compareTo(title(b.$1).toLowerCase()));
  return scored.take(limit).map((e) => e.$1).toList();
}

/// Course suggestions from the backend (`GET /courses/suggest`).
class CourseSuggestionsApi {
  static final _api = ApiClient();

  static Future<List<SearchSuggestion>> load(String query, {bool showUnpublished = false, int limit = 8}) async {
    final res = await _api.get('${ApiConfig.courses}/suggest', queryParams: {
      'q': query,
      'limit': limit,
      if (showUnpublished) 'showUnpublished': 'true',
    });
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    final data = body is Map ? body['data'] : null;
    final raw = data is Map ? data['suggestions'] : null;
    final list = raw is List ? raw : const [];
    return [
      for (final raw in list)
        if (raw is Map)
          SearchSuggestion(
            id: '${raw['id']}',
            title: '${raw['title'] ?? ''}',
            thumbnail: raw['thumbnail'] as String?,
            subtitle: [
              if (raw['category'] != null) '${raw['category']}',
              if (raw['level'] != null) _cap('${raw['level']}'),
              if (raw['instructorName'] != null && '${raw['instructorName']}'.isNotEmpty) '${raw['instructorName']}',
              if (raw['isPublished'] == false) 'Draft',
            ].join(' · '),
            data: raw,
          ),
    ];
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
