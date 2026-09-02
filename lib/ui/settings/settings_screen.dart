// lib/ui/settings/settings_screen.dart — P3-D-13's four-group layout stays;
// 04-03 (NOTIF-02/03/05) activates the Thông báo group's four rows plus the
// exact-alarm opt-in and, when it applies, the tappable soft-prompt line
// (P4-D-07/P4-D-08). Backup is BKP-*, export is BKP-*, interval/vehicle/item
// management is SET-*, none of them this phase's job (D-34's
// anti-scope-creep) — those three groups' rows, titles and captions stay
// exactly as Phase 3 shipped them.
//
// Converting `SettingsScreen` from `StatelessWidget` to `ConsumerWidget` is
// what "activating" actually requires (04-PATTERNS.md Mismatch 2) — the
// layout does not change, the base class does. Every activated write routes
// through `AppNotifier.updateSettings`, which goes through `_mutate` and
// therefore reschedules on save with no extra wiring (P1-D-05/P1-D-06).
import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backup/backup_service.dart';
import '../../backup/google_auth.dart';
import '../../backup/local_export.dart';
import '../../domain/backup_timing.dart';
import '../../domain/catalog.dart';
import '../../domain/models/app_data.dart';
import '../../notifications/notification_service.dart';
import '../../state/app_state.dart';
import '../../state/derived.dart';
import '../backup/restore_sheet.dart';
import '../notifications/battery_hint_sheet.dart';
import 'delete_all_data_dialog.dart';

/// Bounded set of day counts for "Số ngày báo trước" (T-04-15) — a fixed
/// picker rather than free text, so an out-of-range value can never reach
/// `Settings.leadDays`, which feeds `_notifyDatesFor`'s first candidate
/// directly.
const _leadDaysOptions = [1, 3, 5, 7, 10, 14, 21, 30];

/// Bounded set of days-of-month for "Ngày nhắc cập nhật số km" (SET-02) —
/// every day from 1 to 28 inclusive, so an out-of-range value can never
/// reach `Settings.odoReminderDayOfMonth`. 28 is the ceiling, not 30/31:
/// the field picks a day-of-month for a MONTHLY reminder
/// (`notification_plan.dart`'s `_nthMonthDay`), and 29–31 do not exist in
/// every month. The model's own `// 1–28` comment on the field already
/// pins this range; this list is what makes that comment true by
/// construction rather than merely documented.
const _odoReminderDayOfMonthOptions = [
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
  23,
  24,
  25,
  26,
  27,
  28,
];

// [NEW, PROVISIONAL] — the same fixed-message-on-catch-all shape
// `_RestoreSheetBodyState._signIn`'s `_genericFailureMessage` already uses,
// applied to the two Google auth call sites in this file that previously had
// no try/catch at all (CR-02, 05-VERIFICATION.md gap #2). Neither string
// interpolates the caught object — the raw exception must never reach a
// user-facing SnackBar (P5-D-16).
const _googleSignInFailureMessage =
    'Không thể kết nối tới Google. Vui lòng thử lại.';
const _googleSignOutFailureMessage =
    'Không thể đăng xuất khỏi Google. Vui lòng thử lại.';

// [NEW, PROVISIONAL] — CR-03: the "Xuất file" failure SnackBar used to
// interpolate the raw caught exception, which can carry absolute file
// paths (OS user name + the app's private directory). This is the same
// fixed-message discipline as the two consts above, applied to the export
// row.
const _exportFailureMessage = 'Xuất file thất bại. Vui lòng thử lại.';
// [NEW, PROVISIONAL] — WR-02: a failed undo mutation used to be silently
// swallowed. The claim below is true by construction — see the comment at
// its use site in `_onUndoTap`.
const _undoFailureMessage =
    'Không hoàn tác được. Dữ liệu trên máy chưa bị thay đổi.';

// 06-09 (REL-04): the published privacy-policy URL, and the ONE place its
// string literal appears in this file (task 1 acceptance criterion). Every
// other reference — `06-STORE-LISTING.md`'s listing field, the OAuth
// consent-screen entry — must match this string byte for byte, so a diff
// against this constant is how those documents are checked, not a second
// hardcoded copy in this file.
//
// Derived from `git remote -v`'s origin
// (`https://github.com/hieu9721/moto-note-app.git`) per the plan's own
// instruction not to guess the hostname: GitHub user `hieu9721`, repo
// `moto-note-app`, so the Pages URL is
// `https://hieu9721.github.io/moto-note-app/<path>`. `docs/privacy-policy.md`
// carries an explicit `permalink: /privacy-policy` in its own front matter
// (not the Jekyll default `/privacy-policy.html`), which is what makes this
// exact path — no `.html` suffix — the one GitHub Pages actually serves once
// Pages is enabled with source = default branch, folder = /docs.
const _privacyPolicyUrl =
    'https://hieu9721.github.io/moto-note-app/privacy-policy';

