import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../services/api/eexams_service.dart';
import '../providers/eexams_provider.dart';

/// Opens eexams.net signed in as the current ECH user, with error feedback.
/// Usable from any screen, e.g. `openEexams(context, redirect: '/marketplace')`.
/// Useful eexams paths: `/marketplace`, `/student/exams`, `/student/results`,
/// `/student/results/<resultId>`.
Future<void> openEexams(BuildContext context, {String redirect = '/'}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await EexamsService().open(redirect: redirect);
  } catch (e) {
    messenger?.showSnackBar(const SnackBar(content: Text('Could not open eexams. Please try again.')));
  }
}

/// Compact card: eexams stats, "Open eexams" and the synced results.
class EexamsSection extends ConsumerWidget {
  const EexamsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(eexamsOverviewProvider).valueOrNull ?? EexamsOverview.empty;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in_outlined, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('eexams practice exams', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => ref.invalidate(eexamsOverviewProvider),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              overview.examsTaken == 0
                  ? 'Practise national-exam style papers on eexams. You are signed in automatically and your results appear here.'
                  : '${overview.examsTaken} exam${overview.examsTaken == 1 ? '' : 's'} taken'
                      '${overview.averagePercentage != null ? ' · average ${overview.averagePercentage}%' : ''}'
                      '${overview.bestPercentage != null ? ' · best ${overview.bestPercentage}%' : ''}',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open eexams'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  onPressed: () => openEexams(context, redirect: '/student/exams'),
                ),
                if (overview.results.isNotEmpty)
                  OutlinedButton(
                    onPressed: () => _showResults(context, overview),
                    child: Text('My eexams results (${overview.examsTaken})'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResults(BuildContext context, EexamsOverview overview) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(child: Text('eexams results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetContext)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: overview.results.length,
                itemBuilder: (_, i) => _ResultTile(result: overview.results[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final EexamsResult result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.passed == false ? Colors.orange : Colors.green;
    final d = result.completedAt;
    final date = d == null ? '' : '${d.day}/${d.month}/${d.year}';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(result.examTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (result.level != null) result.level!,
          '${_fmt(result.score)}/${_fmt(result.maxScore)} points',
          if (date.isNotEmpty) date,
        ].join(' · ')),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${_fmt(result.percentage)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            if (result.passed != null)
              Text(result.passed! ? 'Passed' : 'Not yet', style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
        onTap: result.reviewPath == null ? null : () => openEexams(context, redirect: result.reviewPath!),
      ),
    );
  }

  static String _fmt(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
}
