// lib/data/receipt_storage.dart — DATA-08 receipt-photo directory convention.
//
// Receipt photos live in one dedicated subdirectory of the app documents
// directory, never scattered alongside appdata.json. One directory means
// one exclusion path covers every photo, both now and after Phase 3 starts
// writing them — see android/app/src/main/res/xml/auto_backup_rules.xml and
// data_extraction_rules.xml, both of which exclude exactly this path segment
// under {dataDir}/app_flutter/. If kReceiptsDirName and the XML path segment
// ever diverge, the exclusion silently stops matching and photos start
// flowing into the user's Google Account backup (D-20 says this must never
// happen).
//
// This file imports dart:io only, no package:path_provider and no Flutter
// library — the caller supplies the Directory, the same pattern
// AppDataRepository uses (P1-D-11), so this stays exercisable under plain
// `dart test`.
import 'dart:io';

/// The single subdirectory name receipt photos live in. Must match the
/// `app_flutter/receipts/` path segment excluded by both Android backup
/// manifests.
const String kReceiptsDirName = 'receipts';

/// Returns the receipts directory inside [appDocumentsDir], creating it if
/// it does not already exist.
Future<Directory> receiptsDirIn(Directory appDocumentsDir) async {
  final dir = Directory('${appDocumentsDir.path}/$kReceiptsDirName');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Deletes each file at the given [paths], ignoring any path that is
/// already gone. Called when a ServiceLog is deleted to remove the photos
/// its `photoPaths` name — Phase 1 provides this single entry point;
/// nothing writes a photo until Phase 3, so nothing is deleted yet.
Future<void> deleteReceipts(Iterable<String> paths) async {
  for (final path in paths) {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
