import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api/eexams_service.dart';

final eexamsServiceProvider = Provider<EexamsService>((ref) => EexamsService());

/// The student's eexams.net results and link status (empty when unavailable).
final eexamsOverviewProvider = FutureProvider.autoDispose<EexamsOverview>((ref) async {
  try {
    return await ref.watch(eexamsServiceProvider).overview();
  } catch (_) {
    return EexamsOverview.empty;
  }
});
