import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_course_provider.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

const _languages = <String, String>{
  'en': 'English',
  'rw': 'Kinyarwanda',
  'fr': 'French',
  'sw': 'Swahili',
};

const _defaultCategories = <String>[
  'Nursery',
  'Primary',
  'O-Level',
  'A-Level',
  'TVET',
  'University',
  'Professional',
  'General',
];

const _sortOptions = <String, String>{
  'newest': 'Newest first',
  'oldest': 'Oldest first',
  'updated': 'Recently updated',
  'title': 'Title (A–Z)',
  'author': 'Author (A–Z)',
  'downloads': 'Most opened',
};

class _BooksApi {
  static Future<Map<String, String>> headers({bool json = true}) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('You are signed out. Please sign in again.');
    final token = await user.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  static Map<String, dynamic> _decode(http.Response r) {
    Map<String, dynamic> data;
    try {
      data = json.decode(r.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Server error (${r.statusCode})');
    }
    if (r.statusCode >= 200 && r.statusCode < 300 && data['success'] == true) {
      return data;
    }
    throw Exception(data['message'] ?? 'Request failed (${r.statusCode})');
  }

  static Future<Map<String, dynamic>> list(Map<String, String> params) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/books/admin/all').replace(queryParameters: params);
    final r = await http.get(uri, headers: await headers());
    return _decode(r)['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getOne(String id) async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/books/admin/$id'), headers: await headers());
    return Map<String, dynamic>.from(_decode(r)['data'] as Map);
  }

  static Future<void> create(Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('${ApiConfig.baseUrl}/books'),
        headers: await headers(), body: json.encode(body));
    _decode(r);
  }

  static Future<void> update(String id, Map<String, dynamic> body) async {
    final r = await http.put(Uri.parse('${ApiConfig.baseUrl}/books/$id'),
        headers: await headers(), body: json.encode(body));
    _decode(r);
  }

  static Future<void> delete(String id) async {
    final r = await http.delete(Uri.parse('${ApiConfig.baseUrl}/books/$id'), headers: await headers());
    _decode(r);
  }

  static Future<Map<String, dynamic>> bulk(List<String> ids, String action) async {
    final r = await http.post(Uri.parse('${ApiConfig.baseUrl}/books/admin/bulk'),
        headers: await headers(), body: json.encode({'ids': ids, 'action': action}));
    return _decode(r);
  }

  /// Uploads a PDF and/or cover. Returns the server's file metadata.
  static Future<Map<String, dynamic>> uploadFiles({PlatformFile? pdf, PlatformFile? cover}) async {
    final req = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/books/upload-files'));
    req.headers.addAll(await headers(json: false));
    if (pdf != null && pdf.bytes != null) {
      req.files.add(http.MultipartFile.fromBytes('pdf', pdf.bytes!,
          filename: pdf.name, contentType: MediaType('application', 'pdf')));
    }
    if (cover != null && cover.bytes != null) {
      req.files.add(http.MultipartFile.fromBytes('cover', cover.bytes!,
          filename: cover.name, contentType: _imageType(cover.name)));
    }
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(_decode(r)['data'] as Map);
  }

  static MediaType _imageType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}

String _formatBytes(num? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB'];
  double v = bytes.toDouble();
  int i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(v >= 10 || i == 0 ? 0 : 1)} ${units[i]}';
}

