// lib/domain/catalog.dart — transcribed from Phụ lục A (the 24-entry parts
// catalog). Pure Dart (D-31) — this directory must never import the
// Flutter SDK.
//
// Deliberate deviation from Appendix A: the source's `CatalogEntry` carries
// `icon: IconData`, a Flutter type that cannot live in `lib/domain/` under
// D-31. This file stores `iconKey: String` instead (e.g. `'water_drop'`);
// plan 02 adds `lib/ui/catalog_icons.dart`, the one file allowed to import
// Flutter's material library, mapping every key used here to its literal
// `Icons.x` constant. See 02-RESEARCH.md Pattern 1 for why the
// tree-shaker still works with a runtime-dynamic lookup over literal values.
//
// This plan (02-01) populates `kCatalog` with a single entry — `engine_oil`
// — to prove the tracer slice end to end. Plan 02 fills in the remaining 23
// entries; that is a functionality gap, not an architectural one.
import 'models/vehicle.dart';

class CatalogEntry {
  final String code;
  final String nameVi;
  final Set<VehicleType> appliesTo;
  final int? intervalKm;
  final int? intervalMonths;
  final bool defaultOn;
  final bool isOil;
  final String? hint;
  final String iconKey;

  const CatalogEntry({
    required this.code,
    required this.nameVi,
    required this.appliesTo,
    required this.iconKey,
    this.intervalKm,
    this.intervalMonths,
    this.defaultOn = false,
    this.isOil = false,
    this.hint,
  });
}

const kCatalog = <CatalogEntry>[
  CatalogEntry(
    code: 'engine_oil',
    nameVi: 'Nhớt máy',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 2000,
    intervalMonths: 3,
    defaultOn: true,
    isOil: true,
    iconKey: 'water_drop',
    hint: 'Quan trọng nhất. Chu kỳ đổi theo loại nhớt.',
  ),
];

/// Entries applicable to [type], preserving `kCatalog`'s declaration order.
List<CatalogEntry> catalogFor(VehicleType type) =>
    kCatalog.where((entry) => entry.appliesTo.contains(type)).toList();
