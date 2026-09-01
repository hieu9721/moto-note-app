// lib/ui/backup/restore_sheet.dart — BKP-08. The ONE restore surface the
// whole phase shares, per P5-D-03: it derives its own mode from the
// presence of local data (read from `appProvider`) rather than a flag any
// caller passes, so the sign-in, the metadata read, the photo warning and
// the overwrite path are structurally incapable of drifting apart between
// entry points — the same discipline
// `lib/ui/widgets/odometer_confirm_dialog.dart` established for the
// P3-D-12 confirmation (03-07/CR-01 precedent).
//
// This plan (05-03) implements the no-local-data branch only (§7.6 Layer
// 1). The comparison branch — Layer 2's side-by-side comparison and Layer
// 3's pre-restore snapshot — is 05-04's job; it is a single, clearly-marked
// unimplemented arm below, not a partial comparison that would render
// something plausible but unprotected.
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backup/drive_service.dart';
import '../../backup/google_auth.dart';
import '../../data/migrations.dart';
import '../../state/app_state.dart';
import '../widgets/formatters.dart';

/// Opens the restore sheet. Copies `odo_sheet.dart:37-48`'s call shape
/// verbatim — `isScrollControlled: true` and `useSafeArea: true` are the
/// house pattern for every modal sheet in this codebase, not incidental to
/// the ODO sheet. Takes no mode argument: [RestoreSheetBody] reads
/// `appProvider` itself to decide which mode to render (P5-D-03).
Future<void> showRestoreSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const RestoreSheetBody(),
  );
}

enum _Stage {
  /// Nothing has happened yet — one primary action starts sign-in.
  idle,

  /// Signed in, `peek()` returned null — no backup exists in this account.
  /// The normal first-install state, never an error.
  noBackupFound,

  /// Signed in, `peek()` returned a [BackupInfo] — the summary form and the
  /// two actions render.
  summary,
}

class RestoreSheetBody extends ConsumerStatefulWidget {
  const RestoreSheetBody({super.key});

  @override
  ConsumerState<RestoreSheetBody> createState() => _RestoreSheetBodyState();
}

class _RestoreSheetBodyState extends ConsumerState<RestoreSheetBody> {
  _Stage _stage = _Stage.idle;
  bool _working = false;
  String? _error;
  BackupInfo? _info;

  // Built once per successful peek() and reused for download() — a fresh
  // DriveService per attempt, never cached beyond this sheet's own
  // lifetime, mirroring `backup_service.dart`'s "fresh DriveService every
  // cycle" rule (RESEARCH Pitfall 4).
  DriveService? _driveService;

