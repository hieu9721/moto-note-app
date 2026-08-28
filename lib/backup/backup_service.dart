// lib/backup/backup_service.dart — the backup seam `_mutate` calls on every
// mutation (P1-D-05). Real Google Sign-In, Drive upload, and debounce timing
// are Phase 5 (§7); this file only fixes the shape so `app_state.dart` never
// has to change when that implementation lands.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Schedules a debounced background backup after a mutation (§7.5). Real
/// implementations debounce for ~30s, then attempt a silent Drive upload
/// that never surfaces a dialog or a spinner (D-23).
abstract class BackupService {
  void scheduleDebounced();
}

/// Phase 1 placeholder, replaced by the real Google Drive-backed
/// implementation in Phase 5. Deliberately inert — no Google sign-in, no
/// Drive API call, no debounce timer belongs here yet.
class NoopBackupService implements BackupService {
  const NoopBackupService();

  @override
  void scheduleDebounced() {}
}

/// Provider name is verbatim from §5.2 so Phase 5 swaps only the
/// implementation behind it; `app_state.dart` never has to change.
final backupServiceProvider = Provider<BackupService>(
  (_) => const NoopBackupService(),
);
