// lib/ui/settings/settings_screen.dart — P3-D-13. Cài đặt's four groups, in
// order, every row disabled: this phase ships no working control here —
// notification settings are NOTIF-*, backup is BKP-*, export is BKP-*,
// interval/vehicle/item management is SET-*, none of them Phase 3's job
// (D-34's anti-scope-creep). Each future owner phase is named in a comment
// beside its group so this is a slot to fill, not a screen to rebuild.
//
// Rows are inlined per-group rather than built from a shared row widget, so
// each row's own `enabled: false` is independently visible in this file —
// matching `welcome_screen.dart`'s existing idiom of an inline disabled
// control plus the small grey "Sẽ có ở bản sau" caption, rather than
// abstracting it behind a widget class.
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: ListView(
          children: const [
            _SettingsGroup(
              // Phase 4 (NOTIF-*) owns these rows.
              title: 'Thông báo',
              rows: [
                ListTile(
                  title: Text('Nhắc bảo dưỡng'),
                  trailing: Icon(Icons.toggle_off_outlined),
                  enabled: false,
                ),
                ListTile(
                  title: Text('Nhắc cập nhật số km'),
                  trailing: Icon(Icons.toggle_off_outlined),
                  enabled: false,
                ),
                ListTile(title: Text('Giờ nhắc'), enabled: false),
                ListTile(title: Text('Số ngày báo trước'), enabled: false),
              ],
            ),
            _SettingsGroup(
              // Phase 5 (BKP-*) owns sign-in and the backup rows.
              title: 'Sao lưu Drive',
              rows: [
                ListTile(title: Text('Đăng nhập Google'), enabled: false),
                ListTile(
                  title: Text('Tự động sao lưu'),
                  trailing: Icon(Icons.toggle_off_outlined),
                  enabled: false,
                ),
              ],
            ),
            _SettingsGroup(
              // Phase 5 (BKP-*) owns the export row.
              title: 'Xuất file',
              rows: [
                ListTile(title: Text('Xuất file dữ liệu'), enabled: false),
              ],
            ),
            _SettingsGroup(
              // Phase 6 (SET-*) owns vehicle and item management.
              title: 'Quản lý xe/hạng mục',
              rows: [
                ListTile(title: Text('Quản lý xe'), enabled: false),
                ListTile(title: Text('Quản lý hạng mục'), enabled: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A section header followed by its (disabled) rows and one shared caption —
/// the same "disabled control + caption" idiom `welcome_screen.dart` already
/// ships for its Drive-restore button, scaled to a row group.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

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
