import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/school/attachments.dart';
import '../../../widgets/school/pickers.dart';
import '../../../widgets/school/school_ui.dart';
import '../../providers/auth_provider.dart';

/// Class groups (the school community): teachers create and moderate,
/// students discuss. One screen for both, depending on the role.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _svc = SchoolService();
  final _key = GlobalKey<AsyncBodyState<List<Map<String, dynamic>>>>();

  Future<void> _create() async {
    final g = await Navigator.of(context).push<Map<String, dynamic>>(MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
    if (g == null || !mounted) return;
    _key.currentState?.reload();
    context.push('/school/groups/${g['id']}');
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).user?.role;
    final staff = role == 'instructor' || role == 'school_admin' || role == 'admin';
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const T('Class groups')),
      floatingActionButton: staff ? FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.group_add_outlined), label: const T('New group')) : null,
      body: AsyncBody<List<Map<String, dynamic>>>(
        key: _key,
        load: _svc.groups,
        builder: (context, groups, reload) => SchoolPage(onRefresh: reload, maxWidth: 820, children: [
          if (groups.isEmpty)
            EmptyState(
              icon: Icons.forum_outlined,
              title: staff ? 'No groups yet' : 'No groups yet',
              message: staff
                  ? 'Create a group for a class you teach — the whole class or a few students — to discuss lessons, share photos and answer questions.'
                  : 'When your teacher adds you to a group, it appears here.',
              action: staff ? FilledButton.icon(onPressed: _create, icon: const Icon(Icons.group_add_outlined), label: const T('New group')) : null,
            )
          else
            for (final g in groups) GroupTile(g: g, onReturn: reload),
          const SizedBox(height: 60),
        ]),
      ),
    );
  }
}