// [NEW, PROVISIONAL] — same fixed-message-on-catch-all shape as
// `_googleSignInFailureMessage` above, applied to the privacy-policy link's
// Android view intent. A launch failure here (no browser/app registered to
// handle a view intent) is a real, if rare, possibility on a stripped-down
// ROM — unlike `openBatterySettings()` in `lib/notifications/battery_hints.dart`,
// which deliberately lets a launch failure surface unhandled because it is
// itself the terminal action of its own sheet, this row sits inside the
// ordinary Settings list, where CR-02/CR-03's established discipline (never
// interpolate a caught exception into user-facing copy) already governs
// every other tappable row.
const _privacyPolicyLaunchFailureMessage =
    'Không thể mở chính sách quyền riêng tư. Vui lòng thử lại.';

/// Live OS check backing the exact-alarm row's displayed state — never the
/// stored flag alone, since the user can revoke the permission from system
/// settings at any time without the app hearing about it (T-04-13).
final _canScheduleExactProvider = FutureProvider.autoDispose<bool>(
  (ref) =>
      ref.watch(notificationSchedulerProvider).canScheduleExactNotifications(),
);

/// Live OS check backing the soft-prompt line's visibility (P4-D-08) —
/// never the stored `notificationPermissionAsked` intent, which only
/// records that the app asked, not what the OS currently allows.
final _notificationsEnabledProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(notificationSchedulerProvider).areNotificationsEnabled(),
);

