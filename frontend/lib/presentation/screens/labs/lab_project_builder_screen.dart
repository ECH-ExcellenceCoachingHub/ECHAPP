import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/lab_project.dart';
import '../../providers/lab_provider.dart';
import '../../widgets/labs/lab_rooms.dart';

/// Student experiment builder: the idea (aim + hypothesis), the equipment with its
/// settings, and the method (actions, readings, calculations, observations, questions).
/// The backend compiles the spec into a playable 3D lab (POST /labs/projects).
class LabProjectBuilderScreen extends ConsumerStatefulWidget {
  /// Existing project to edit, or null for a new one.
  final String? projectId;

  /// Starting spec for a new project (blank, AI draft or remix).
  final Map<String, dynamic>? initialSpec;
  final String? remixOf;
  const LabProjectBuilderScreen({super.key, this.projectId, this.initialSpec, this.remixOf});

  @override
  ConsumerState<LabProjectBuilderScreen> createState() => _LabProjectBuilderScreenState();
}

class _LabProjectBuilderScreenState extends ConsumerState<LabProjectBuilderScreen> {
  Map<String, dynamic>? _spec;
  String? _projectId;
  String? _loadError;
  bool _saving = false;
  bool _dirty = false;
  List<String> _problems = const [];
  final _title = TextEditingController();
  final _aim = TextEditingController();
  final _hypothesis = TextEditingController();

  List<Map<String, dynamic>> get _equipment => (_spec!['equipment'] as List).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> get _steps => (_spec!['steps'] as List).cast<Map<String, dynamic>>();
  String get _env => (_spec!['environment'] ?? 'PhysicsLab').toString();

  @override
  void initState() {
    super.initState();
    _projectId = widget.projectId;
    if (widget.initialSpec != null) {
      _setSpec(widget.initialSpec!);
    } else if (widget.projectId != null) {
      _load();
    } else {
      _setSpec({'environment': 'PhysicsLab'});
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _aim.dispose();
    _hypothesis.dispose();
    super.dispose();
  }

  /// Deep, mutable copy with the lists the builder expects.
  void _setSpec(Map<String, dynamic> raw) {
    final spec = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
    spec['equipment'] = [for (final e in (spec['equipment'] as List? ?? const [])) Map<String, dynamic>.from(e as Map)..['init'] = Map<String, dynamic>.from((e['init'] as Map?) ?? {})];
    spec['steps'] = [for (final s in (spec['steps'] as List? ?? const [])) Map<String, dynamic>.from(s as Map)];
    // Stable keys for recorded values so calculations survive reordering.
    var n = 0;
    for (final s in spec['steps'] as List) {
      if ((s['kind'] == 'measure' || s['kind'] == 'calc') && (s['key'] == null || s['key'].toString().isEmpty)) s['key'] = 'v${++n}';
    }
    _title.text = (spec['title'] ?? '').toString();
    _aim.text = (spec['aim'] ?? '').toString();
    _hypothesis.text = (spec['hypothesis'] ?? '').toString();
    setState(() => _spec = spec);
  }

  Future<void> _load() async {
    try {
      final (_, spec) = await ref.read(labServiceProvider).getProject(widget.projectId!);
      _setSpec(spec);
    } catch (e) {
      setState(() => _loadError = '$e');
    }
  }

  Map<String, dynamic> _currentSpec() => {
        ..._spec!,
        'title': _title.text.trim(),
        'aim': _aim.text.trim(),
        'hypothesis': _hypothesis.text.trim(),
      };

  void _changed(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
        _problems = const [];
      });

