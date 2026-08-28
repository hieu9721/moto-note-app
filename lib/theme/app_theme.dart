// lib/theme/app_theme.dart — a single Material 3 ThemeData so MaterialApp
// has something real to render instead of Flutter's own default. The final
// palette, the 1024x1024 opaque launcher icon and the splash screen are
// REL-02 (Phase 6); this file exists only so `lib/theme/` is present per the
// §12 layout ahead of that work.
import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
);
