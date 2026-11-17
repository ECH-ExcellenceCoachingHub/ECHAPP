import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../services/api/teacher_tools_service.dart';
import '../../../widgets/eexams_section.dart';

const kToolsPurple = Color(0xFF7C3AED);
const kToolsGreen = Color(0xFF10B981);

/// Shows any error from the teacher tools as a SnackBar.
void showToolError(BuildContext context, Object e) {
  final msg = e is TeacherToolsException ? e.message : 'Something went wrong. Please try again.';
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 6)));
}

void showToolMessage(BuildContext context, String msg) =>
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg)));

/// Lets the teacher pick a document (PDF/Word/TXT/PowerPoint) as bytes.
Future<PickedUpload?> pickDocument({List<String> extensions = const ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx']}) async {
  final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: extensions, withData: true);
  final f = result?.files.single;
  if (f == null || f.bytes == null) return null;
  if (f.bytes!.length > 50 * 1024 * 1024) throw TeacherToolsException('That file is larger than 50 MB.');
  return PickedUpload(f.name, f.bytes!);
}

/// "3 of 4 used this month" strip; red when the allowance is used up.
class QuotaBanner extends StatelessWidget {
  final PlannerQuota? quota;
  final String noun;
  const QuotaBanner({super.key, required this.quota, required this.noun});

  @override
  Widget build(BuildContext context) {
    final q = quota;
    if (q == null) return const SizedBox.shrink();
    final out = !q.allowed;
    final resets = q.periodEnd == null ? '' : ' Resets on ${q.periodEnd!.day}/${q.periodEnd!.month}.';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (out ? Colors.red : kToolsPurple).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (out ? Colors.red : kToolsPurple).withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(out ? Icons.block : Icons.auto_awesome, size: 18, color: out ? Colors.red : kToolsPurple),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            out ? 'You have used all ${q.limit} $noun for this month.$resets' : '${q.summary} ($noun).',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

/// Shown when the teacher's eexams account still needs to be connected.
class LinkRequiredCard extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const LinkRequiredCard({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.link, color: kToolsPurple),
            SizedBox(width: 8),
            Expanded(child: Text('Connect your eexams account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          ]),
          const SizedBox(height: 8),
          Text(message ?? 'An eexams account with your email already exists. Open eexams once and log in to connect it — after that these tools work automatically.',
              style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kToolsPurple, foregroundColor: Colors.white),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open eexams'),
              onPressed: () => openEexams(context, redirect: '/teacher'),
            ),
            OutlinedButton(onPressed: onRetry, child: const Text("I've connected it")),
          ]),
        ]),
      ),
    );
  }
}

/// Editable list of short lines (activities, bullets, MCQ options).
class LineListEditor extends StatelessWidget {
  final String label;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final String? hint;
  final String keyPrefix;
  const LineListEditor({super.key, required this.label, required this.items, required this.onChanged, this.hint, required this.keyPrefix});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[600], letterSpacing: 0.3)),
      const SizedBox(height: 6),
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('$keyPrefix-$i-${items.length}'),
                initialValue: items[i],
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(isDense: true, hintText: hint, border: const OutlineInputBorder()),
                onChanged: (v) {
                  final next = [...items];
                  next[i] = v;
                  onChanged(next);
                },
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => onChanged([...items]..removeAt(i)),
            ),
          ]),
        ),
      TextButton.icon(
        onPressed: () => onChanged([...items, '']),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add line'),
      ),
    ]);
  }
}

/// A text field bound to `map[key]` (rebuilt when [version] changes).
Widget mapField(
  Map<String, dynamic> map,
  String key,
  String label, {
  required String version,
  required VoidCallback onChanged,
  int maxLines = 1,
  String? hint,
  TextInputType? keyboard,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      key: ValueKey('$version-$key'),
      initialValue: (map[key] ?? '').toString(),
      minLines: 1,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, hintText: hint, isDense: true, border: const OutlineInputBorder()),
      onChanged: (v) {
        map[key] = v;
        onChanged();
      },
    ),
  );
}

/// Grid of short fields that wraps on phones.
class FieldGrid extends StatelessWidget {
  final List<Widget> children;
  const FieldGrid({super.key, required this.children});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 900 ? 4 : c.maxWidth > 560 ? 2 : 1;
      final w = (c.maxWidth - (cols - 1) * 10) / cols;
      return Wrap(spacing: 10, children: [for (final ch in children) SizedBox(width: w, child: ch)]);
    });
  }
}

/// Attached-book chip / attach button used by every planner tool.
class ReferenceAttach extends StatelessWidget {
  final String? fileName;
  final bool busy;
  final VoidCallback onAttach;
  final VoidCallback onClear;
  const ReferenceAttach({super.key, this.fileName, required this.busy, required this.onAttach, required this.onClear});

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 10), Text('Reading the document…')]),
      );
    }
    if (fileName != null) {
      return InputChip(avatar: const Icon(Icons.description, size: 18), label: Text(fileName!, overflow: TextOverflow.ellipsis), onDeleted: onClear);
    }
    return OutlinedButton.icon(
      onPressed: onAttach,
      icon: const Icon(Icons.attach_file, size: 18),
      label: const Text('Attach the book or notes (optional)'),
    );
  }
}
