import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/lab_scenario.dart';
import '../../services/api/lab_service.dart';

final labServiceProvider = Provider<LabService>((ref) => LabService());

/// Published labs (all subjects). Filtering is done client-side so switching chips is instant.
final labScenariosProvider = FutureProvider<List<LabScenario>>((ref) => ref.watch(labServiceProvider).listScenarios());

/// Student's XP, level, badges and labs to continue.
final labSummaryProvider = FutureProvider<LabSummary>((ref) async {
  try {
    return await ref.watch(labServiceProvider).summary();
  } catch (_) {
    return LabSummary.empty;
  }
});

final labScenarioProvider = FutureProvider.family<LabScenario, String>((ref, id) => ref.watch(labServiceProvider).getScenario(id));
