// lib/ui/catalog_icons.dart — the ONE file in this project allowed to
// import `package:flutter/material.dart` for resolving `CatalogEntry.
// iconKey` (declared in `lib/domain/catalog.dart`, which stays Flutter-free
// per D-31) back into a real `IconData`.
//
// INVARIANT: every value in `kCatalogIcons` MUST be a literal `Icons.x`
// reference, never constructed from a variable or a codepoint. Flutter's
// icon-font tree-shaker statically scans the compiled program for constant
// icon-data expressions; a *dynamically constructed* one (built from a
// runtime codepoint) aborts tree-shaking for the whole app and forces the
// full ~1.6 MB Material icon font into the release APK unless
// `--no-tree-shake-icons` is passed. The runtime-dynamic *lookup*
// (`kCatalogIcons[entry.iconKey]`) is fine — the tree-shaker finds every
// literal `Icons.x` value regardless of how the map is indexed at runtime.
// This build must never need the tree-shake opt-out flag (02-RESEARCH.md
// Pattern 1 / Pitfall 1, Assumptions Log A1).
import 'package:flutter/material.dart';

const kCatalogIcons = <String, IconData>{
  'water_drop': Icons.water_drop,
  'opacity': Icons.opacity,
  'filter_alt': Icons.filter_alt,
  'thermostat': Icons.thermostat,
  'bolt': Icons.bolt,
  'air': Icons.air,
  'cleaning_services': Icons.cleaning_services,
  'settings': Icons.settings,
  'autorenew': Icons.autorenew,
  'circle': Icons.circle,
  'album': Icons.album,
  'link': Icons.link,
  'settings_ethernet': Icons.settings_ethernet,
  'stop_circle': Icons.stop_circle,
  'trip_origin': Icons.trip_origin,
  'height': Icons.height,
  'circle_outlined': Icons.circle_outlined,
  'battery_full': Icons.battery_full,
  'description': Icons.description,
};

/// Resolves [iconKey] to its [IconData], falling back to a placeholder
/// icon (rather than throwing or returning null) if a future catalog entry
/// ships with a key this map forgot to add — so a missing mapping renders a
/// visible placeholder inside a list instead of crashing it.
IconData catalogIconFor(String iconKey) =>
    kCatalogIcons[iconKey] ?? Icons.help_outline;