/// Backs the "Hoàn tác khôi phục" row's visibility (P5-D-05) — the pre-
/// restore snapshot file's own modification time, or null when no snapshot
/// exists. Same `FutureProvider.autoDispose` idiom as
/// [_canScheduleExactProvider] above; the row
/// invalidates this itself after a successful (or failed-but-terminal)
/// undo so the row's visibility reflects the file on disk, never a value
/// captured once at first build.
final _preRestoreSnapshotModifiedAtProvider =
    FutureProvider.autoDispose<DateTime?>(
      (ref) => ref.watch(repositoryProvider).preRestoreSnapshotModifiedAt(),
    );

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appProvider.select((d) => d.settings));
    final notifier = ref.read(appProvider.notifier);
    // The house secondary-text colour (T-03-30: no new literal colour
    // constants) — same source as odo_sheet.dart/item_detail_screen.dart's
    // caption text.
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    // 06-05 (SET-01): the two live "Quản lý xe/hạng mục" rows below read
    // these — vehicle count/current vehicle for the first row, and the
    // enabled-count over the selected vehicle's applicable catalog count
    // for the second. `selectedVehicle` can only be null for the one frame
    // between a vehicle deletion and the router's redirect away from
    // Settings (06-01's resolver, same defensive gap `home_screen.dart`
    // already documents), so every fallback below is empty/zero, never a
    // crash.
    final vehicles = ref.watch(appProvider.select((d) => d.vehicles));
    final selectedVehicle = ref.watch(selectedVehicleProvider);
    final currentVehicleName = selectedVehicle == null
        ? ''
        : (selectedVehicle.name.isEmpty ? 'Xe của bạn' : selectedVehicle.name);
    final enabledItemCount = selectedVehicle == null
        ? 0
        : ref
              .watch(appProvider.select((d) => d.items))
              .where((i) => i.vehicleId == selectedVehicle.id && i.enabled)
              .length;
    final applicableCatalogCount = selectedVehicle == null
        ? 0
        : catalogFor(selectedVehicle.type).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: ListView(
          children: [
            _SettingsGroup(
              // Phase 4 (NOTIF-*) owns these rows.
              title: 'Thông báo',
              showComingSoonCaption: false,
              rows: [
                SwitchListTile(
                  title: const Text('Nhắc bảo dưỡng'),
                  value: settings.notificationsEnabled,
                  onChanged: (v) => notifier.updateSettings(
                    (s) => s.copyWith(notificationsEnabled: v),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Nhắc cập nhật số km'),
                  value: settings.odoReminderEnabled,
                  onChanged: (v) => notifier.updateSettings(
                    (s) => s.copyWith(odoReminderEnabled: v),
                  ),
                ),
                // SET-02: the fifth and last Settings field declared for
                // this requirement — `odoReminderDayOfMonth` already had a
                // model default and a live consumer in
                // `notification_plan.dart` (only reached inside the
                // `odoReminderEnabled` branch above), but no UI row until
                // now (WINDOWS.md entry 5). Same "bounded ListTile + dialog
                // picker" shape as "Số ngày báo trước" below, not a
                // free-text field, so the model's `// 1–28` comment stays
                // true by construction.
                ListTile(
                  title: const Text('Ngày nhắc cập nhật số km'),
                  trailing: Text(
                    'Ngày ${settings.odoReminderDayOfMonth} hàng tháng',
                  ),
                  onTap: () async {
                    final picked = await showDialog<int>(
                      context: context,
                      builder: (ctx) => SimpleDialog(
                        title: const Text('Ngày nhắc cập nhật số km'),
                        children: [
                          RadioGroup<int>(
                            groupValue: settings.odoReminderDayOfMonth,
                            onChanged: (v) => Navigator.of(ctx).pop(v),
                            child: Column(
                              children: [
                                for (final d in _odoReminderDayOfMonthOptions)
                                  RadioListTile<int>(
                                    title: Text('Ngày $d'),
                                    value: d,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                    if (picked == null) return;
                    if (!context.mounted) return;
                    // Bounded by construction
                    // (_odoReminderDayOfMonthOptions) — never an
                    // out-of-range value reaches Settings (T-04-15's same
                    // discipline, applied to the model's `// 1–28` range).
                    await notifier.updateSettings(
                      (s) => s.copyWith(odoReminderDayOfMonth: picked),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Giờ nhắc'),
                  trailing: Text(
                    '${settings.notifyHour.toString().padLeft(2, '0')}:00',
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: settings.notifyHour,
                        minute: 0,
                      ),
                    );
                    if (picked == null) return;
                    if (!context.mounted) return;
                    // The model stores an hour, not a minute — the picked
                    // minute is deliberately discarded, never silently
                    // widening what Settings persists.
                    await notifier.updateSettings(
                      (s) => s.copyWith(notifyHour: picked.hour),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Số ngày báo trước'),
                  trailing: Text('${settings.leadDays} ngày'),
                  onTap: () async {
                    final picked = await showDialog<int>(
                      context: context,
                      builder: (ctx) => SimpleDialog(
                        title: const Text('Số ngày báo trước'),
                        children: [
                          RadioGroup<int>(
                            groupValue: settings.leadDays,
                            onChanged: (v) => Navigator.of(ctx).pop(v),
                            child: Column(
                              children: [
                                for (final d in _leadDaysOptions)
                                  RadioListTile<int>(
                                    title: Text('$d ngày'),
                                    value: d,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                    if (picked == null) return;
                    if (!context.mounted) return;
                    // Bounded by construction (_leadDaysOptions) — never an
                    // out-of-range value reaches Settings (T-04-15).
                    await notifier.updateSettings(
                      (s) => s.copyWith(leadDays: picked),
                    );
                  },
                ),
                const _ExactAlarmRow(),
                ListTile(
                  // [NEW, PROVISIONAL] — opens the battery-guidance sheet
                  // (P4-D-09: one implementation, two entry points).
                  title: const Text('Thông báo không tới?'),
                  subtitle: const Text(
                    'Cách để máy không chặn thông báo của app.',
                  ),
                  onTap: () => showBatteryHintSheet(context),
                ),
                const _NotificationSoftPromptRow(),
              ],
            ),
            _SettingsGroup(
              // Phase 5 (BKP-*) owns sign-in and the backup rows. Live as
              // of 05-01 — the caption below would read as actively
              // misleading under working rows (T-04-14).
              title: 'Sao lưu Drive',
              showComingSoonCaption: false,
              rows: [
                const _GoogleAccountRow(),
                SwitchListTile(
                  title: const Text('Tự động sao lưu'),
                  value: settings.driveBackupEnabled,
                  onChanged: (v) async {
                    if (!v) {
                      await notifier.updateSettings(
                        (s) => s.copyWith(driveBackupEnabled: false),
                      );
                      return;
                    }
                    // Turning ON must end with `drive.appdata` actually
                    // AUTHORIZED — not merely with an account present.
                    // Gating this on "is someone signed in?" was the
                    // original defect (G-05-2): authentication says nothing
                    // about whether the scope was granted, so once silent
                    // authentication started succeeding the handler enabled
                    // backup without ever requesting the scope, and the
                    // first upload could only fail into the one-line
                    // `· Có lỗi` state — the exact silent failure BKP-04
                    // exists to make visible.
                    //
                    // One path now covers both cases, in the same
                    // silent-then-interactive order `BackupService.runManual`
                    // already uses: `silentAuthorization()` returns non-null
                    // only when the scope is already granted (no UI at all),
                    // and otherwise `signInAndAuthorize()` runs the
                    // interactive authenticate + `authorizeScopes` from this
                    // gesture handler, which is where the platform requires
                    // it. On cancellation, leave the switch off and write
                    // nothing.
                    try {
                      final auth = ref.read(googleAuthServiceProvider);
                      var result = await auth.silentAuthorization();
                      result ??= await auth.signInAndAuthorize();
                      if (!context.mounted) return;
                      if (result == null) {
                        return; // cancelled — write nothing
                      }
                      await notifier.updateSettings(
                        (s) => s.copyWith(
                          driveBackupEnabled: true,
                          googleEmail: result!.email,
                        ),
                      );
                    } catch (_) {
                      // CR-02: a config/SHA-1 mismatch must not strand the
                      // switch mid-flight. Nothing is written on this path
                      // — driveBackupEnabled stays false, so the switch
                      // renders itself back to off from appProvider with
                      // no manual state fiddling here.
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(_googleSignInFailureMessage),
                        ),
                      );
                    }
                  },
                ),
                // This one line is the entire visible surface of automatic
                // backup (D-23) — everything else about an automatic
                // backup is silent by requirement, and a future
                // contributor reaching for a toast/spinner here should
                // find the reason it is not there.
                _BackupStatusRow(
                  lastBackupAt: settings.lastBackupAt,
                  lastBackupError: settings.lastBackupError,
                ),
                ListTile(
                  title: const Text('Sao lưu ngay'),
                  onTap: () async {
                    final outcome = await ref
                        .read(backupServiceProvider)
                        .runManual();
                    if (!context.mounted) return;
                    if (outcome.succeeded || outcome.code != null) {
                      // WR-01: route the result through the single
                      // documented Settings writer below instead of
                      // hand-rolling the write here — its own doc comment
                      // already claims to be the only writer of
                      // lastBackupAt/lastBackupError. The pause MUST run
                      // first, exactly as RealBackupService._recordResult
                      // orders it: the write below goes through _mutate,
                      // whose unconditional post-persist call is
                      // scheduleDebounced(), and without the armed
                      // one-shot that schedules a fresh upload of the
                      // document that was just uploaded (P5-D-19).
                      ref
                          .read(backupServiceProvider)
                          .pauseNextAutomaticBackup();
                      await notifier.recordBackupResult(outcome);
                      if (!context.mounted) return;
                    }
                    if (outcome.succeeded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          // [NEW, PROVISIONAL]
                          content: Text('Đã sao lưu thành công'),
                        ),
                      );
                    } else if (outcome.code != null) {
                      // BKP-07: the manual button reports its result
                      // clearly — the deliberate opposite of the automatic
                      // path's silence (D-23). Do not "fix" this into
                      // silence.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(kBackupErrorMessages[outcome.code]!),
                        ),
                      );
                    }
                    // outcome.code == null && !succeeded: the user
                    // cancelled the interactive sign-in, or a run was
                    // already in flight — neither is a failure, so nothing
                    // is persisted and nothing is reported.
                  },
                ),
                // §7.6 Layer 1: the third and only entry point into the
                // restore sheet that is reachable with data already on the
                // device — a deliberate, separately-confirmed trip into
                // Settings, never gated on sign-in (P5-D-02): the sheet
                // handles sign-in itself, and hiding this row while signed
                // out would leave a signed-out user with no visible route
                // to their own backup.
                ListTile(
                  title: const Text('Khôi phục từ Google Drive'),
                  // [NEW, PROVISIONAL] — states plainly, before the tap,
                  // that the sheet behind this row is about replacement,
                  // not about merging.
                  subtitle: const Text(
                    'Sẽ thay thế toàn bộ dữ liệu hiện có trên máy.',
                  ),
                  // G-05-4: a successful restore WRITES the 7-day
                  // pre-restore snapshot, but nothing told the row below
                  // that the file now exists, so `Hoàn tác khôi phục` did
                  // not appear until the app was restarted — the one
                  // moment a user who restored by mistake goes looking for
                  // it. `_preRestoreSnapshotModifiedAtProvider` is keyed on
                  // that file's mtime and already documents being
                  // invalidated after an undo; a restore is the event that
                  // CREATES the snapshot and needs the same treatment.
                  // Invalidating unconditionally on dismissal is correct
                  // and cheap: the provider re-reads the file, so a
                  // cancelled or failed restore simply resolves null again
                  // and the row stays hidden (D-24's third protection).
                  onTap: () async {
                    await showRestoreSheet(context);
                    ref.invalidate(_preRestoreSnapshotModifiedAtProvider);
                  },
                ),
                const _UndoRestoreRow(),
                // §7.1's three sign-in facts, reproduced verbatim from
                // constraints.md — never paraphrase, reorder or abbreviate.
                // The third is enforced by the drive.appdata scope (D-22),
                // not merely asserted by this copy — do not soften it.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Không có tài khoản MotoNote.',
                        style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                      ),
                      Text(
                        'Có đăng nhập Google, và chỉ khi bạn bật backup.',
                        style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                      ),
                      Text(
                        'App chỉ thấy đúng file của nó.',
                        style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _SettingsGroup(
              // Phase 5 (BKP-*) owns the export row. Live as of 05-06 — the
              // caption below would read as actively misleading under a
              // working row (T-04-14).
              title: 'Xuất file',
              showComingSoonCaption: false,
              rows: [
                ListTile(
                  title: const Text('Xuất file dữ liệu'),
                  // [NEW, PROVISIONAL] — states plainly what the file is.
                  subtitle: const Text('Bản sao toàn bộ dữ liệu trong app.'),
                  // BKP-11/BKP-12/D-18: this row does not depend on sign-in
                  // state in any way. §7.2 names "Xuất file" as the
                  // mitigation for the one thing the drive.appdata scope
                  // costs the user, and D-18's user — who has never signed
                  // in — is exactly who this button is for. A later
                  // contributor tidying "backup-related" rows into one
                  // signed-in-gated block would break the requirement
                  // without noticing.
                  onTap: () async {
                    try {
                      await exportAppData(
                        ref.read(appProvider),
                        ref.read(repositoryProvider).documentsDirectory,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          // [NEW, PROVISIONAL]
                          content: Text('Đã tạo file xuất dữ liệu'),
                        ),
                      );
                    } catch (_) {
                      // CR-03: never interpolate the caught exception
                      // object into user-facing Vietnamese copy — the same
                      // mapped-message discipline the backup error codes
                      // already enforce for the persisted field, extended
                      // here to this display-only SnackBar. share_plus'
                      // PlatformException.toString() and dart:io I/O
                      // errors can both carry absolute file paths.
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(_exportFailureMessage)),
                      );
                    }
                  },
                ),
              ],
            ),
            _SettingsGroup(
              // Phase 6 (SET-*) owns vehicle and item management. Live as
              // of 06-05 — the coming-soon caption below would read as
              // actively misleading under working rows (T-04-14).
              title: 'Quản lý xe/hạng mục',
              showComingSoonCaption: false,
              rows: [
                ListTile(
                  title: const Text('Quản lý xe'),
                  subtitle: Text(
                    '${vehicles.length} xe · Đang dùng: $currentVehicleName',
                    style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                  ),
                  onTap: () => context.push('/settings/vehicles'),
                ),
                // 06-06 declares '/settings/items' — that route does not
                // exist yet at the end of this plan, so tapping this row is
                // deliberately a no-op for exactly one wave (recorded in
                // 06-05-SUMMARY.md, not an oversight). Not rendered
                // disabled, and no temporary SnackBar substitutes for it.
                ListTile(
                  title: const Text('Quản lý hạng mục'),
                  subtitle: Text(
                    '$enabledItemCount/$applicableCatalogCount hạng mục '
                    'đang bật',
                    style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                  ),
                  onTap: () => context.push('/settings/items'),
                ),
              ],
            ),
            _SettingsGroup(
              // 06-09 (REL-04): the app-information row group — one row,
              // opening the published privacy policy. Placed ABOVE the
              // danger-zone group deliberately (that group must stay last),
              // and below every functional group, matching the plan's own
              // "near the app-information rows at the bottom" placement.
              title: 'Về ứng dụng',
              showComingSoonCaption: false,
              rows: [
                ListTile(
                  title: const Text('Chính sách quyền riêng tư'),
                  onTap: () => _openPrivacyPolicy(context),
                ),
              ],
            ),
            _SettingsGroup(
              // Phase 6 (SET-03, P6-D-10…13): the delete-all-data flow.
              // MUST stay the last group in the list — the danger zone is
              // deliberately at the very bottom, after every other group.
              title: 'Vùng nguy hiểm',
              showComingSoonCaption: false,
              rows: [
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  // The one place in Settings a row is error-tinted at
                  // rest, not only inside its dialog (Color table's named
                  // exception) — SET-03 is store-mandated and deserves
                  // visible weight without a tap to discover its severity.
                  // The row background itself stays colorScheme.surface —
                  // only the icon and label are tinted.
                  title: Text(
                    'Xoá tất cả dữ liệu',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => showDeleteAllDataFlow(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 06-09 (REL-04): opens the published privacy policy in whatever
/// browser/app the OS resolves for a view intent, reusing
/// `android_intent_plus` — the dependency `openBatterySettings()` already
/// uses in `lib/notifications/battery_hints.dart` — rather than adding a new
/// URL-launching package. Wrapped in try/catch with a mapped, non-interpolated
/// failure message, matching every other async row handler in this file
/// (CR-02/CR-03); `context.mounted` is checked before the SnackBar because
/// the sheet/screen can be popped while the platform channel call is in
/// flight (the CLAUDE.md trap this file guards against everywhere else).
Future<void> _openPrivacyPolicy(BuildContext context) async {
  try {
    const intent = AndroidIntent(
      action: 'action_view',
      data: _privacyPolicyUrl,
    );
    await intent.launch();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_privacyPolicyLaunchFailureMessage)),
    );
  }
}

/// A section header followed by its rows and, optionally, the shared "Sẽ có
/// ở bản sau" caption — the same "disabled control + caption" idiom
/// `welcome_screen.dart` already ships for its Drive-restore button, scaled
/// to a row group. 04-03 adds [showComingSoonCaption]: once a group's rows
/// actually work, the caption directly beneath them would read as actively
/// misleading, so the Thông báo group is the one call site that passes
/// `false` — the other three groups keep the default (T-04-14).
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.rows,
    this.showComingSoonCaption = true,
  });

  final String title;
  final List<Widget> rows;
  final bool showComingSoonCaption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        ...rows,
        if (showComingSoonCaption)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Sẽ có ở bản sau',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

/// The exact-alarm opt-in row (P4-D-07) — a `ConsumerStatefulWidget` rather
/// than folded into `SettingsScreen` itself, so its `WidgetsBindingObserver`
/// can re-check the live OS grant on resume (the only signal available for
/// "the user just came back from the exact-alarm settings page") without
/// making the rest of the screen wait on anything (D-19).
class _ExactAlarmRow extends ConsumerStatefulWidget {
  const _ExactAlarmRow();

  @override
  ConsumerState<_ExactAlarmRow> createState() => _ExactAlarmRowState();
}

class _ExactAlarmRowState extends ConsumerState<_ExactAlarmRow>
    with WidgetsBindingObserver {
  /// Set when the user taps the switch ON and the app hands control to the
  /// system exact-alarm settings page. The request call below is
  /// fire-and-forget — it returns before the user has decided anything — so
  /// the next resume is the first moment the app can learn what was
  /// actually granted (CR-02). Cleared on that very next resume regardless
  /// of outcome, so it can never be consumed by an unrelated later resume
  /// (T-04-26).
  bool _awaitingExactAlarmResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(_canScheduleExactProvider);
      if (_awaitingExactAlarmResume) {
        // Clear first: a failed or refused round trip must not leave the
        // flag armed for an unrelated later resume (T-04-26).
        _awaitingExactAlarmResume = false;
        unawaited(_syncExactAlarmGrant());
      }
    }
  }

  Future<void> _onChanged(bool wantsOn) async {
    final notifier = ref.read(appProvider.notifier);
    if (!wantsOn) {
      await notifier.updateSettings(
        (s) => s.copyWith(exactAlarmsEnabled: false),
      );
      return;
    }
    // The one and only call site in the whole app (P4-D-07) — on Android
    // 12+ this leaves the app entirely for a system settings page (D-30).
    // The call is fire-and-forget and returns before the user has decided
    // anything, so nothing is read or persisted here (CR-02) — the resume
    // path (`didChangeAppLifecycleState` -> `_syncExactAlarmGrant`) is what
    // actually records what the OS granted, once there is something to
    // record.
    _awaitingExactAlarmResume = true;
    final service = ref.read(notificationSchedulerProvider);
    await service.requestExactAlarmsPermission();
  }

  /// Persists exactly what the OS currently grants, once the user has
  /// returned from the exact-alarm settings page (CR-02). This is the only
  /// place in the file that writes a non-literal value into
  /// `exactAlarmsEnabled` — `_onChanged`'s OFF branch writes `false`
  /// directly, since revoking the app's own opt-in needs no OS round trip.
  Future<void> _syncExactAlarmGrant() async {
    final service = ref.read(notificationSchedulerProvider);
    final granted = await service.canScheduleExactNotifications();
    if (!mounted) return;
    await ref
        .read(appProvider.notifier)
        .updateSettings((s) => s.copyWith(exactAlarmsEnabled: granted));
  }

  @override
  Widget build(BuildContext context) {
    final storedOptIn = ref.watch(
      appProvider.select((d) => d.settings.exactAlarmsEnabled),
    );
    final liveGranted = ref.watch(_canScheduleExactProvider).value ?? false;
    return SwitchListTile(
      // [NEW, PROVISIONAL] — entirely new surface, not in §10.3.
      title: const Text('Nhắc đúng giờ'),
      subtitle: const Text(
        'Cần quyền báo thức chính xác. Không bật thì thông báo vẫn tới, có '
        'thể trễ vài giờ.',
      ),
      value: storedOptIn && liveGranted,
      onChanged: _onChanged,
    );
  }
}

/// P4-D-08: the tappable soft-prompt line, shown only while the OS
/// currently has notifications off for this app — the LIVE state, never
/// the stored `notificationPermissionAsked` intent. Once Android has
/// recorded a permanent denial, this is the only route back — a plain text
/// line would be a dead end.
class _NotificationSoftPromptRow extends ConsumerStatefulWidget {
  const _NotificationSoftPromptRow();

  @override
  ConsumerState<_NotificationSoftPromptRow> createState() =>
      _NotificationSoftPromptRowState();
}

class _NotificationSoftPromptRowState
    extends ConsumerState<_NotificationSoftPromptRow>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(_notificationsEnabledProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // D-19: the row itself renders only once the live check resolves to
    // `false` — absent while unknown (still loading) and absent while
    // enabled, never a spinner in its place.
    final enabled = ref.watch(_notificationsEnabledProvider).value;
    if (enabled != false) return const SizedBox.shrink();
    return ListTile(
      // [NEW, PROVISIONAL] — §10.3 describes "một dòng nhắc nhẹ" but never
      // quotes it (P4-D-08).
      title: const Text('Thông báo đang tắt'),
      subtitle: const Text('Bấm để bật lại trong cài đặt máy.'),
      onTap: () =>
          ref.read(notificationSchedulerProvider).openAppNotificationSettings(),
    );
  }
}

/// The "Đăng nhập Google" row (BKP-03/BKP-14) — a plain `ConsumerWidget`,
/// deliberately NOT `_ExactAlarmRow`'s observe-and-recheck-on-resume shape.
///
/// This row originally live-derived the address through `currentEmail()` ->
/// `attemptLightweightAuthentication()` and invalidated that on every
/// `AppLifecycleState.resumed`, following the exact-alarm row's
/// "live OS state over stored intent" rule (T-04-13/P4-D-08). On a real
/// device that combination is an unbounded loop (gap G-05-3): despite its
/// name and its documented contract, `attemptLightweightAuthentication()`
/// PRESENTS a Google sheet, which pauses this app and resumes it on close,
/// and that resume re-invalidated the provider which re-opened the sheet.
/// Measured on SM A066B: zero flows while on Trang chủ, ~18 completed
/// sign-in flows per 30s with this screen open, input focus flipping
/// between the app and the GMS window so the whole app read as frozen.
///
/// So the address now comes from the stored document. Two of this phase's
/// own decisions already required that a passive row behave this way:
/// D-19 (no screen waits on the network) and D-23 (never pop a sign-in
/// dialog mid-flow) — a row that merely DISPLAYS who is signed in must not
/// be able to open a Google dialog at all. `googleEmail` is written by the
/// only two events that can change it, in the same `updateSettings` call
/// that changes the rest of the state: an explicit sign-in below, and an
/// explicit sign-out below. Nothing else can desynchronise it in-app.
///
/// Accepted trade-off (this is the P4-D-08 liveness being given up here,
/// and it is bounded): access revoked from the Google account page
/// out-of-app leaves this row showing the last address until the next
/// sign-in or sign-out. That state is not silent — it is exactly what
/// BKP-04's `Lần sao lưu cuối: … · Có lỗi` line in Settings reports, which
/// is the surface the source document assigns to a revoked grant.
class _GoogleAccountRow extends ConsumerWidget {
  const _GoogleAccountRow();

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final signedIn =
        ref.read(appProvider.select((d) => d.settings.googleEmail)) != null;
    if (signedIn) {
      final confirmed = await _confirmGoogleSignOut(context);
      if (!context.mounted) return;
      if (confirmed != true) return;
      try {
        await ref.read(googleAuthServiceProvider).signOut();
      } catch (_) {
        // CR-02: a failed signOut() must leave googleEmail and
        // driveBackupEnabled EXACTLY as they were — the updateSettings
        // call below that clears them must NOT run, or the app would
        // claim signed-out while the platform still holds the account.
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_googleSignOutFailureMessage)),
        );
        return;
      }
      if (!context.mounted) return;
      // One updateSettings call clearing googleEmail and disabling
      // driveBackupEnabled together — no intermediate state exists where
      // the app believes automatic backup is on with no account, and the
      // same state change that clears googleEmail is what invalidates
      // this row's live provider below, so a render racing the sign-out
      // cannot show a stale address. The Drive file is NOT touched —
      // deleting it is explicitly rejected (P5-D-13): it would destroy
      // the user's only backup and duplicates Phase 6's delete-all-data
      // button.
      await ref
          .read(appProvider.notifier)
          .updateSettings(
            (s) => s.copyWith(googleEmail: null, driveBackupEnabled: false),
          );
      return;
    }
    try {
      final result = await ref
          .read(googleAuthServiceProvider)
          .signInAndAuthorize();
      if (!context.mounted) return;
      if (result == null) return; // user cancelled — nothing to persist.
      await ref
          .read(appProvider.notifier)
          .updateSettings((s) => s.copyWith(googleEmail: result.email));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_googleSignInFailureMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(appProvider.select((d) => d.settings.googleEmail));
    return ListTile(
      title: const Text('Đăng nhập Google'),
      subtitle: Text(email ?? 'Chưa đăng nhập'), // [NEW, PROVISIONAL]
      onTap: () => _onTap(context, ref),
    );
  }
}

/// P5-D-13's escape hatch — a user who signed into the wrong Google account
/// has a route out that does not destroy their only backup. Copy is
/// invented, `[NEW, PROVISIONAL]`, recorded verbatim in `05-01-SUMMARY.md`.
/// Follows `odometer_confirm_dialog.dart`'s one-function-per-confirmation
/// shape even though this confirmation has a single caller today —
/// `_GoogleAccountRow._onTap`.
Future<bool?> _confirmGoogleSignOut(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Đăng xuất Google?'),
      content: const Text(
        'Backup tự động sẽ dừng lại. Bản sao lưu hiện có trên Drive vẫn '
        'được giữ nguyên.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Đăng xuất'),
        ),
      ],
    ),
  );
}

/// §7.6 Layer 3 / BKP-10's undo — one row, one condition (P5-D-05): renders
/// only while [_preRestoreSnapshotModifiedAtProvider] resolves non-null
/// AND `canUndoRestore` says the seven-day window is still open. Not a
/// disabled row, not a greyed-out label — the row is either present or it
/// renders nothing at all. No date arithmetic happens here; the predicate
/// owns the boundary (already pinned by
/// `test/domain/backup_timing_test.dart`) and this widget only asks it a
/// yes/no question.
///
/// P5-D-06: deliberately no counterpart on `home_screen.dart`. §7.5/D-23
/// design this whole feature as one quiet line in Settings, and unlike a
/// dead notification (P4-D-12) — a truly *silent* failure the user cannot
/// otherwise see — a wrong restore is not silent: the wrong data is on
/// Trang chủ, where the user is already looking at it. Keeping this out of
/// `home_screen.dart` also leaves T-03-28's counting invariant untouched.
///
/// A `ConsumerWidget`, not stateful: nothing here needs to react to an OS
/// lifecycle resume the way `_ExactAlarmRow`/`_GoogleAccountRow` do — the
/// snapshot file only ever changes because of an action this same app
/// takes (a restore writes it, this row's own confirmed tap deletes it),
/// never because of something outside the app the user could grant or
/// revoke while away.
class _UndoRestoreRow extends ConsumerWidget {
  const _UndoRestoreRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotModifiedAt = ref
        .watch(_preRestoreSnapshotModifiedAtProvider)
        .value;
    if (snapshotModifiedAt == null) return const SizedBox.shrink();
    if (!canUndoRestore(snapshotModifiedAt)) return const SizedBox.shrink();

    return ListTile(
      title: const Text('Hoàn tác khôi phục'),
      // [NEW, PROVISIONAL] — names how long has passed since the restore
      // so the window closing is visible, rather than the user discovering
      // one day that the button is simply gone.
      subtitle: Text(
        'Đã khôi phục ${relativeVi(snapshotModifiedAt)}. Có thể hoàn tác '
        'trong vòng 7 ngày kể từ đó.',
      ),
      onTap: () => _onUndoTap(context, ref),
    );
  }

  Future<void> _onUndoTap(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmUndoRestore(context);
    if (!context.mounted) return;
    if (confirmed != true) return;

    final repo = ref.read(repositoryProvider);

    // Step 1: read. If the snapshot is undecodable (SchemaTooNewException
    // or a format/decode error), report it and change nothing — the same
    // discipline the restore sheet applies to a document it cannot read.
    // Do not delete a snapshot the app failed to read; it may be readable
    // by a future build.
    final AppData? snapshot;
    try {
      snapshot = await repo.readPreRestoreSnapshot();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          // [NEW, PROVISIONAL]
          content: Text(
            'Không đọc được bản hoàn tác. Dữ liệu trên máy chưa bị thay đổi.',
          ),
        ),
      );
      return;
    }
    if (!context.mounted) return;

    if (snapshot == null) {
      // The file vanished between the render and the tap.
      ref.invalidate(_preRestoreSnapshotModifiedAtProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          // [NEW, PROVISIONAL]
          content: Text('Không tìm thấy bản để hoàn tác.'),
        ),
      );
      return;
    }

    // Steps 2 and 3 in this order deliberately: deleting the snapshot
    // first would leave the user with neither the undo nor the data if
    // the mutation then failed.
    try {
      await ref.read(appProvider.notifier).undoRestore(snapshot);
    } catch (_) {
      // WR-02: a failed disk write here must be reported, not silently
      // swallowed — this is the one control whose whole purpose is
      // recovering from a bad restore. The claim that nothing on the
      // device changed is true by construction: _mutate awaits
      // _repo.save(next) before it assigns state, so a failed save
      // leaves both the in-memory document and appdata.json exactly as
      // they were. Do not delete the snapshot on this path: it is
      // still the user's only route back, and step 3 must not run.
      //
      // Known residue, left alone deliberately: undoRestore() arms
      // pauseNextAutomaticBackup() before its own _mutate call, and on
      // this failure path that one-shot is never consumed — the next
      // mutation's debounced automatic backup is skipped once. Costs
      // one deferred automatic upload (the >24h cold-start trigger
      // still fires); unwinding the flag from the UI layer would mean
      // reaching past AppNotifier into BackupService state, which is
      // worse than the residue.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(_undoFailureMessage)));
      return;
    }
    if (!context.mounted) return;
    try {
      await repo.deletePreRestoreSnapshot();
    } catch (_) {
      // The undo itself already succeeded — telling the user it failed
      // here would be a lie. Swallowed deliberately: the only visible
      // consequence is that the undo row keeps rendering, and tapping it
      // again re-applies the same snapshot, which is idempotent.
    }
    if (!context.mounted) return;
    ref.invalidate(_preRestoreSnapshotModifiedAtProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        // [NEW, PROVISIONAL]
        content: Text('Đã hoàn tác khôi phục'),
      ),
    );
  }
}