  Future<bool> _save({bool run = false}) async {
    setState(() => _saving = true);
    try {
      final p = await ref.read(labServiceProvider).saveProject(_currentSpec(), id: _projectId, remixOf: _projectId == null ? widget.remixOf : null);
      _projectId = p.id;
      ref.invalidate(myLabProjectsProvider);
      if (!mounted) return true;
      setState(() {
        _dirty = false;
        _problems = const [];
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiment saved')));
      if (run) context.push('/lab/${p.id}');
      return true;
    } on LabProjectInvalid catch (e) {
      setState(() => _problems = e.errors);
      return false;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _check() async {
    setState(() => _saving = true);
    try {
      final problems = await ref.read(labServiceProvider).checkProject(_currentSpec());
      if (!mounted) return;
      setState(() => _problems = problems);
      if (problems.isEmpty) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Looks good — your experiment is ready to run!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave without saving?'),
        content: const Text('Your changes to this experiment will be lost.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave'))],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    final kitAsync = ref.watch(labKitProvider);
    if (_loadError != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_loadError!)));
    if (_spec == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return kitAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Could not load the lab kit: $e'))),
      data: (kit) {
        final room = kit.rooms[_env];
        if (room == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Unknown lab room')));
        final style = LabRoom.of(_env);
        return PopScope(
          canPop: !_dirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (await _confirmLeave() && context.mounted) {
              _dirty = false;
              context.canPop() ? context.pop() : context.go('/labs/projects');
            }
          },
          child: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: Text(_projectId == null ? 'New experiment' : 'Edit experiment', style: const TextStyle(fontWeight: FontWeight.w800)),
                bottom: TabBar(tabs: [
                  const Tab(icon: Icon(Icons.lightbulb_outline_rounded), text: 'Idea'),
                  Tab(icon: const Icon(Icons.science_outlined), text: 'Equipment (${_equipment.length})'),
                  Tab(icon: const Icon(Icons.format_list_numbered_rounded), text: 'Method (${_steps.length})'),
                ]),
                actions: [
                  TextButton.icon(onPressed: _saving ? null : _check, icon: const Icon(Icons.fact_check_outlined), label: const Text('Check')),
                ],
              ),
              body: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [style.gradient.first.withValues(alpha: 0.18), Colors.transparent])),
                  child: Row(children: [
                    Icon(style.icon, color: style.gradient.first, size: 18),
                    const SizedBox(width: 8),
                    Text(room.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                ),
                if (_problems.isNotEmpty) _ProblemsBanner(problems: _problems, onClose: () => setState(() => _problems = const [])),
                Expanded(
                  child: TabBarView(children: [
                    _ideaTab(room),
                    _equipmentTab(room),
                    _methodTab(room, kit.maxSteps),
                  ]),
                ),
              ]),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : () => _save(),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _save(run: true),
                        icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded),
                        label: const Text('Save & run in 3D'),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Idea ──────────────────────────────────────────────────────────────────

  Widget _ideaTab(LabKitRoom room) => ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
          controller: _title,
          maxLength: 120,
          onChanged: (_) => _dirty = true,
          decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Does a longer pendulum swing more slowly?', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _aim,
          maxLength: 400,
          minLines: 2,
          maxLines: 4,
          onChanged: (_) => _dirty = true,
          decoration: const InputDecoration(labelText: 'Aim — what do you want to find out?', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hypothesis,
          maxLength: 400,
          minLines: 2,
          maxLines: 4,
          onChanged: (_) => _dirty = true,
          decoration: const InputDecoration(labelText: 'Hypothesis — what do you think will happen, and why?', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        _Tips(tips: [
          'A good experiment changes ONE thing (independent variable), measures ONE thing (dependent variable) and keeps everything else the same.',
          ...room.tips,
        ]),
      ]);

  // ─── Equipment ─────────────────────────────────────────────────────────────

  Widget _equipmentTab(LabKitRoom room) {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Add equipment', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final item in room.items)
          ActionChip(
            avatar: Icon(_iconFor(item.category), size: 18),
            label: Text(item.shortTitle),
            onPressed: _equipment.where((e) => e['type'] == item.type).length >= item.max ? null : () => _addEquipment(item),
          ),
      ]),
      const SizedBox(height: 20),
      Text('On your bench', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      if (_equipment.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('Nothing yet — tap an item above to add it.', style: TextStyle(color: theme.hintColor))),
      for (final e in _equipment)
        if (room.item(e['type'].toString()) case final item?)
          _EquipmentCard(
            key: ValueKey(e['id']),
            data: e,
            item: item,
            usedInSteps: _stepsUsing(e['id'].toString()),
            onChanged: () => _changed(() {}),
            onRemove: () => _removeEquipment(e),
          ),
    ]);
  }

  void _addEquipment(LabKitItem item) => _changed(() {
        final base = item.type.replaceAll('_', '');
        var n = 1;
        while (_equipment.any((e) => e['id'] == '$base$n')) {
          n++;
        }
        final count = _equipment.where((e) => e['type'] == item.type).length;
        _equipment.add({
          'id': '$base$n',
          'type': item.type,
          'label': count == 0 ? '' : '${item.shortTitle} ${count + 1}',
          'init': {for (final p in item.params) p.key: p.defaultValue},
        });
      });

  int _stepsUsing(String id) => _steps.where((s) => s['target'] == id || s['into'] == id || (s['reading'] is Map && s['reading']['item'] == id)).length;

  Future<void> _removeEquipment(Map<String, dynamic> e) async {
    final used = _stepsUsing(e['id'].toString());
    if (used > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove this item?'),
          content: Text('$used ${used == 1 ? 'step uses' : 'steps use'} it. Those steps will be removed too.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove'))],
        ),
      );
      if (ok != true) return;
    }
    final id = e['id'];
    _changed(() {
      _equipment.remove(e);
      _steps.removeWhere((s) => s['target'] == id || s['into'] == id || (s['reading'] is Map && s['reading']['item'] == id));
    });
  }

  // ─── Method ────────────────────────────────────────────────────────────────

  Widget _methodTab(LabKitRoom room, int maxSteps) {
    final theme = Theme.of(context);
    return Column(children: [
      Expanded(
        child: _steps.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _equipment.isEmpty ? 'Add equipment first, then write your method step by step.' : 'Write your method one step at a time.\nTap "Add step" below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.hintColor),
                  ),
                ),
              )
            : ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: _steps.length,
                onReorder: (from, to) => _changed(() {
                  if (to > from) to--;
                  _steps.insert(to, _steps.removeAt(from));
                }),
                itemBuilder: (_, i) {
                  final s = _steps[i];
                  final (icon, color) = _kindStyle(s['kind']?.toString());
                  return Card(
                    key: ObjectKey(s),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Text('${i + 1}', style: TextStyle(color: color, fontWeight: FontWeight.w800))),
                      title: Text(_describe(s, room), maxLines: 3, overflow: TextOverflow.ellipsis),
                      subtitle: Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(_kindLabel(s['kind']?.toString()), style: TextStyle(color: color, fontSize: 12))]),
                      onTap: () => _editStep(room, s),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.delete_outline_rounded), tooltip: 'Delete step', onPressed: () => _changed(() => _steps.remove(s))),
                        ReorderableDragStartListener(index: i, child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.drag_handle_rounded))),
                      ]),
                    ),
                  );
                },
              ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: _steps.length >= maxSteps ? null : () => _addStep(room),
            icon: const Icon(Icons.add_rounded),
            label: Text(_steps.length >= maxSteps ? 'Maximum $maxSteps steps' : 'Add step'),
          ),
        ),
      ),
    ]);
  }

  Future<void> _addStep(LabKitRoom room) async {
    final kind = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final k in const ['action', 'measure', 'calc', 'info', 'checkpoint'])
            ListTile(
              leading: Icon(_kindStyle(k).$1, color: _kindStyle(k).$2),
              title: Text(_kindLabel(k), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(switch (k) {
                'action' => 'Use a piece of equipment (pour, connect, switch on, run code…)',
                'measure' => 'Read a value off an instrument and record it',
                'calc' => 'Work something out from your readings',
                'info' => 'Tell yourself what to look for or notice',
                _ => 'A multiple-choice question to test understanding',
              }),
              enabled: _equipment.isNotEmpty || k == 'info' || k == 'checkpoint' || k == 'calc',
              onTap: () => Navigator.pop(ctx, k),
            ),
        ]),
      ),
    );
    if (kind == null || !mounted) return;
    final step = <String, dynamic>{'kind': kind};
    if (kind == 'measure' || kind == 'calc') {
      var n = 1;
      while (_steps.any((s) => s['key'] == 'v$n')) {
        n++;
      }
      step['key'] = 'v$n';
    }
    final saved = await _openStepEditor(room, step, _steps.length);
    if (saved != null) _changed(() => _steps.add(saved));
  }

  Future<void> _editStep(LabKitRoom room, Map<String, dynamic> s) async {
    final saved = await _openStepEditor(room, Map<String, dynamic>.from(s), _steps.indexOf(s));
    if (saved != null) {
      _changed(() {
        s
          ..clear()
          ..addAll(saved);
      });
    }
  }

  Future<Map<String, dynamic>?> _openStepEditor(LabKitRoom room, Map<String, dynamic> step, int index) => showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: _StepEditor(
            step: step,
            room: room,
            equipment: _equipment,
            // Values recorded by EARLIER steps, for calculations.
            earlierRecords: [
              for (final s in _steps.take(index < 0 ? _steps.length : index))
                if ((s['kind'] == 'measure' || s['kind'] == 'calc') && s['key'] != null) (key: s['key'].toString(), label: (s['label'] ?? s['key']).toString()),
            ],
            labelOf: (id) => _labelOf(room, id),
          ),
        ),
      );

  String _labelOf(LabKitRoom room, String? id) {
    final e = _equipment.where((x) => x['id'] == id).firstOrNull;
    if (e == null) return '?';
    final label = (e['label'] ?? '').toString();
    return label.isNotEmpty ? label : (room.item(e['type'].toString())?.shortTitle ?? e['type'].toString());
  }

  String _describe(Map<String, dynamic> s, LabKitRoom room) {
    final instruction = (s['instruction'] ?? '').toString();
    switch (s['kind']) {
      case 'info':
        return instruction.isEmpty ? 'Observe' : instruction;
      case 'checkpoint':
        return 'Q: ${s['prompt'] ?? ''}';
      case 'calc':
        final ops = {'+': '+', '-': '−', '*': '×', '/': '÷'};
        String name(dynamic v) => _steps.where((x) => x['key'] == v).map((x) => (x['label'] ?? v).toString()).firstOrNull ?? '$v';
        return '${s['label'] ?? 'Result'} = ${name(s['a'])} ${ops[s['op']] ?? '?'} ${name(s['b'])}';
      case 'measure':
        if (s['reading'] is Map) {
          final item = _equipment.where((x) => x['id'] == s['reading']['item']).firstOrNull;
          final r = item == null ? null : room.item(item['type'].toString())?.readings.where((x) => x.key == s['reading']['key']).firstOrNull;
          return 'Record ${s['label'] ?? r?.label ?? 'a reading'} from the ${_labelOf(room, s['reading']['item']?.toString())}';
        }
        return instruction.isNotEmpty ? instruction : 'Record ${s['label'] ?? 'a value'}';
      default:
        if (instruction.isNotEmpty) return instruction;
        final target = _equipment.where((x) => x['id'] == s['target']).firstOrNull;
        final item = target == null ? null : room.item(target['type'].toString());
        final a = item?.actions.where((x) => x.key == s['action']).firstOrNull;
        if (a == null) return '${s['intent'] ?? 'Use'} the ${_labelOf(room, s['target']?.toString())}';
        return _fillText(a, s, room);
    }
  }

  String _fillText(LabKitAction a, Map<String, dynamic> s, LabKitRoom room) => a.text
      .replaceAll('{label}', _labelOf(room, s['target']?.toString()))
      .replaceAll('{intoLabel}', _labelOf(room, s['into']?.toString()))
      .replaceAll('{v}', '${s['command'] ?? s['value'] ?? ''}')
      .replaceAll('{n}', '${s['count'] ?? a.count?.defaultValue ?? ''}');
}

