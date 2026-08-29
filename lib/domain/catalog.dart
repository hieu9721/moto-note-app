// lib/domain/catalog.dart — transcribed from Phụ lục A (the 24-entry parts
// catalog). Pure Dart (D-31) — this directory must never import the
// Flutter SDK.
//
// Deliberate deviation from Appendix A: the source's `CatalogEntry` carries
// `icon: IconData`, a Flutter type that cannot live in `lib/domain/` under
// D-31. This file stores `iconKey: String` instead (e.g. `'water_drop'`);
// `lib/ui/catalog_icons.dart` is the one file allowed to import Flutter's
// material library, mapping every key used here to its literal `Icons.x`
// constant. See 02-RESEARCH.md Pattern 1 for why the tree-shaker still
// works with a runtime-dynamic lookup over literal values.
//
// P2-D-01: `defaultOn` below is the single source of truth for which items
// are pre-checked at onboarding step 4 — verified against Appendix A to
// yield 20/11/9 (scooter), 17/11/6 (underbone), 19/12/7 (manual) for
// (applicable, pre-checked, collapsed). P2-D-02: the "advanced" grouping is
// derived from `defaultOn` at the UI layer — this class gains no `advanced`
// field. P2-D-04 governs the deferred kiểm định khí thải entry — see the
// comment at the end of the ĐIỆN & KHÁC section below.
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
  // ══════════════ ĐỘNG CƠ ══════════════
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

  CatalogEntry(
    code: 'gear_oil',
    nameVi: 'Nhớt láp (hộp số)',
    appliesTo: {VehicleType.scooter},
    intervalKm: 8000,
    intervalMonths: 12,
    defaultOn: true,
    isOil: true,
    iconKey: 'opacity',
    hint: 'Thường thay sau mỗi 3–4 lần thay nhớt máy.',
  ),

  CatalogEntry(
    code: 'oil_filter',
    nameVi: 'Lọc nhớt',
    appliesTo: {VehicleType.manual},
    intervalKm: 8000,
    intervalMonths: 12,
    defaultOn: true,
    iconKey: 'filter_alt',
  ),

  CatalogEntry(
    code: 'coolant',
    nameVi: 'Nước làm mát',
    appliesTo: {VehicleType.scooter, VehicleType.manual},
    intervalKm: 12000,
    intervalMonths: 24,
    iconKey: 'thermostat',
    hint: 'Chỉ xe có két nước.',
  ),

  CatalogEntry(
    code: 'spark_plug',
    nameVi: 'Bugi',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 10000,
    intervalMonths: 12,
    defaultOn: true,
    iconKey: 'bolt',
  ),

  CatalogEntry(
    code: 'air_filter',
    nameVi: 'Lọc gió',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 10000,
    intervalMonths: 12,
    defaultOn: true,
    iconKey: 'air',
    hint: 'Chạy đường bụi nhiều thì thay sớm hơn.',
  ),

  CatalogEntry(
    code: 'cvt_air_filter',
    nameVi: 'Lọc gió nồi',
    appliesTo: {VehicleType.scooter},
    intervalKm: 8000,
    iconKey: 'air',
  ),

  CatalogEntry(
    code: 'injector',
    nameVi: 'Vệ sinh kim phun',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 15000,
    intervalMonths: 24,
    iconKey: 'cleaning_services',
  ),

  CatalogEntry(
    code: 'valve',
    nameVi: 'Chỉnh khe hở xu-páp',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 15000,
    iconKey: 'settings',
  ),

  // ══════════════ TRUYỀN ĐỘNG ══════════════
  CatalogEntry(
    code: 'cvt_belt',
    nameVi: 'Dây curoa',
    appliesTo: {VehicleType.scooter},
    intervalKm: 18000,
    intervalMonths: 24,
    defaultOn: true,
    iconKey: 'autorenew',
    hint: 'Đứt giữa đường là phải kéo xe về.',
  ),

  CatalogEntry(
    code: 'cvt_rollers',
    nameVi: 'Bi nồi',
    appliesTo: {VehicleType.scooter},
    intervalKm: 18000,
    iconKey: 'circle',
    hint: 'Thường thay cùng lúc với dây curoa.',
  ),

  CatalogEntry(
    code: 'cvt_clutch',
    nameVi: 'Bố ba càng',
    appliesTo: {VehicleType.scooter},
    intervalKm: 20000,
    iconKey: 'album',
  ),

  CatalogEntry(
    code: 'chain_lube',
    nameVi: 'Bôi trơn xích',
    appliesTo: {VehicleType.underbone, VehicleType.manual},
    intervalKm: 500,
    iconKey: 'link',
    hint: 'Chu kỳ ngắn, bật nếu bạn tự làm.',
  ),

  CatalogEntry(
    code: 'chain_adjust',
    nameVi: 'Căng chỉnh xích',
    appliesTo: {VehicleType.underbone, VehicleType.manual},
    intervalKm: 2000,
    defaultOn: true,
    iconKey: 'link',
  ),

  CatalogEntry(
    code: 'chain_set',
    nameVi: 'Nhông xích đĩa',
    appliesTo: {VehicleType.underbone, VehicleType.manual},
    intervalKm: 18000,
    defaultOn: true,
    iconKey: 'settings_ethernet',
    hint: 'Thay cả bộ, không thay lẻ.',
  ),

  // ══════════════ PHANH ══════════════
  CatalogEntry(
    code: 'brake_pad_f',
    nameVi: 'Má phanh trước',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 18000,
    defaultOn: true,
    iconKey: 'stop_circle',
  ),

  CatalogEntry(
    code: 'brake_pad_r',
    nameVi: 'Má phanh sau',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 22000,
    defaultOn: true,
    iconKey: 'stop_circle',
  ),

  CatalogEntry(
    code: 'brake_fluid',
    nameVi: 'Dầu phanh',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 20000,
    intervalMonths: 24,
    iconKey: 'water_drop',
    hint: 'Chỉ xe phanh đĩa.',
  ),

  // ══════════════ LỐP & KHUNG GẦM ══════════════
  CatalogEntry(
    code: 'tire_front',
    nameVi: 'Lốp trước',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 20000,
    intervalMonths: 36,
    defaultOn: true,
    iconKey: 'trip_origin',
  ),

  CatalogEntry(
    code: 'tire_rear',
    nameVi: 'Lốp sau',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 18000,
    intervalMonths: 36,
    defaultOn: true,
    iconKey: 'trip_origin',
    hint: 'Mòn nhanh hơn lốp trước.',
  ),

  CatalogEntry(
    code: 'fork_oil',
    nameVi: 'Dầu phuộc trước',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 25000,
    intervalMonths: 36,
    iconKey: 'height',
  ),

  CatalogEntry(
    code: 'bearings',
    nameVi: 'Bạc đạn cổ, bánh xe',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalKm: 25000,
    iconKey: 'circle_outlined',
  ),

  // ══════════════ ĐIỆN & KHÁC ══════════════
  CatalogEntry(
    code: 'battery',
    nameVi: 'Ắc quy',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalMonths: 30,
    defaultOn: true,
    iconKey: 'battery_full',
    hint: 'Chỉ tính theo thời gian, không theo km.',
  ),

  CatalogEntry(
    code: 'insurance',
    nameVi: 'Bảo hiểm TNDS',
    appliesTo: {VehicleType.scooter, VehicleType.underbone, VehicleType.manual},
    intervalMonths: 12,
    defaultOn: true,
    iconKey: 'description',
  ),

  // P2-D-04: a pending `emission_check` entry (kiểm định khí thải) is
  // deliberately NOT added here. Phụ lục A's closing note defers it pending
  // Vietnam's emissions-inspection regulation rollout; when a concrete rule
  // exists, a later release adds that entry with the matching
  // `intervalMonths` — but per P2-D-04 it is never auto-created for
  // existing vehicles, only offered through Settings' "add item" list.
];

/// Entries applicable to [type], preserving `kCatalog`'s declaration order.
List<CatalogEntry> catalogFor(VehicleType type) =>
    kCatalog.where((entry) => entry.appliesTo.contains(type)).toList();