String _formatDate(dynamic iso) {
  if (iso == null) return '—';
  final d = DateTime.tryParse(iso.toString())?.toLocal();
  if (d == null) return '—';
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// Related courses come back populated ({_id, title}) from the admin API,
/// but older payloads may hold plain ids.
Map<String, String> _courseMap(dynamic related) {
  final out = <String, String>{};
  if (related is List) {
    for (final c in related) {
      if (c is Map) {
        final id = (c['_id'] ?? c['id'])?.toString();
        if (id != null) out[id] = (c['title'] ?? 'Course').toString();
      } else if (c != null) {
        out[c.toString()] = 'Course';
      }
    }
  }
  return out;
}

Color _cardColor(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark ? const Color(0xFF1F2937) : Colors.white;
Color _borderColor(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
Color _surfaceColor(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);

InputDecoration _input(BuildContext context, String label, {String? hint, Widget? prefix, Widget? suffix}) {
  final border = _borderColor(context);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    isDense: true,
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: _cardColor(context),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5)),
  );
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AdminBooksScreen extends ConsumerStatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  ConsumerState<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends ConsumerState<AdminBooksScreen> {
  // Data
  List<Map<String, dynamic>> _books = [];
  Map<String, dynamic> _stats = {};
  List<String> _subjects = [];
  List<String> _categories = [];
  int _total = 0;
  int _pages = 1;

  // Query
  int _page = 1;
  int _limit = 20;
  String _search = '';
  String _status = 'All';
  String _subject = 'All';
  String _language = 'All';
  String _category = 'All';
  String _courseId = 'All';
  String _sort = 'newest';

  // UI
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool _grid = true;
  final Set<String> _selected = {};
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(adminCourseProvider);
      if (s.courses.isEmpty && !s.isLoading) {
        ref.read(adminCourseProvider.notifier).loadCourses();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _search.isNotEmpty ||
      _status != 'All' ||
      _subject != 'All' ||
      _language != 'All' ||
      _category != 'All' ||
      _courseId != 'All';

  Future<void> _load({bool keepSelection = false}) async {
    final seq = ++_requestSeq;
    setState(() {
      _loading = true;
      _error = null;
      if (!keepSelection) _selected.clear();
    });
    try {
      final data = await _BooksApi.list({
        'page': '$_page',
        'limit': '$_limit',
        'sort': _sort,
        if (_search.isNotEmpty) 'search': _search,
        if (_status != 'All') 'status': _status,
        if (_subject != 'All') 'subject': _subject,
        if (_language != 'All') 'language': _language,
        if (_category != 'All') 'academicCategory': _category,
        if (_courseId != 'All') 'courseId': _courseId,
      });
      if (!mounted || seq != _requestSeq) return;
      final pag = Map<String, dynamic>.from(data['pagination'] ?? {});
      final pages = (pag['pages'] as num?)?.toInt() ?? 1;
      setState(() {
        _books = (data['books'] as List? ?? []).map((b) => Map<String, dynamic>.from(b as Map)).toList();
        _stats = Map<String, dynamic>.from(data['stats'] ?? {});
        _subjects = List<String>.from(data['subjects'] ?? const []);
        _categories = List<String>.from(data['academicCategories'] ?? const []);
        _total = (pag['total'] as num?)?.toInt() ?? _books.length;
        _pages = pages < 1 ? 1 : pages;
        _loading = false;
      });
      // Landed past the last page (e.g. after deleting) → step back.
      if (_books.isEmpty && _page > 1 && _page > _pages) {
        _page = _pages;
        _load();
      }
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _applyFilter(VoidCallback change) {
    setState(() {
      change();
      _page = 1;
    });
    _load();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (v.trim() == _search) return;
      _applyFilter(() => _search = v.trim());
    });
  }

  void _clearFilters() {
    _searchCtrl.clear();
    _applyFilter(() {
      _search = '';
      _status = 'All';
      _subject = 'All';
      _language = 'All';
      _category = 'All';
      _courseId = 'All';
    });
  }

  void _goToPage(int p) {
    if (p < 1 || p > _pages || p == _page) return;
    setState(() => _page = p);
    _load();
  }

  // ---- Actions -------------------------------------------------------------

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<bool> _confirm(String title, String message, {String action = 'Delete'}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _cardColor(c),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _openForm([Map<String, dynamic>? book]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BookFormDialog(
        book: book,
        subjects: _subjects,
        categories: {..._defaultCategories, ..._categories}.toList(),
      ),
    );
    if (saved == true) {
      _snack(book == null ? 'Book added' : 'Book updated');
      _load(keepSelection: true);
    }
  }

  Future<void> _togglePublish(Map<String, dynamic> book) async {
    final next = !(book['isPublished'] == true);
    setState(() => book['isPublished'] = next);
    try {
      await _BooksApi.update(book['_id'], {'isPublished': next});
      _snack(next ? 'Book published' : 'Book moved to drafts');
      _load(keepSelection: true);
    } catch (e) {
      setState(() => book['isPublished'] = !next);
      _snack('Could not update: $e', error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> book) async {
    if (!await _confirm('Delete book', 'Delete "${book['title']}"? Its PDF and cover will be removed permanently.')) {
      return;
    }
    try {
      await _BooksApi.delete(book['_id']);
      _snack('Book deleted');
      _selected.remove(book['_id']);
      _load(keepSelection: true);
    } catch (e) {
      _snack('Could not delete: $e', error: true);
    }
  }

  Future<void> _bulk(String action) async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    if (action == 'delete' &&
        !await _confirm('Delete ${ids.length} book(s)', 'These books and their files will be removed permanently.')) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _BooksApi.bulk(ids, action);
      _snack(action == 'delete'
          ? '${ids.length} book(s) deleted'
          : '${ids.length} book(s) ${action == 'publish' ? 'published' : 'moved to drafts'}');
      _load();
    } catch (e) {
      _snack('Bulk action failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview(Map<String, dynamic> book) async {
    try {
      final full = await _BooksApi.getOne(book['_id']);
      if (!mounted) return;
      context.push('/books/${book['_id']}', extra: full);
    } catch (e) {
      _snack('Could not open book: $e', error: true);
    }
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pad = ResponsiveBreakpoints.isMobile(context) ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primaryGreen,
                onRefresh: () => _load(keepSelection: true),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStats(context),
                            const SizedBox(height: 16),
                            _buildToolbar(context),
                            if (_selected.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildBulkBar(context),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    ..._buildContent(context, pad),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(pad, 8, pad, pad + 8),
                      sliver: SliverToBoxAdapter(child: _buildPagination(context)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondary = AppTheme.getSecondaryTextColor(context);
    final mobile = ResponsiveBreakpoints.isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(bottom: BorderSide(color: _borderColor(context))),
      ),
      child: Row(
        children: [
          if (context.canPop())
            IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
              onPressed: () => context.pop(),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Library Books',
                    style: TextStyle(fontSize: mobile ? 20 : 24, fontWeight: FontWeight.w800, color: textColor)),
                Text('${_stats['total'] ?? _total} books in the library',
                    style: TextStyle(fontSize: 13, color: secondary)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _load(keepSelection: true),
            icon: Icon(Icons.refresh_rounded, color: textColor),
          ),
          const SizedBox(width: 4),
          mobile
              ? IconButton.filled(
                  onPressed: () => _openForm(),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  tooltip: 'Add book',
                )
              : FilledButton.icon(
                  onPressed: () => _openForm(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Book'),
                ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final items = <(String, String, IconData, Color, VoidCallback?)>[
      ('Total', '${_stats['total'] ?? 0}', Icons.menu_book_rounded, AppTheme.primaryGreen,
          () => _applyFilter(() => _status = 'All')),
      ('Published', '${_stats['published'] ?? 0}', Icons.public_rounded, Colors.blue,
          () => _applyFilter(() => _status = 'published')),
      ('Drafts', '${_stats['drafts'] ?? 0}', Icons.edit_note_rounded, Colors.orange,
          () => _applyFilter(() => _status = 'draft')),
      ('No cover', '${_stats['withoutCover'] ?? 0}', Icons.hide_image_outlined, Colors.purple,
          () => _applyFilter(() => _status = 'nocover')),
      ('Opens', '${_stats['downloads'] ?? 0}', Icons.trending_up_rounded, Colors.teal, null),
      ('Storage', _formatBytes(_stats['totalSize'] as num?), Icons.cloud_outlined, Colors.indigo, null),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1000 ? 6 : (c.maxWidth > 600 ? 3 : 2);
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final it in items)
            SizedBox(width: w, child: _StatTile(label: it.$1, value: it.$2, icon: it.$3, color: it.$4, onTap: it.$5)),
        ],
      );
    });
  }

  Widget _buildToolbar(BuildContext context) {
    final secondary = AppTheme.getSecondaryTextColor(context);
    final courses = ref.watch(adminCourseProvider).courses;

    Widget dd<T>(String label, T value, Map<T, String> options, ValueChanged<T> onChanged, {double width = 170}) {
      return SizedBox(
        width: width,
        child: DropdownButtonFormField<T>(
          key: ValueKey('$label-$value'),
          initialValue: options.containsKey(value) ? value : null,
          isExpanded: true,
          isDense: true,
          dropdownColor: _cardColor(context),
          decoration: _input(context, label),
          items: [
            for (final e in options.entries)
              DropdownMenuItem<T>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  onSubmitted: (v) {
                    _debounce?.cancel();
                    _applyFilter(() => _search = v.trim());
                  },
                  decoration: _input(
                    context,
                    'Search',
                    hint: 'Title, author, subject, level…',
                    prefix: const Icon(Icons.search_rounded),
                    suffix: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilter(() => _search = '');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, icon: Icon(Icons.grid_view_rounded), tooltip: 'Grid'),
                  ButtonSegment(value: false, icon: Icon(Icons.view_list_rounded), tooltip: 'List'),
                ],
                selected: {_grid},
                onSelectionChanged: (s) => setState(() => _grid = s.first),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              dd<String>('Status', _status, const {
                'All': 'All statuses',
                'published': 'Published',
                'draft': 'Drafts',
                'nocover': 'Missing cover',
              }, (v) => _applyFilter(() => _status = v), width: 150),
              dd<String>('Subject', _subject, {'All': 'All subjects', for (final s in _subjects) s: s},
                  (v) => _applyFilter(() => _subject = v)),
              dd<String>('Language', _language, {'All': 'All languages', ..._languages},
                  (v) => _applyFilter(() => _language = v), width: 150),
              dd<String>('Level', _category, {'All': 'All levels', for (final c in _categories) c: c},
                  (v) => _applyFilter(() => _category = v), width: 150),
              dd<String>('Course', _courseId, {
                'All': 'All courses',
                'none': 'Not linked to a course',
                for (final c in courses) c.id: c.title,
              }, (v) => _applyFilter(() => _courseId = v), width: 220),
              dd<String>('Sort by', _sort, _sortOptions, (v) => _applyFilter(() => _sort = v), width: 170),
              if (_hasFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text('Clear filters'),
                ),
            ],
          ),
          if (!_loading && _error == null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _books.isNotEmpty && _books.every((b) => _selected.contains(b['_id']))
                      ? true
                      : (_books.any((b) => _selected.contains(b['_id'])) ? null : false),
                  tristate: true,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: _books.isEmpty
                      ? null
                      : (_) => setState(() {
                            final all = _books.every((b) => _selected.contains(b['_id']));
                            for (final b in _books) {
                              all ? _selected.remove(b['_id']) : _selected.add(b['_id']);
                            }
                          }),
                ),
                Text('Select page', style: TextStyle(fontSize: 13, color: secondary)),
                const Spacer(),
                Text(
                  _hasFilters ? '$_total matching books' : '$_total books',
                  style: TextStyle(fontSize: 13, color: secondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulkBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${_selected.length} selected',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _bulk('publish'),
            icon: const Icon(Icons.public_rounded, size: 18),
            label: const Text('Publish'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _bulk('unpublish'),
            icon: const Icon(Icons.visibility_off_rounded, size: 18),
            label: const Text('Unpublish'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _busy ? null : () => _bulk('delete'),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete'),
          ),
          TextButton(onPressed: () => setState(_selected.clear), child: const Text('Clear selection')),
          if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, double pad) {
    if (_loading && _books.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [SliverToBoxAdapter(child: _buildMessage(context, Icons.error_outline_rounded, 'Could not load books', _error!, retry: true))];
    }
    if (_books.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _hasFilters
              ? _buildMessage(context, Icons.search_off_rounded, 'No books match these filters',
                  'Try a different search or clear the filters.',
                  action: TextButton(onPressed: _clearFilters, child: const Text('Clear filters')))
              : _buildMessage(context, Icons.menu_book_rounded, 'No books yet', 'Add your first book to the library.',
                  action: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Book'),
                  )),
        ),
      ];
    }

    final loadingBar = _loading
        ? const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(color: AppTheme.primaryGreen, minHeight: 2),
            ),
          )
        : const SliverToBoxAdapter(child: SizedBox(height: 2));

    if (_grid) {
      return [
        SliverPadding(padding: EdgeInsets.symmetric(horizontal: pad), sliver: loadingBar),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.52,
            ),
            delegate: SliverChildBuilderDelegate(
              (c, i) => _BookGridCard(
                book: _books[i],
                selected: _selected.contains(_books[i]['_id']),
                onSelect: (v) => setState(() => v ? _selected.add(_books[i]['_id']) : _selected.remove(_books[i]['_id'])),
                onEdit: () => _openForm(_books[i]),
                onPreview: () => _preview(_books[i]),
                onTogglePublish: () => _togglePublish(_books[i]),
                onDelete: () => _delete(_books[i]),
              ),
              childCount: _books.length,
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(padding: EdgeInsets.symmetric(horizontal: pad), sliver: loadingBar),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: pad),
        sliver: SliverList.separated(
          itemCount: _books.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (c, i) => _BookListTile(
            book: _books[i],
            selected: _selected.contains(_books[i]['_id']),
            onSelect: (v) => setState(() => v ? _selected.add(_books[i]['_id']) : _selected.remove(_books[i]['_id'])),
            onEdit: () => _openForm(_books[i]),
            onPreview: () => _preview(_books[i]),
            onTogglePublish: () => _togglePublish(_books[i]),
            onDelete: () => _delete(_books[i]),
          ),
        ),
      ),
    ];
  }

  Widget _buildMessage(BuildContext context, IconData icon, String title, String body,
      {bool retry = false, Widget? action}) {
    final textColor = AppTheme.getTextColor(context);
    final secondary = AppTheme.getSecondaryTextColor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 56, color: secondary),
          const SizedBox(height: 14),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: TextStyle(color: secondary)),
          const SizedBox(height: 18),
          if (retry)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              onPressed: _load,
              child: const Text('Retry'),
            ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    if (_error != null || (_books.isEmpty && !_loading)) return const SizedBox.shrink();
    final secondary = AppTheme.getSecondaryTextColor(context);
    final from = _total == 0 ? 0 : (_page - 1) * _limit + 1;
    final to = ((_page - 1) * _limit + _books.length).clamp(0, _total);

    // Page window: 1 … p-1 p p+1 … last
    final pages = <int?>[];
    for (var p = 1; p <= _pages; p++) {
      if (p == 1 || p == _pages || (p - _page).abs() <= 1) {
        pages.add(p);
      } else if (pages.isNotEmpty && pages.last != null) {
        pages.add(null);
      }
    }

    Widget navBtn(IconData icon, String tip, int target, bool enabled) => IconButton(
          tooltip: tip,
          onPressed: enabled && !_loading ? () => _goToPage(target) : null,
          icon: Icon(icon, size: 20),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Showing $from–$to of $_total', style: TextStyle(fontSize: 13, color: secondary)),
              const SizedBox(width: 16),
              Text('Per page', style: TextStyle(fontSize: 13, color: secondary)),
              const SizedBox(width: 6),
              DropdownButton<int>(
                value: _limit,
                underline: const SizedBox.shrink(),
                dropdownColor: _cardColor(context),
                items: const [10, 20, 50, 100]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                    .toList(),
                onChanged: (v) {
                  if (v == null || v == _limit) return;
                  _applyFilter(() => _limit = v);
                },
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              navBtn(Icons.first_page_rounded, 'First page', 1, _page > 1),
              navBtn(Icons.chevron_left_rounded, 'Previous page', _page - 1, _page > 1),
              for (final p in pages)
                p == null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text('…', style: TextStyle(color: secondary)),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: p == _page ? AppTheme.primaryGreen : null,
                              foregroundColor: p == _page ? Colors.white : AppTheme.getTextColor(context),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _loading ? null : () => _goToPage(p),
                            child: Text('$p', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
              navBtn(Icons.chevron_right_rounded, 'Next page', _page + 1, _page < _pages),
              navBtn(Icons.last_page_rounded, 'Last page', _pages, _page < _pages),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Book tiles
// ---------------------------------------------------------------------------

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatTile({required this.label, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardColor(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.getTextColor(context))),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppTheme.getSecondaryTextColor(context))),
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

class _BookCover extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final double radius;
  const _BookCover({this.url, this.width, this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
      child: const Center(child: Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen, size: 32)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: (url == null || url!.isEmpty)
          ? placeholder
          : Image.network(
              mediaProxyUrl(url),
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool published;
  const _StatusBadge(this.published);

  @override
  Widget build(BuildContext context) {
    final c = published ? AppTheme.primaryGreen : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(published ? 'Published' : 'Draft',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

class _BookMenu extends StatelessWidget {
  final bool published;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onTogglePublish;
  final VoidCallback onDelete;

  const _BookMenu({
    required this.published,
    required this.onEdit,
    required this.onPreview,
    required this.onTogglePublish,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert_rounded),
      color: _cardColor(context),
      onSelected: (v) {
        switch (v) {
          case 'edit':
            onEdit();
          case 'preview':
            onPreview();
          case 'publish':
            onTogglePublish();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Edit'))),
        const PopupMenuItem(
            value: 'preview', child: ListTile(leading: Icon(Icons.open_in_new_rounded), title: Text('Open / preview'))),
        PopupMenuItem(
          value: 'publish',
          child: ListTile(
            leading: Icon(published ? Icons.visibility_off_rounded : Icons.public_rounded),
            title: Text(published ? 'Unpublish' : 'Publish'),
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}

class _BookGridCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final bool selected;
  final ValueChanged<bool> onSelect;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onTogglePublish;
  final VoidCallback onDelete;

  const _BookGridCard({
    required this.book,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onPreview,
    required this.onTogglePublish,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondary = AppTheme.getSecondaryTextColor(context);
    final published = book['isPublished'] == true;
    final courses = _courseMap(book['relatedCourses']);

    return Material(
      color: _cardColor(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.primaryGreen : _borderColor(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _BookCover(url: book['coverUrl'], radius: 0),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Checkbox(
                          value: selected,
                          activeColor: AppTheme.primaryGreen,
                          visualDensity: VisualDensity.compact,
                          onChanged: (v) => onSelect(v ?? false),
                        ),
                      ),
                    ),
                    Positioned(top: 10, right: 8, child: _StatusBadge(published)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book['title'] ?? 'Untitled',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textColor)),
                          const SizedBox(height: 2),
                          Text(book['author'] ?? 'Unknown author',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: secondary)),
                          const SizedBox(height: 6),
                          Text(
                            [
                              book['subject'] ?? 'Other',
                              (book['language'] ?? 'en').toString().toUpperCase(),
                              if (courses.isNotEmpty) '${courses.length} course${courses.length == 1 ? '' : 's'}',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    _BookMenu(
                      published: published,
                      onEdit: onEdit,
                      onPreview: onPreview,
                      onTogglePublish: onTogglePublish,
                      onDelete: onDelete,
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

class _BookListTile extends StatelessWidget {
  final Map<String, dynamic> book;
  final bool selected;
  final ValueChanged<bool> onSelect;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onTogglePublish;
  final VoidCallback onDelete;

  const _BookListTile({
    required this.book,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onPreview,
    required this.onTogglePublish,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondary = AppTheme.getSecondaryTextColor(context);
    final published = book['isPublished'] == true;
    final courses = _courseMap(book['relatedCourses']);
    final mobile = ResponsiveBreakpoints.isMobile(context);

    Widget meta(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 14, color: secondary),
          const SizedBox(width: 4),
          Text(t, style: TextStyle(fontSize: 12, color: secondary)),
        ]);

    return Material(
      color: _cardColor(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primaryGreen : _borderColor(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: AppTheme.primaryGreen,
                onChanged: (v) => onSelect(v ?? false),
              ),
              _BookCover(url: book['coverUrl'], width: 56, height: 76),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(book['title'] ?? 'Untitled',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textColor)),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(published),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${book['author'] ?? 'Unknown author'} · ${book['subject'] ?? 'Other'}'
                      '${(book['academicCategory'] ?? '').toString().isNotEmpty ? ' · ${book['academicCategory']}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: secondary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        meta(Icons.translate_rounded, _languages[book['language']] ?? (book['language'] ?? 'en')),
                        if (book['pages'] != null) meta(Icons.description_outlined, '${book['pages']} pages'),
                        meta(Icons.save_outlined, _formatBytes(book['fileSize'] as num?)),
                        meta(Icons.trending_up_rounded, '${book['downloadCount'] ?? 0} opens'),
                        if (!mobile) meta(Icons.calendar_today_rounded, _formatDate(book['createdAt'])),
                        meta(Icons.school_outlined,
                            courses.isEmpty ? 'No courses' : courses.values.take(2).join(', ') + (courses.length > 2 ? ' +${courses.length - 2}' : '')),
                      ],
                    ),
                  ],
                ),
              ),
              if (!mobile) ...[
                IconButton(
                  tooltip: published ? 'Unpublish' : 'Publish',
                  onPressed: onTogglePublish,
                  icon: Icon(published ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: published ? AppTheme.primaryGreen : Colors.grey),
                ),
                IconButton(
                    tooltip: 'Edit', onPressed: onEdit, icon: const Icon(Icons.edit_rounded, color: Colors.orange)),
              ],
              _BookMenu(
                published: published,
                onEdit: onEdit,
                onPreview: onPreview,
                onTogglePublish: onTogglePublish,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create / edit form
// ---------------------------------------------------------------------------

class BookFormDialog extends ConsumerStatefulWidget {
  /// Null → create a new book.
  final Map<String, dynamic>? book;
  final List<String> subjects;
  final List<String> categories;

  const BookFormDialog({super.key, this.book, required this.subjects, required this.categories});

  @override
  ConsumerState<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends ConsumerState<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _description;
  late final TextEditingController _subject;
  late final TextEditingController _category;
  late final TextEditingController _pages;
  late String _language;
  late bool _published;
  late Map<String, String> _courses; // id → title
  final _subjectFocus = FocusNode();
  final _categoryFocus = FocusNode();

  PlatformFile? _newPdf;
  PlatformFile? _newCover;
  bool _removeCover = false;
  bool _saving = false;
  String _savingStep = '';
  String? _error;

  bool get _isEdit => widget.book != null;
  Map<String, dynamic> get _b => widget.book ?? const {};

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: _b['title'] ?? '');
    _author = TextEditingController(text: _b['author'] ?? '');
    _description = TextEditingController(text: _b['description'] ?? '');
    _subject = TextEditingController(text: _b['subject'] ?? '');
    _category = TextEditingController(text: _b['academicCategory'] ?? '');
    _pages = TextEditingController(text: _b['pages']?.toString() ?? '');
    _language = (_b['language'] ?? 'en').toString();
    _published = _isEdit ? _b['isPublished'] == true : true;
    _courses = _courseMap(_b['relatedCourses']);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(adminCourseProvider);
      if (s.courses.isEmpty && !s.isLoading) ref.read(adminCourseProvider.notifier).loadCourses();
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _author, _description, _subject, _category, _pages]) {
      c.dispose();
    }
    _subjectFocus.dispose();
    _categoryFocus.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
      final f = r?.files.single;
      if (f == null) return;
      if (f.bytes == null) {
        setState(() => _error = 'Could not read the selected PDF.');
        return;
      }
      if (f.size > 50 * 1024 * 1024) {
        setState(() => _error = 'PDF is larger than 50 MB.');
        return;
      }
      setState(() {
        _newPdf = f;
        _error = null;
        if (_title.text.trim().isEmpty) {
          _title.text = f.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '').replaceAll(RegExp(r'[_-]+'), ' ');
        }
      });
    } catch (e) {
      setState(() => _error = 'Failed to pick PDF: $e');
    }
  }

  Future<void> _pickCover() async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      final f = r?.files.single;
      if (f == null) return;
      if (f.bytes == null) {
        setState(() => _error = 'Could not read the selected image.');
        return;
      }
      if (f.size > 10 * 1024 * 1024) {
        setState(() => _error = 'Cover image is larger than 10 MB.');
        return;
      }
      setState(() {
        _newCover = f;
        _removeCover = false;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _pickCourses() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _CoursePickerDialog(initial: _courses),
    );
    if (result != null) setState(() => _courses = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && _newPdf == null) {
      setState(() => _error = 'Please choose the book PDF.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      Map<String, dynamic> files = {};
      if (_newPdf != null || _newCover != null) {
        setState(() => _savingStep = 'Uploading files…');
        files = await _BooksApi.uploadFiles(pdf: _newPdf, cover: _newCover);
      }

      setState(() => _savingStep = 'Saving details…');
      final pagesText = _pages.text.trim();
      final body = <String, dynamic>{
        'title': _title.text.trim(),
        'author': _author.text.trim(),
        'description': _description.text.trim(),
        'subject': _subject.text.trim(),
        'academicCategory': _category.text.trim(),
        'language': _language,
        'isPublished': _published,
        'relatedCourses': _courses.keys.toList(),
        'pages': pagesText.isEmpty ? (files['pages']) : int.tryParse(pagesText),
      };

      if (_newPdf != null) {
        body.addAll({
          'pdfUrl': files['pdfUrl'],
          'pdfS3Key': files['pdfS3Key'],
          'fileSize': files['fileSize'],
          'textContent': files['textContent'],
        });
      }
      if (_newCover != null) {
        body['coverUrl'] = files['coverUrl'];
        body['coverS3Key'] = files['coverS3Key'];
      } else if (_removeCover) {
        body['coverUrl'] = null;
        body['coverS3Key'] = null;
      }

      if (_isEdit) {
        await _BooksApi.update(_b['_id'], body);
      } else {
        await _BooksApi.create(body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondary = AppTheme.getSecondaryTextColor(context);
    final desktop = ResponsiveBreakpoints.isDesktop(context);
    final size = MediaQuery.of(context).size;

    final details = _buildDetails(context);
    final media = _buildMedia(context);

    return Dialog(
      backgroundColor: _cardColor(context),
      insetPadding: EdgeInsets.all(desktop ? 32 : 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: desktop ? 980 : 640, maxHeight: size.height * 0.92),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 10, 14),
                child: Row(
                  children: [
                    Icon(_isEdit ? Icons.edit_rounded : Icons.library_add_rounded, color: AppTheme.primaryGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isEdit ? 'Edit book' : 'Add a new book',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
                          if (_isEdit)
                            Text(
                              'Added ${_formatDate(_b['createdAt'])}'
                              '${_b['uploadedBy'] is Map ? ' by ${_b['uploadedBy']['fullName'] ?? ''}' : ''}'
                              ' · ${_b['downloadCount'] ?? 0} opens',
                              style: TextStyle(fontSize: 12, color: secondary),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: _borderColor(context)),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: desktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: details),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: media),
                          ],
                        )
                      : Column(children: [media, const SizedBox(height: 20), details]),
                ),
              ),
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  ]),
                ),
              Divider(height: 1, color: _borderColor(context)),
              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                child: Row(
                  children: [
                    Switch(
                      value: _published,
                      activeThumbColor: AppTheme.primaryGreen,
                      onChanged: _saving ? null : (v) => setState(() => _published = v),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(_published ? 'Visible to students' : 'Draft (hidden)',
                          overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor)),
                    ),
                    const Spacer(),
                    if (_saving) ...[
                      const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen)),
                      const SizedBox(width: 8),
                      if (desktop) Text(_savingStep, style: TextStyle(color: secondary)),
                      const SizedBox(width: 12),
                    ],
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                      onPressed: _saving ? null : _save,
                      icon: Icon(_isEdit ? Icons.save_rounded : Icons.check_rounded),
                      label: Text(_isEdit ? 'Save changes' : 'Create book'),
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

  Widget _sectionTitle(BuildContext context, String t, {String? sub}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.getTextColor(context))),
            if (sub != null)
              Text(sub, style: TextStyle(fontSize: 12, color: AppTheme.getSecondaryTextColor(context))),
          ],
        ),
      );

  Widget _autocomplete(BuildContext context, TextEditingController ctrl, FocusNode focus, String label, List<String> options,
      {String? hint, String? Function(String?)? validator}) {
    return RawAutocomplete<String>(
      textEditingController: ctrl,
      focusNode: focus,
      optionsBuilder: (v) {
        final q = v.text.trim().toLowerCase();
        return options.where((o) => q.isEmpty || o.toLowerCase().contains(q)).take(12);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
        controller: controller,
        focusNode: focusNode,
        validator: validator,
        enabled: !_saving,
        decoration: _input(context, label, hint: hint, suffix: const Icon(Icons.arrow_drop_down_rounded)),
      ),
      optionsViewBuilder: (context, onSelected, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 6,
          color: _cardColor(context),
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [for (final o in opts) ListTile(dense: true, title: Text(o), onTap: () => onSelected(o))],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final secondary = AppTheme.getSecondaryTextColor(context);
    String? required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'Book details'),
        TextFormField(
          controller: _title,
          enabled: !_saving,
          maxLength: 200,
          validator: required,
          decoration: _input(context, 'Title *'),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _author,
          enabled: !_saving,
          maxLength: 100,
          validator: required,
          decoration: _input(context, 'Author *'),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _description,
          enabled: !_saving,
          maxLines: 4,
          maxLength: 2000,
          decoration: _input(context, 'Description', hint: 'What is this book about?'),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, c) {
          final two = c.maxWidth > 420;
          final subject = _autocomplete(context, _subject, _subjectFocus, 'Subject *', widget.subjects,
              hint: 'e.g. Mathematics', validator: required);
          final category = _autocomplete(context, _category, _categoryFocus, 'Level / category', widget.categories,
              hint: 'e.g. O-Level');
          return two
              ? Row(children: [Expanded(child: subject), const SizedBox(width: 12), Expanded(child: category)])
              : Column(children: [subject, const SizedBox(height: 12), category]);
        }),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final two = c.maxWidth > 420;
          final lang = DropdownButtonFormField<String>(
            initialValue: _languages.containsKey(_language) ? _language : null,
            isExpanded: true,
            dropdownColor: _cardColor(context),
            decoration: _input(context, 'Language'),
            items: [for (final e in _languages.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: _saving ? null : (v) => setState(() => _language = v ?? 'en'),
          );
          final pages = TextFormField(
            controller: _pages,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _input(context, 'Pages', hint: 'Auto-detected from PDF'),
          );
          return two
              ? Row(children: [Expanded(child: lang), const SizedBox(width: 12), Expanded(child: pages)])
              : Column(children: [lang, const SizedBox(height: 12), pages]);
        }),
        const SizedBox(height: 20),
        _sectionTitle(context, 'Related courses', sub: 'Students in these courses will see this book in the course.'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _surfaceColor(context), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_courses.isEmpty)
                Text('Not linked to any course', style: TextStyle(fontSize: 13, color: secondary))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in _courses.entries)
                      InputChip(
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(_courseTitle(e.key, e.value), overflow: TextOverflow.ellipsis),
                        ),
                        onDeleted: _saving ? null : () => setState(() => _courses.remove(e.key)),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickCourses,
                    icon: const Icon(Icons.playlist_add_rounded, size: 18),
                    label: Text(_courses.isEmpty ? 'Link courses' : 'Change courses'),
                  ),
                  if (_courses.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _saving ? null : () => setState(() => _courses.clear()),
                      child: const Text('Remove all'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Prefer the live course title (from the provider) over a stale/placeholder one.
  String _courseTitle(String id, String fallback) {
    final list = ref.watch(adminCourseProvider).courses;
    for (final c in list) {
      if (c.id == id) return c.title;
    }
    return fallback;
  }

  Widget _buildMedia(BuildContext context) {
    final secondary = AppTheme.getSecondaryTextColor(context);
    final textColor = AppTheme.getTextColor(context);
    final existingCover = _removeCover ? null : _b['coverUrl'] as String?;
    final hasCover = _newCover != null || (existingCover != null && existingCover.isNotEmpty);

    Widget coverImage;
    if (_newCover?.bytes != null) {
      coverImage = Image.memory(_newCover!.bytes!, fit: BoxFit.cover);
    } else if (existingCover != null && existingCover.isNotEmpty) {
      coverImage = _BookCover(url: existingCover, radius: 0);
    } else {
      coverImage = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 40, color: secondary),
          const SizedBox(height: 6),
          Text('No cover', style: TextStyle(color: secondary, fontSize: 12)),
        ],
      );
    }

    final hasExistingPdf = _isEdit && (_b['pdfUrl'] ?? '').toString().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'Cover image', sub: 'JPG, PNG or WebP. Portrait (3:4) looks best.'),
        Center(
          child: InkWell(
            onTap: _saving ? null : _pickCover,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 180,
              height: 240,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _surfaceColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor(context)),
              ),
              child: coverImage,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickCover,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(hasCover ? 'Replace cover' : 'Choose cover'),
            ),
            if (_newCover != null)
              TextButton(
                onPressed: _saving ? null : () => setState(() => _newCover = null),
                child: const Text('Undo'),
              ),
            if (_newCover == null && existingCover != null && existingCover.isNotEmpty)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: _saving ? null : () => setState(() => _removeCover = true),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Remove'),
              ),
            if (_removeCover)
              TextButton(
                onPressed: _saving ? null : () => setState(() => _removeCover = false),
                child: const Text('Keep current cover'),
              ),
          ],
        ),
        const SizedBox(height: 22),
        _sectionTitle(context, 'PDF file ${_isEdit ? '' : '*'}', sub: 'Up to 50 MB. Text is extracted for read-aloud.'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _newPdf != null ? AppTheme.primaryGreen : _borderColor(context)),
          ),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded,
                  color: _newPdf != null || hasExistingPdf ? Colors.red.shade400 : secondary, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _newPdf?.name ?? (hasExistingPdf ? 'Current PDF' : 'No file chosen'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                    ),
                    Text(
                      _newPdf != null
                          ? '${_formatBytes(_newPdf!.size)} · ${_isEdit ? 'will replace the current file' : 'ready to upload'}'
                          : hasExistingPdf
                              ? '${_formatBytes(_b['fileSize'] as num?)}${_b['pages'] != null ? ' · ${_b['pages']} pages' : ''}'
                              : 'Choose the book PDF',
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickPdf,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(_newPdf != null || hasExistingPdf ? 'Replace PDF' : 'Choose PDF'),
            ),
            if (_newPdf != null)
              TextButton(
                onPressed: _saving ? null : () => setState(() => _newPdf = null),
                child: Text(_isEdit ? 'Keep current PDF' : 'Remove'),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Course picker
// ---------------------------------------------------------------------------

class _CoursePickerDialog extends ConsumerStatefulWidget {
  final Map<String, String> initial;
  const _CoursePickerDialog({required this.initial});

  @override
  ConsumerState<_CoursePickerDialog> createState() => _CoursePickerDialogState();
}

class _CoursePickerDialogState extends ConsumerState<_CoursePickerDialog> {
  late final Map<String, String> _sel = Map.of(widget.initial);
  String _q = '';
  bool _onlySelected = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCourseProvider);
    final textColor = AppTheme.getTextColor(context);
    final secondary = AppTheme.getSecondaryTextColor(context);
    final q = _q.toLowerCase();
    final list = state.courses.where((c) {
      if (_onlySelected && !_sel.containsKey(c.id)) return false;
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.level.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      backgroundColor: _cardColor(context),
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 620, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(children: [
                Expanded(
                  child: Text('Link courses',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v.trim()),
                decoration: _input(context, 'Search courses', prefix: const Icon(Icons.search_rounded)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                Checkbox(
                  value: _onlySelected,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (v) => setState(() => _onlySelected = v ?? false),
                ),
                Text('Show selected only', style: TextStyle(fontSize: 13, color: secondary)),
                const Spacer(),
                Text('${state.courses.length} courses', style: TextStyle(fontSize: 12, color: secondary)),
                const SizedBox(width: 12),
              ]),
            ),
            Divider(height: 1, color: _borderColor(context)),
            Flexible(
              child: state.isLoading && state.courses.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                    )
                  : state.error != null && state.courses.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('Could not load courses: ${state.error}',
                                textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => ref.read(adminCourseProvider.notifier).loadCourses(),
                              child: const Text('Retry'),
                            ),
                          ]),
                        )
                      : list.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text('No courses found', style: TextStyle(color: secondary)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final c = list[i];
                                final on = _sel.containsKey(c.id);
                                return CheckboxListTile(
                                  value: on,
                                  activeColor: AppTheme.primaryGreen,
                                  onChanged: (v) => setState(() => v == true ? _sel[c.id] = c.title : _sel.remove(c.id)),
                                  secondary: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: c.thumbnail != null && c.thumbnail!.isNotEmpty
                                        ? Image.network(
                                            mediaProxyUrl(c.thumbnail),
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox(width: 44, height: 44, child: Icon(Icons.school_rounded)),
                                          )
                                        : const SizedBox(width: 44, height: 44, child: Icon(Icons.school_rounded)),
                                  ),
                                  title: Text(c.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                                  subtitle: Text(
                                    [if (c.level.isNotEmpty) c.level, if (!c.isPublished) 'Unpublished'].join(' · '),
                                    style: TextStyle(fontSize: 12, color: secondary),
                                  ),
                                );
                              },
                            ),
            ),
            Divider(height: 1, color: _borderColor(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 12),
              child: Row(children: [
                Text('${_sel.length} selected', style: TextStyle(color: secondary)),
                const Spacer(),
                TextButton(onPressed: () => setState(_sel.clear), child: const Text('Clear')),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  onPressed: () => Navigator.pop(context, _sel),
                  child: const Text('Done'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