// ─── Equipment card ────────────────────────────────────────────────────────────

class _EquipmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final LabKitItem item;
  final int usedInSteps;
  final VoidCallback onChanged, onRemove;
  const _EquipmentCard({super.key, required this.data, required this.item, required this.usedInSteps, required this.onChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final init = data['init'] as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_iconFor(item.category)),
            const SizedBox(width: 10),
            Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800))),
            if (usedInSteps > 0) Text('in $usedInSteps ${usedInSteps == 1 ? 'step' : 'steps'}', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
            IconButton(onPressed: onRemove, icon: const Icon(Icons.close_rounded), tooltip: 'Remove'),
          ]),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Wrap(spacing: 12, runSpacing: 10, children: [
              SizedBox(
                width: 220,
                child: TextFormField(
                  initialValue: (data['label'] ?? '').toString(),
                  maxLength: 60,
                  decoration: InputDecoration(labelText: 'Name / label (optional)', hintText: item.shortTitle, isDense: true, counterText: ''),
                  onChanged: (v) {
                    data['label'] = v;
                    onChanged();
                  },
                ),
              ),
              for (final p in item.params)
                SizedBox(
                  width: p.type == 'select' ? 260 : 160,
                  child: switch (p.type) {
                    'select' => DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: p.options.any((o) => o.value == init[p.key]?.toString()) ? init[p.key].toString() : p.defaultValue?.toString(),
                        decoration: InputDecoration(labelText: p.label, isDense: true),
                        items: [for (final o in p.options) DropdownMenuItem(value: o.value, child: Text(o.label, overflow: TextOverflow.ellipsis))],
                        onChanged: (v) {
                          init[p.key] = v;
                          onChanged();
                        },
                      ),
                    'number' => TextFormField(
                        initialValue: '${init[p.key] ?? p.defaultValue ?? ''}',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: p.label, suffixText: p.unit, helperText: '${_fmt(p.min)}–${_fmt(p.max)}', isDense: true),
                        onChanged: (v) {
                          final n = num.tryParse(v.replaceAll(',', '.'));
                          if (n != null) init[p.key] = n;
                          onChanged();
                        },
                      ),
                    _ => TextFormField(
                        initialValue: '${init[p.key] ?? p.defaultValue ?? ''}',
                        decoration: InputDecoration(labelText: p.label, isDense: true),
                        onChanged: (v) {
                          init[p.key] = v;
                          onChanged();
                        },
                      ),
                  },
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Step editor ───────────────────────────────────────────────────────────────

class _StepEditor extends StatefulWidget {
  final Map<String, dynamic> step;
  final LabKitRoom room;
  final List<Map<String, dynamic>> equipment;
  final List<({String key, String label})> earlierRecords;
  final String Function(String? id) labelOf;
  const _StepEditor({required this.step, required this.room, required this.equipment, required this.earlierRecords, required this.labelOf});

  @override
  State<_StepEditor> createState() => _StepEditorState();
}

class _StepEditorState extends State<_StepEditor> {
  late final Map<String, dynamic> s = widget.step;
  String? _error;

  String get kind => (s['kind'] ?? 'action').toString();
  Map<String, dynamic>? get _target => widget.equipment.where((e) => e['id'] == s['target']).firstOrNull;
  LabKitItem? get _targetItem => _target == null ? null : widget.room.item(_target!['type'].toString());
  LabKitAction? get _action => _targetItem?.actions.where((a) => a.key == s['action']).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(_kindLabel(kind), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            ...switch (kind) {
              'action' => _actionFields(),
              'measure' => _measureFields(),
              'calc' => _calcFields(),
              'checkpoint' => _questionFields(),
              _ => <Widget>[],
            },
            if (kind != 'checkpoint') ...[
              const SizedBox(height: 12),
              _text('instruction', kind == 'info' ? 'What should you observe or note?' : 'Instruction shown in the lab (optional — leave empty for an automatic one)', lines: 2, max: 400),
            ],
            if (kind == 'action' || kind == 'measure' || kind == 'calc') ...[
              const SizedBox(height: 12),
              _text('hint', 'Hint if you get stuck (optional)', max: 300),
            ],
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
            const SizedBox(height: 16),
            FilledButton(onPressed: _done, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Done')),
          ]),
        ),
      ),
    );
  }

  Widget _text(String key, String label, {int lines = 1, int max = 200, String? hint}) => TextFormField(
        initialValue: (s[key] ?? '').toString(),
        minLines: lines,
        maxLines: lines + 2,
        maxLength: max,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
        onChanged: (v) => s[key] = v,
      );

  Widget _dropdown<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) => DropdownButtonFormField<T>(
        isExpanded: true,
        initialValue: items.any((i) => i.value == value) ? value : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items,
        onChanged: (v) => setState(() => onChanged(v)),
      );

  List<Widget> _actionFields() {
    final item = _targetItem;
    final action = _action;
    final raw = s['action'] == null && s['intent'] != null; // AI draft / remix step not from the kit
    return [
      _dropdown<String>(
        label: 'Equipment',
        value: s['target']?.toString(),
        items: [for (final e in widget.equipment) DropdownMenuItem(value: e['id'].toString(), child: Text(widget.labelOf(e['id'].toString())))],
        onChanged: (v) {
          s['target'] = v;
          s.remove('action');
          s.remove('intent');
          s.remove('until');
          s.remove('into');
        },
      ),
      const SizedBox(height: 12),
      if (raw)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
          child: Text('Custom action: ${s['intent']}${s['until'] != null ? ' (until ${s['until']})' : ''}. Choose an action below to replace it.'),
        ),
      if (raw) const SizedBox(height: 12),
      if (item != null)
        _dropdown<String>(
          label: 'What to do',
          value: s['action']?.toString(),
          items: [for (final a in item.actions) DropdownMenuItem(value: a.key, child: Text(a.label))],
          onChanged: (v) {
            s['action'] = v;
            s.remove('intent');
            s.remove('until');
            final a = item.actions.where((x) => x.key == v).firstOrNull;
            if (a?.value != null) s['value'] = a!.value!.defaultValue;
            if (a?.count != null) s['count'] = a!.count!.defaultValue;
            if (a != null && a.choices.isNotEmpty) s['command'] = a.choices.first;
          },
        ),
      if (action != null && action.into.isNotEmpty) ...[
        const SizedBox(height: 12),
        _dropdown<String>(
          label: action.intent == 'Pour'
              ? 'Into'
              : action.intent == 'Connect'
                  ? 'Connect to'
                  : 'Onto',
          value: s['into']?.toString(),
          items: [
            for (final e in widget.equipment)
              if (action.into.contains(e['type']) && e['id'] != s['target']) DropdownMenuItem(value: e['id'].toString(), child: Text(widget.labelOf(e['id'].toString()))),
          ],
          onChanged: (v) => s['into'] = v,
        ),
        if (!widget.equipment.any((e) => action.into.contains(e['type'])))
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Add a ${action.into.join(' or ').replaceAll('_', ' ')} to your equipment first.', style: TextStyle(color: Theme.of(context).colorScheme.error))),
      ],
      if (action?.value != null) ...[const SizedBox(height: 12), _valueSlider(action!.value!, 'value')],
      if (action?.count != null) ...[const SizedBox(height: 12), _valueSlider(action!.count!, 'count')],
      if (action != null && action.choices.isNotEmpty) ...[
        const SizedBox(height: 12),
        _dropdown<String>(label: 'Objective', value: s['command']?.toString(), items: [for (final c in action.choices) DropdownMenuItem(value: c, child: Text(c))], onChanged: (v) => s['command'] = v),
      ],
      if (action?.command == true) ...[
        const SizedBox(height: 12),
        _text('command', item?.type == 'firewall' ? 'Rule or command (e.g. deny port 23)' : 'Command or line of code',
            max: 80, hint: item?.type == 'workstation' && widget.room.environment == 'CodingBench' ? 'print("Hello!")' : 'ping 192.168.1.1'),
        const SizedBox(height: 12),
        _text('output', 'Output / what happens (shown after it runs, optional)', lines: 2, max: 400),
      ],
      if (action?.needsModel == 'titr')
        const Padding(padding: EdgeInsets.only(top: 8), child: Text('Needs an acid in the conical flask and an alkali in the burette.', style: TextStyle(fontSize: 12))),
    ];
  }

  Widget _valueSlider(LabKitValue v, String key) {
    var max = v.max.toDouble();
    if (v.maxFrom != null && _target != null) max = ((_target!['init'] as Map)[v.maxFrom] as num?)?.toDouble() ?? max;
    final min = v.min.toDouble();
    final current = ((s[key] as num?)?.toDouble() ?? v.defaultValue.toDouble()).clamp(min, max);
    final divisions = v.step > 0 ? ((max - min) / v.step).round().clamp(1, 1000) : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${v.label}: ${_fmt(current)} ${v.unit}', style: const TextStyle(fontWeight: FontWeight.w700)),
      Slider(value: current, min: min, max: max, divisions: divisions, label: '${_fmt(current)} ${v.unit}', onChanged: (x) => setState(() => s[key] = double.parse(x.toStringAsFixed(3)))),
    ]);
  }

  List<Widget> _measureFields() {
    final options = <({String item, LabKitReading r})>[
      for (final e in widget.equipment)
        for (final r in widget.room.item(e['type'].toString())?.readings ?? const <LabKitReading>[]) (item: e['id'].toString(), r: r),
    ];
    final reading = s['reading'] is Map ? s['reading'] as Map : null;
    final current = reading == null ? null : '${reading['item']}|${reading['key']}';
    return [
      if (options.isEmpty && s['truth'] == null)
        const Text('None of your equipment shows a reading. Add a meter, stopwatch, burette, pendulum or microscope.')
      else if (s['truth'] != null && reading == null)
        Text('Reading from the AI draft: ${s['truth']}', style: const TextStyle(fontStyle: FontStyle.italic))
      else
        _dropdown<String>(
          label: 'What do you read?',
          value: current,
          items: [for (final o in options) DropdownMenuItem(value: '${o.item}|${o.r.key}', child: Text('${o.r.label} — ${widget.labelOf(o.item)}'))],
          onChanged: (v) {
            if (v == null) return;
            final parts = v.split('|');
            s['reading'] = {'item': parts[0], 'key': parts[1]};
            s.remove('truth');
            final r = options.firstWhere((o) => o.item == parts[0] && o.r.key == parts[1]).r;
            if ((s['label'] ?? '').toString().isEmpty) s['label'] = r.label.replaceAll(RegExp(r'\s*\(.*\)$'), '');
            s['unit'] = r.unit;
          },
        ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(flex: 3, child: _text('label', 'Name of the value (e.g. Current)', max: 120)),
        const SizedBox(width: 10),
        Expanded(flex: 1, child: _text('unit', 'Unit', max: 20)),
      ]),
    ];
  }

  List<Widget> _calcFields() {
    final recs = widget.earlierRecords;
    List<DropdownMenuItem<String>> operandItems() => [
          for (final r in recs) DropdownMenuItem(value: r.key, child: Text(r.label)),
          const DropdownMenuItem(value: '#', child: Text('A number…')),
        ];
    Widget operand(String key, String label) {
      final v = s[key];
      final isNum = v is num || (v is String && num.tryParse(v) != null) || v == '#';
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _dropdown<String>(label: label, value: isNum ? '#' : v?.toString(), items: operandItems(), onChanged: (x) => s[key] = x == '#' ? 1 : x),
        if (isNum)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextFormField(
              initialValue: v == '#' ? '' : '$v',
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Number', border: OutlineInputBorder()),
              onChanged: (x) => s[key] = num.tryParse(x.replaceAll(',', '.')) ?? 1,
            ),
          ),
      ]);
    }

    final tol = (s['tolerance'] as num?)?.toDouble() ?? 0.1;
    return [
      if (recs.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Tip: add "Take a reading" steps BEFORE this one, so you can calculate with your readings.')),
      Row(children: [
        Expanded(flex: 3, child: _text('label', 'Result name (e.g. Resistance)', max: 120)),
        const SizedBox(width: 10),
        Expanded(flex: 1, child: _text('unit', 'Unit', max: 20)),
      ]),
      const SizedBox(height: 4),
      operand('a', 'First value'),
      const SizedBox(height: 12),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: '+', label: Text('+')),
          ButtonSegment(value: '-', label: Text('−')),
          ButtonSegment(value: '*', label: Text('×')),
          ButtonSegment(value: '/', label: Text('÷')),
        ],
        selected: {(s['op'] ?? '/').toString()},
        onSelectionChanged: (v) => setState(() => s['op'] = v.first),
      ),
      const SizedBox(height: 12),
      operand('b', 'Second value'),
      const SizedBox(height: 12),
      _dropdown<double>(
        label: 'How exact must the answer be?',
        value: const [1.0, 0.1, 0.01, 0.001].contains(tol) ? tol : 0.1,
        items: const [
          DropdownMenuItem(value: 1.0, child: Text('Whole number (± 1)')),
          DropdownMenuItem(value: 0.1, child: Text('1 decimal place (± 0.1)')),
          DropdownMenuItem(value: 0.01, child: Text('2 decimal places (± 0.01)')),
          DropdownMenuItem(value: 0.001, child: Text('3 decimal places (± 0.001)')),
        ],
        onChanged: (v) => s['tolerance'] = v,
      ),
    ];
  }

  List<Widget> _questionFields() {
    final choices = (s['choices'] as List?)?.map((e) => e.toString()).toList() ?? ['', ''];
    s['choices'] = choices;
    s['answerIndex'] ??= 0;
    return [
      _text('prompt', 'Question', lines: 2, max: 400),
      const SizedBox(height: 8),
      const Text('Answers — tick the correct one', style: TextStyle(fontWeight: FontWeight.w700)),
      RadioGroup<int>(
        groupValue: s['answerIndex'] as int,
        onChanged: (v) => setState(() => s['answerIndex'] = v),
        child: Column(children: [
          for (var i = 0; i < choices.length; i++)
            Row(children: [
              Radio<int>(value: i),
              Expanded(
                child: TextFormField(
                  key: ValueKey('choice$i-${choices.length}'),
                  initialValue: choices[i],
                  maxLength: 200,
                  decoration: InputDecoration(hintText: 'Answer ${i + 1}', counterText: '', isDense: true),
                  onChanged: (v) => choices[i] = v,
                ),
              ),
              if (choices.length > 2)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() {
                    choices.removeAt(i);
                    final a = s['answerIndex'] as int;
                    if (a >= choices.length || a == i) s['answerIndex'] = 0;
                  }),
                ),
            ]),
        ]),
      ),
      if (choices.length < 6)
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => choices.add('')), icon: const Icon(Icons.add), label: const Text('Add answer'))),
      const SizedBox(height: 8),
      _text('explanation', 'Explanation shown after answering (optional)', lines: 2, max: 600),
    ];
  }

  void _done() {
    String? err;
    switch (kind) {
      case 'action':
        if (s['target'] == null) {
          err = 'Choose the equipment.';
        } else if (s['action'] == null && s['intent'] == null) {
          err = 'Choose what to do.';
        } else if ((_action?.into.isNotEmpty ?? false) && s['into'] == null) {
          err = 'Choose where it goes.';
        } else if (_action?.command == true && (s['command'] ?? '').toString().trim().isEmpty) {
          err = 'Write the command.';
        }
      case 'measure':
        if (s['reading'] == null && s['truth'] == null) err = 'Choose what you read.';
        if ((s['label'] ?? '').toString().trim().isEmpty) err ??= 'Name the value.';
      case 'calc':
        if ((s['label'] ?? '').toString().trim().isEmpty) err = 'Name the result.';
        if (s['a'] == null || s['b'] == null) err ??= 'Choose both values.';
        s['op'] ??= '/';
      case 'info':
        if ((s['instruction'] ?? '').toString().trim().isEmpty) err = 'Write what to observe.';
      case 'checkpoint':
        final choices = (s['choices'] as List).map((e) => e.toString().trim()).toList();
        if ((s['prompt'] ?? '').toString().trim().isEmpty) err = 'Write the question.';
        if (choices.where((c) => c.isNotEmpty).length < 2) err ??= 'Write at least two answers.';
        if (err == null) {
          // Drop empty answers, keeping the right one ticked.
          final correct = choices[s['answerIndex'] as int];
          final kept = choices.where((c) => c.isNotEmpty).toList();
          s['choices'] = kept;
          s['answerIndex'] = correct.isEmpty ? 0 : kept.indexOf(correct);
        }
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, s);
  }
}