/// P5-D-29's confirmation — invented surface, `[NEW, PROVISIONAL]`, recorded
/// verbatim in this plan's SUMMARY. §7.6 specifies no confirmation for
/// "Hoàn tác khôi phục", but every other data-replacing action in this app
/// confirms (the odometer correction, the restore comparison itself,
/// sign-out above), so this one does too. `Huỷ` renders as the visually
/// primary [FilledButton] and `Hoàn tác` as the secondary [OutlinedButton]
/// — the same never-default-to-destructive shape `restore_sheet.dart`
/// already uses for `Huỷ`/`Vẫn khôi phục`.
Future<bool?> _confirmUndoRestore(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hoàn tác khôi phục?'),
      content: const Text(
        'Dữ liệu vừa khôi phục từ Drive sẽ được thay bằng dữ liệu trên máy '
        'trước khi khôi phục. Bản sao lưu trên Drive không bị ảnh hưởng.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Huỷ'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Hoàn tác'),
        ),
      ],
    ),
  );
}

/// BKP-06/BKP-07's one honest line — the whole visible surface of automatic
/// backup (D-23). Takes the relative-time string from [relativeVi], never
/// an inline duration calculation here — the whole point of task 2's
/// `lib/domain/backup_timing.dart` is that this line and the >24h rule can
/// never disagree about what a day is. A plain widget rather than a
/// `ConsumerWidget` — both fields it renders already come from
/// `SettingsScreen`'s own `ref.watch(appProvider.select(...))`, so this
/// widget needs no provider access of its own.
class _BackupStatusRow extends StatelessWidget {
  const _BackupStatusRow({
    required this.lastBackupAt,
    required this.lastBackupError,
  });

  final DateTime? lastBackupAt;
  final String? lastBackupError;

  @override
  Widget build(BuildContext context) {
    if (lastBackupAt == null && lastBackupError == null) {
      // Never backed up, and no attempt has failed yet.
      return const ListTile(title: Text('Chưa sao lưu lần nào'));
      // [NEW, PROVISIONAL]
    }
    final at = lastBackupAt;
    final prefix = at == null ? null : 'Lần sao lưu cuối: ${relativeVi(at)}';
    if (lastBackupError == null) {
      // lastBackupAt set, no error.
      return ListTile(title: Text(prefix!));
    }
    if (prefix == null) {
      // Never backed up, and the very first attempt already failed — the
      // error half alone, without a relative time this case has none of.
      return ListTile(title: Text(lastBackupError!));
    }
    // §7.5's verbatim composed head: "Lần sao lưu cuối: 3 ngày trước · Có
    // lỗi", with the mapped error string as the subtitle so the user can
    // see WHICH failure it was.
    return ListTile(
      title: Text('$prefix · Có lỗi'),
      subtitle: Text(lastBackupError!),
    );
  }
}