  /// Step 2 (sign in) + step 3 (peek) — one gesture handler covers both,
  /// since neither is useful without the other and only one loading state
  /// needs to render between them.
  Future<void> _signIn() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final authService = ref.read(googleAuthServiceProvider);
      final result = await authService.signInAndAuthorize();
      // CLAUDE.md trap / RESEARCH Pitfall 10: BuildContext/State used after
      // an await. This sheet has more suspension points in one flow than
      // any prior phase's single path — every one of them is checked here.
      if (!mounted) return;
      if (result == null) {
        // A cancelled interactive sign-in is not an error — back to idle
        // silently, matching `_GoogleAccountRowState`'s identical rule in
        // settings_screen.dart.
        setState(() => _working = false);
        return;
      }
      final client = result.authorization.authClient(scopes: kDriveScopes);
      final driveService = DriveService(client);
      final info = await driveService.peek();
      if (!mounted) return;
      setState(() {
        _working = false;
        _driveService = driveService;
        if (info == null) {
          // BKP-05: a missing backup is the normal first-install state,
          // never an error and never a restore button the user could
          // press.
          _stage = _Stage.noBackupFound;
        } else {
          _info = info;
          _stage = _Stage.summary;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = _genericFailureMessage;
      });
    }
  }

  /// Step 6: download, then commit through the one whole-document replace
  /// (`AppNotifier.restoreFrom`), then dismiss. Step 7's three distinct
  /// failure cases (P5-D-22) all keep the sheet open with an inline error —
  /// nothing is written on any of them, matching `_mutate`'s own
  /// persist-before-assign/rethrow-on-failure contract that
  /// `odo_sheet.dart`'s `_save` already codifies for its own save path.
  Future<void> _restore() async {
    final driveService = _driveService;
    if (driveService == null) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final downloaded = await driveService.download();
      if (!mounted) return;
      await ref.read(appProvider.notifier).restoreFrom(downloaded);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on SchemaTooNewException catch (e) {
      // P1-D-09/P5-D-22: the typed found/supported fields exist on this
      // exception specifically so this screen can say this.
      if (!mounted) return;
      setState(() {
        _working = false;
        _error =
            'Bản sao lưu này được tạo bởi một phiên bản MotoNote mới hơn '
            '(schema ${e.found}, ứng dụng hiện chỉ hỗ trợ tới schema '
            '${e.supported}). Vui lòng cập nhật ứng dụng để khôi phục.';
      });
    } on FormatException catch (_) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = _damagedBackupMessage;
      });
    } on TypeError catch (_) {
      // A deserialisation type error — AppData.fromJson's generated code
      // throwing on a shape it did not expect. Same user-facing message as
      // FormatException above: both mean "the backup file is damaged", not
      // "the network failed" (P5-D-22).
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = _damagedBackupMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = _genericFailureMessage;
      });
    }
  }

  void _startOver() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // P5-D-03: the sheet derives its own mode from the presence of local
    // data, read here from `appProvider` — never from a flag a caller
    // passes, so no entry point (now or in a later phase) can ever open the
    // wrong mode.
    final hasLocalData = ref.watch(
      appProvider.select((d) => d.vehicles.isNotEmpty),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: hasLocalData
              ? _buildComparisonModePlaceholder(colorScheme)
              : _buildNoLocalDataFlow(colorScheme),
        ),
      ),
    );
  }

  /// This plan implements the no-local-data branch only (§7.6 Layer 1). The
  /// comparison branch — Layer 2's side-by-side comparison and Layer 3's
  /// pre-restore snapshot — is 05-04's job. A single, clearly-marked,
  /// unimplemented arm, not a partial comparison that would render
  /// something plausible but unprotected.
  List<Widget> _buildComparisonModePlaceholder(ColorScheme colorScheme) {
    return [
      Text(
        'Khôi phục khi máy đã có dữ liệu sẽ có ở bản cập nhật sau.',
        // [NEW, PROVISIONAL]
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
      ),
    ];
  }

  List<Widget> _buildNoLocalDataFlow(ColorScheme colorScheme) {
    final children = <Widget>[];

    switch (_stage) {
      case _Stage.idle:
        children.addAll([
          Text(
            _idleLine,
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _working ? null : _signIn,
            child: _working
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(_signInButtonLabel),
          ),
        ]);
      case _Stage.noBackupFound:
        children.addAll([
          Text(
            _noBackupLine,
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _startOver, child: const Text('Bắt đầu mới')),
        ]);
      case _Stage.summary:
        final info = _info!;
        final summaryLine =
            '${formatShortDate(info.modifiedAt.toLocal())} · '
            '${info.vehicleCount} xe · ${info.logCount} log · '
            '${(info.sizeBytes / 1024).round()}KB';
        children.addAll([
          Text(
            summaryLine,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // D-20: the photo exclusion is stated ON THIS SURFACE, verbatim —
          // not in an FAQ, not in a help screen — because the sentence
          // exists to change a decision at the moment it is being made.
          Text(
            '⚠ Ảnh hoá đơn không khôi phục được',
            style: TextStyle(fontSize: 14, color: colorScheme.error),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _working ? null : _startOver,
                  child: const Text('Bắt đầu mới'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _working ? null : _restore,
                  child: _working
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Khôi phục'),
                ),
              ),
            ],
          ),
        ]);
    }

    if (_error != null) {
      children.addAll([
        const SizedBox(height: 16),
        Text(_error!, style: TextStyle(fontSize: 14, color: colorScheme.error)),
      ]);
    }

    return children;
  }
}

// Invented Vietnamese strings for this plan — [NEW, PROVISIONAL], recorded
// verbatim in this plan's SUMMARY per its own <output> requirement.
const _idleLine =
    'Đăng nhập Google để tìm bản sao lưu MotoNote trên Drive của bạn.';
const _signInButtonLabel = 'Đăng nhập Google';
const _noBackupLine = 'Không tìm thấy bản sao lưu nào trong tài khoản này.';
const _genericFailureMessage =
    'Không thể kết nối tới Google Drive. Vui lòng thử lại.';
const _damagedBackupMessage =
    'Tệp sao lưu bị hỏng. Dữ liệu trên máy chưa bị thay đổi.';
