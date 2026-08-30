// lib/ui/settings/settings_screen.dart — HOME-01's third shell tab. This
// plan's task 1 creates the minimal real screen so the branch compiles;
// task 2 fills in P3-D-13's four groups (Thông báo, Sao lưu Drive, Xuất
// file, Quản lý xe/hạng mục).
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(child: ListView()),
    );
  }
}