class GroupTile extends StatelessWidget {
  const GroupTile({super.key, required this.g, this.onReturn});
  final Map<String, dynamic> g;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final unread = (g['unread'] as num?)?.toInt() ?? 0;
    final muted = AppTheme.getSecondaryTextColor(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await context.push('/school/groups/${g['id']}');
            onReturn?.call();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.6))),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: Icon(g['announcementsOnly'] == true ? Icons.campaign_outlined : Icons.forum_outlined, color: AppTheme.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  T('${g['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    [g['className'], g['subject'], '${g['studentCount']} students', if (g['lastMessageAt'] != null) 'last ${relativeDay(g['lastMessageAt'])}']
                        .where((e) => e != null && '$e'.isNotEmpty).join(' · '),
                    style: TextStyle(fontSize: 12.5, color: muted),
                  ),
                ]),
              ),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                  child: T('$unread', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Teacher: create a group for one of their classes (whole class or chosen students).
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key, this.classroomId, this.subject});
  final String? classroomId;
  final String? subject;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _svc = SchoolService();
  final _name = TextEditingController();
  final _description = TextEditingController();
  List<Map<String, dynamic>> _classes = [];
  String? _classId;
  String? _subject;
  bool _wholeClass = true;
  bool _announcements = false;
  List<Map<String, dynamic>> _students = [];
  final Set<String> _picked = {};
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _classId = widget.classroomId;
    _subject = widget.subject;
    _loadClasses();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final t = await _svc.myTeaching();
      final map = <String, Map<String, dynamic>>{};
      for (final c in SchoolService.list(t['classTeacherOf'])) {
        map['${c['id']}'] = {'id': '${c['id']}', 'name': c['name'], 'subjects': <String>[]};
      }
      for (final s in SchoolService.list(t['subjects'])) {
        map.putIfAbsent('${s['classroomId']}', () => {'id': '${s['classroomId']}', 'name': s['className'], 'subjects': <String>[]});
        (map['${s['classroomId']}']!['subjects'] as List<String>).add('${s['subject']}');
      }
      if (t['schoolTeacher'] != true || map.isEmpty) {
        // School admins: every class of the school.
        try {
          for (final c in await _svc.classes('me')) {
            map.putIfAbsent('${c['id']}', () => {'id': '${c['id']}', 'name': c['name'], 'subjects': SchoolService.list(c['subjects']).map((s) => '${s['subject']}').toList()});
          }
        } catch (_) {}
      }
      setState(() {
        _classes = map.values.toList();
        _classId ??= _classes.isNotEmpty ? '${_classes.first['id']}' : null;
        _loading = false;
      });
      if (_classId != null) _loadStudents();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showSnack(context, e.toString(), error: true);
      }
    }
  }

  Future<void> _loadStudents() async {
    try {
      final d = await _svc.classDetail(_classId!);
      if (mounted) setState(() { _students = SchoolService.list(d['students']); _picked.clear(); });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_classId == null) return showSnack(context, 'Choose a class', error: true);
    if (_name.text.trim().length < 2) return showSnack(context, 'Give the group a name', error: true);
    if (!_wholeClass && _picked.isEmpty) return showSnack(context, 'Choose at least one student', error: true);
    setState(() => _busy = true);
    try {
      final g = await _svc.createGroup({
        'classroomId': _classId,
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        if (_subject != null) 'subject': _subject,
        'wholeClass': _wholeClass,
        if (!_wholeClass) 'studentIds': _picked.toList(),
        'announcementsOnly': _announcements,
      });
      if (mounted) Navigator.pop(context, g);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = _classes.where((c) => c['id'] == _classId).firstOrNull;
    final subjects = (cl?['subjects'] as List?)?.cast<String>() ?? const <String>[];
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const T('New class group')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy || _loading ? null : _save,
            icon: const Icon(Icons.check),
            label: const T('Create group'),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? const EmptyState(icon: Icons.meeting_room_outlined, title: 'No classes', message: 'You can create groups for the classes you teach. Ask the school to assign you to a class.')
              : SchoolPage(maxWidth: 720, children: [
                  SectionCard(
                    child: Column(children: [
                      DropdownButtonFormField<String>(
                        initialValue: _classId,
                        decoration: const InputDecoration(labelText: 'Class'),
                        items: [for (final c in _classes) DropdownMenuItem(value: '${c['id']}', child: T('${c['name']}'))],
                        onChanged: (v) { setState(() { _classId = v; _subject = null; }); _loadStudents(); },
                      ),
                      if (subjects.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: subjects.contains(_subject) ? _subject : null,
                          decoration: const InputDecoration(labelText: 'Subject (optional)'),
                          items: [const DropdownMenuItem(value: null, child: T('General')), for (final s in subjects) DropdownMenuItem(value: s, child: Text(s))],
                          onChanged: (v) => setState(() => _subject = v),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(controller: _name, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Group name', hintText: 'e.g. S3 A Biology — questions')),
                      const SizedBox(height: 12),
                      TextField(controller: _description, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'What is it for? (optional)')),
                    ]),
                  ),
                  SectionCard(
                    title: 'Members',
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SegmentedButton<bool>(
                        segments: const [ButtonSegment(value: true, label: T('Whole class')), ButtonSegment(value: false, label: T('Choose students'))],
                        selected: {_wholeClass},
                        onSelectionChanged: (v) => setState(() => _wholeClass = v.first),
                      ),
                      const SizedBox(height: 8),
                      if (_wholeClass)
                        T('All ${_students.length} students of the class, and new students who join it later.', style: TextStyle(color: AppTheme.getSecondaryTextColor(context)))
                      else
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          for (final s in _students)
                            FilterChip(
                              avatar: CircleAvatar(child: Text(initialsOf(s['fullName']), style: const TextStyle(fontSize: 10))),
                              label: T('${s['fullName']}'),
                              selected: _picked.contains('${s['id']}'),
                              onSelected: (v) => setState(() => v ? _picked.add('${s['id']}') : _picked.remove('${s['id']}')),
                            ),
                        ]),
                    ]),
                  ),
                  SectionCard(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _announcements,
                      onChanged: (v) => setState(() => _announcements = v),
                      title: const T('Announcements only'),
                      subtitle: const T('Only teachers can post; students read and get notified.'),
                    ),
                  ),
                ]),
    );
  }
}