// ─── Small pieces ──────────────────────────────────────────────────────────────

class _ProblemsBanner extends StatelessWidget {
  final List<String> problems;
  final VoidCallback onClose;
  const _ProblemsBanner({required this.problems, required this.onClose});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withValues(alpha: 0.4))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.build_circle_outlined, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('A few things to fix:', style: TextStyle(fontWeight: FontWeight.w800)),
                for (final p in problems) Text('• $p'),
              ]),
            ),
          ),
        ),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 18)),
      ]),
    );
  }
}

class _Tips extends StatelessWidget {
  final List<String> tips;
  const _Tips({required this.tips});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFCD34D).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.tips_and_updates_rounded, color: Color(0xFFF59E0B)), SizedBox(width: 8), Text('Tips', style: TextStyle(fontWeight: FontWeight.w800))]),
          const SizedBox(height: 6),
          for (final t in tips) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $t')),
        ]),
      );
}

String _fmt(num? v) {
  if (v == null) return '';
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(v.abs() < 1 ? 2 : 1);
}

IconData _iconFor(String category) => switch (category) {
      'ppe' => Icons.health_and_safety_rounded,
      'glassware' => Icons.science_rounded,
      'reagent' => Icons.water_drop_rounded,
      'electrical' => Icons.electrical_services_rounded,
      'mechanics' => Icons.av_timer_rounded,
      'instrument' => Icons.straighten_rounded,
      'optics' => Icons.biotech_rounded,
      'biology' => Icons.crop_portrait_rounded,
      'heat' => Icons.local_fire_department_rounded,
      'computer' => Icons.computer_rounded,
      'network' => Icons.lan_rounded,
      'display' => Icons.tv_rounded,
      _ => Icons.category_rounded,
    };

String _kindLabel(String? k) => switch (k) {
      'measure' => 'Take a reading',
      'calc' => 'Calculate',
      'info' => 'Observe / note',
      'checkpoint' => 'Question',
      _ => 'Do an action',
    };

(IconData, Color) _kindStyle(String? k) => switch (k) {
      'measure' => (Icons.speed_rounded, const Color(0xFF3B82F6)),
      'calc' => (Icons.calculate_rounded, const Color(0xFF8B5CF6)),
      'info' => (Icons.visibility_rounded, const Color(0xFF64748B)),
      'checkpoint' => (Icons.quiz_rounded, const Color(0xFFF59E0B)),
      _ => (Icons.pan_tool_alt_rounded, const Color(0xFF10B981)),
    };