/// The discussion of one group. Polls for new messages while open.
class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key, required this.groupId});
  final String groupId;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _svc = SchoolService();
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Map<String, dynamic>? _group;
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _pinned = [];
  bool _canPost = false;
  bool _hasMore = false;
  bool _sending = false;
  bool _uploading = false;
  final List<Map<String, dynamic>> _photos = [];
  Map<String, dynamic>? _replyTo;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _initial();
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _newer());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _initial() async {
    try {
      final r = await Future.wait([_svc.group(widget.groupId), _svc.groupMessages(widget.groupId)]);
      if (!mounted) return;
      setState(() {
        _group = r[0];
        _apply(r[1], replace: true);
        _error = null;
      });
      _toBottom();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _apply(Map<String, dynamic> r, {bool replace = false, bool older = false}) {
    final list = SchoolService.list(r['messages']);
    if (replace) {
      _messages..clear()..addAll(list);
      _hasMore = r['hasMore'] == true;
    } else if (older) {
      _messages.insertAll(0, list);
      _hasMore = r['hasMore'] == true;
    } else {
      final ids = _messages.map((m) => m['id']).toSet();
      _messages.addAll(list.where((m) => !ids.contains(m['id'])));
    }
    _pinned = SchoolService.list(r['pinned']);
    _canPost = r['canPost'] == true;
  }

  Future<void> _newer() async {
    if (_messages.isEmpty || !mounted) return;
    try {
      final r = await _svc.groupMessages(widget.groupId, after: '${_messages.last['createdAt']}');
      if (!mounted) return;
      final before = _messages.length;
      setState(() => _apply(r));
      if (_messages.length > before) _toBottom();
    } catch (_) {}
  }

  Future<void> _older() async {
    if (_messages.isEmpty) return;
    try {
      final r = await _svc.groupMessages(widget.groupId, before: '${_messages.first['createdAt']}');
      if (mounted) setState(() => _apply(r, older: true));
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty && _photos.isEmpty) return;
    setState(() => _sending = true);
    try {
      final m = await _svc.postGroupMessage(widget.groupId, text: text, attachments: List.of(_photos), replyTo: _replyTo?['id'] as String?);
      setState(() {
        _messages.add(m);
        _text.clear();
        _photos.clear();
        _replyTo = null;
      });
      _toBottom();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _messageMenu(Map<String, dynamic> m) async {
    final teacher = _group?['isTeacher'] == true;
    final v = await showModalBottomSheet<String>(context: context, builder: (ctx) => SafeArea(
      child: Wrap(children: [
        if (_canPost) ListTile(leading: const Icon(Icons.reply), title: const T('Reply'), onTap: () => Navigator.pop(ctx, 'reply')),
        if (teacher && m['deleted'] != true) ListTile(leading: const Icon(Icons.push_pin_outlined), title: Text(m['pinned'] == true ? 'Unpin' : 'Pin for everyone'), onTap: () => Navigator.pop(ctx, 'pin')),
        if (m['canDelete'] == true) ListTile(leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor), title: const T('Delete'), onTap: () => Navigator.pop(ctx, 'delete')),
      ]),
    ));
    try {
      if (v == 'reply') setState(() => _replyTo = m);
      if (v == 'pin') { await _svc.pinGroupMessage(widget.groupId, '${m['id']}', m['pinned'] != true); _initial(); }
      if (v == 'delete') { await _svc.deleteGroupMessage(widget.groupId, '${m['id']}'); _initial(); }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = _group;
    if (g == null) {
      return Scaffold(appBar: AppBar(title: const T('Group')), body: _error == null ? const Center(child: CircularProgressIndicator()) : ErrorRetry(message: _error!, onRetry: _initial));
    }
    final muted = AppTheme.getSecondaryTextColor(context);
    final byId = {for (final m in _messages) m['id']: m};
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          T('${g['name']}', style: const TextStyle(fontSize: 17)),
          Text([g['className'], '${g['studentCount']} students'].where((e) => e != null).join(' · '), style: TextStyle(fontSize: 12, color: muted)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Members & settings',
            icon: const Icon(Icons.info_outline),
            onPressed: () async {
              final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => GroupSettingsScreen(group: g)));
              if (changed == true) {
                if (!context.mounted) return;
                if (mounted) _initial();
              }
            },
          ),
        ],
      ),
      body: Column(children: [
        if (_pinned.isNotEmpty)
          Container(
            width: double.infinity,
            color: AppTheme.warningColor.withValues(alpha: 0.10),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(children: [
              const Icon(Icons.push_pin, size: 16, color: AppTheme.warningColor),
              const SizedBox(width: 8),
              Expanded(child: T('${_pinned.first['author']?['fullName'] ?? ''}: ${_pinned.first['text']}', maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        Expanded(
          child: _messages.isEmpty
              ? EmptyState(icon: Icons.forum_outlined, title: 'No messages yet', message: _canPost ? 'Start the discussion.' : 'Your teacher will post here.')
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: _messages.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_hasMore && i == 0) return Center(child: TextButton(onPressed: _older, child: const T('Older messages')));
                    final m = _messages[i - (_hasMore ? 1 : 0)];
                    return _Bubble(m: m, replyTo: m['replyTo'] != null ? byId[m['replyTo']] : null, onLongPress: () => _messageMenu(m));
                  },
                ),
        ),
        if (_canPost)
          SafeArea(
            top: false,
            child: Container(
              color: AppTheme.getCardColor(context),
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_replyTo != null)
                  Row(children: [
                    const Icon(Icons.reply, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: T('Replying to ${_replyTo!['author']?['fullName'] ?? ''}: ${_replyTo!['text']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12.5))),
                    IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _replyTo = null)),
                  ]),
                if (_photos.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 6), child: AttachmentStrip(items: _photos, size: 56, onRemove: (i) => setState(() => _photos.removeAt(i)))),
                Row(children: [
                  IconButton(
                    tooltip: 'Add photo',
                    icon: _uploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_photo_alternate_outlined),
                    onPressed: _uploading ? null : () async {
                      setState(() => _uploading = true);
                      final p = await pickAndUploadPhoto(context, _svc);
                      if (mounted) setState(() { if (p != null) _photos.add(p); _uploading = false; });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(hintText: trSchool(context, 'Write a message'), isDense: true),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send), color: AppTheme.primary),
                ]),
              ]),
            ),
          )
        else
          SafeArea(
            top: false,
            child: Padding(padding: const EdgeInsets.all(12), child: T('Only teachers can post in this group.', style: TextStyle(color: muted))),
          ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m, this.replyTo, required this.onLongPress});
  final Map<String, dynamic> m;
  final Map<String, dynamic>? replyTo;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final mine = m['mine'] == true;
    final staff = ['instructor', 'school_admin', 'admin'].contains(m['author']?['role']);
    final muted = AppTheme.getSecondaryTextColor(context);
    final bg = mine ? AppTheme.primary.withValues(alpha: 0.14) : AppTheme.getCardColor(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        onSecondaryTap: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78 > 560 ? 560 : MediaQuery.of(context).size.width * 0.78),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: mine ? 0 : 0.5)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!mine)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  T('${m['author']?['fullName'] ?? ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: staff ? AppTheme.primaryDark : AppTheme.getTextColor(context))),
                  if (staff) const Padding(padding: EdgeInsets.only(left: 6), child: StatusPill('Teacher', tone: Tone.good)),
                ]),
              if (replyTo != null)
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppTheme.getBorderColor(context).withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                  child: T('${replyTo!['author']?['fullName'] ?? ''}: ${replyTo!['text']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted)),
                ),
              if (m['deleted'] == true)
                T('Message deleted', style: TextStyle(fontStyle: FontStyle.italic, color: muted))
              else ...[
                if ('${m['text']}'.isNotEmpty) SelectableText('${m['text']}'),
                if ((m['attachments'] as List?)?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 6), child: AttachmentStrip(items: SchoolService.list(m['attachments']), size: 120)),
              ],
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (m['pinned'] == true) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.push_pin, size: 12, color: AppTheme.warningColor)),
                Text(fmtDateTime(m['createdAt']), style: TextStyle(fontSize: 10.5, color: muted)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Members, teachers, posting rule; teachers can change them or close the group.
class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key, required this.group});
  final Map<String, dynamic> group;

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  final _svc = SchoolService();
  late Map<String, dynamic> _g = widget.group;
  bool _changed = false;

  Future<void> _update(Map<String, dynamic> body) async {
    try {
      final g = await _svc.updateGroup('${_g['id']}', body);
      setState(() { _g = g; _changed = true; });
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacher = _g['isTeacher'] == true;
    final students = SchoolService.list(_g['students']);
    final teachers = SchoolService.list(_g['teachers']);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) Navigator.pop(context, _changed); },
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        appBar: AppBar(title: T('${_g['name']}')),
        body: SchoolPage(maxWidth: 720, children: [
          if ('${_g['description']}'.isNotEmpty) SectionCard(child: T('${_g['description']}')),
          if (teacher)
            SectionCard(
              child: Column(children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _g['announcementsOnly'] == true,
                  onChanged: (v) => _update({'announcementsOnly': v}),
                  title: const T('Announcements only'),
                  subtitle: const T('Only teachers can post.'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_add_alt_outlined),
                  title: const T('Add a teacher to moderate'),
                  onTap: () async {
                    final t = await pickTeacher(context, _svc, 'me', title: 'Add a teacher', allowNone: false);
                    if (t?['id'] != null) _update({'addTeacherId': t!['id']});
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.archive_outlined, color: AppTheme.errorColor),
                  title: const T('Close group', style: TextStyle(color: AppTheme.errorColor)),
                  onTap: () async {
                    if (!await confirm(context, title: 'Close this group?', message: 'Members can no longer read or post. Messages are kept for the school.', confirmLabel: 'Close', destructive: true)) return;
                    try {
                      await _svc.closeGroup('${_g['id']}');
                      if (context.mounted) { Navigator.pop(context, true); context.pop(); }
                    } catch (e) {
                      if (context.mounted) showSnack(context, e.toString(), error: true);
                    }
                  },
                ),
              ]),
            ),
          SectionCard(
            title: 'Teachers',
            child: Column(children: [
              for (final t in teachers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text(initialsOf(t['fullName']))),
                  title: T('${t['fullName']}'),
                  trailing: teacher && teachers.length > 1 ? IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _update({'removeTeacherId': t['id']})) : null,
                ),
            ]),
          ),
          SectionCard(
            title: 'Students (${students.length})',
            subtitle: _g['wholeClass'] == true ? 'Whole class ${_g['className'] ?? ''}' : 'Chosen students',
            trailing: teacher && _g['wholeClass'] != true
                ? TextButton(onPressed: () => _update({'wholeClass': true}), child: const T('Use whole class'))
                : null,
            child: Wrap(spacing: 6, runSpacing: 6, children: [for (final s in students) Chip(label: T('${s['fullName']}'))]),
          ),
        ]),
      ),
    );
  }
}
