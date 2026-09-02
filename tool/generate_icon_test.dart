// tool/generate_icon_test.dart — the icon generator AND its own test.
//
// Deliberately NOT under test/: this file imports package:flutter (via
// flutter_test/dart:ui), and `dart test` runs the whole test/ tree under
// plain Dart (D-31) — a single Flutter import there would break every
// other test. Run explicitly:
//
//   flutter test tool/generate_icon_test.dart
//
// REL-02 / P6-D-16: produces a 1024x1024 fully opaque launcher icon and a
// transparent adaptive-icon foreground, both from one vector glyph drawn
// with dart:ui primitives only (no source image asset, no new package).
// Re-running this file regenerates byte-identical PNGs — the icon is
// reproducible, not a pasted binary nobody can adjust after the P6-D-16
// on-device review (T-06-08-04).
//
// Concept (06-UI-SPEC.md § Per-Screen Contract item H): an opaque teal
// field, a white speedometer-gauge-and-wrench glyph, no text — the Play
// listing already carries the app name. The glyph sits inside the inner
// 66% of the canvas so nothing load-bearing is cropped by a circular,
// squircle or rounded-square OEM adaptive-icon mask.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canvas size for both the opaque launcher icon and the transparent
/// adaptive-icon foreground — Play requires 1024x1024 for the store icon.
const int kIconSize = 1024;

/// Teal 800 — a darker, opaque tone of the app's `Colors.teal` seed
/// (lib/theme/app_theme.dart), suitable as a full-bleed background rather
/// than the lighter `colorScheme.primary` tone used for buttons.
const Color kBackgroundColor = Color(0xFF00695C);

const Color kGlyphColor = Colors.white;

/// Fraction of the canvas, from each edge, that is NOT safe — the margin
/// circular/squircle/rounded-square OEM adaptive-icon masks crop away.
/// (1 - 0.66) / 2 == 0.17, i.e. the glyph must stay within the inner 66%.
const double kSafeZoneMarginFraction = 0.17;

/// Paints the speedometer-gauge-and-wrench glyph, centered on [size],
/// sized well inside the inner-66% safe zone. No text anywhere.
void paintGlyph(Canvas canvas, Size size) {
  final center = Offset(size.width / 2, size.height / 2);
  final gaugeRadius = size.width * 0.26;
  final strokeWidth = size.width * 0.045;

  // Gauge arc — a 270-degree arc open at the bottom, like a speedometer
  // face, matching the "simplified speedometer gauge arc" concept.
  final gaugePaint = Paint()
    ..color = kGlyphColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;
  final arcRect = Rect.fromCircle(center: center, radius: gaugeRadius);
  const startAngle = 2.356194; // 135deg, radians
  const sweepAngle = 4.712389; // 270deg, radians
  canvas.drawArc(arcRect, startAngle, sweepAngle, false, gaugePaint);

  // Needle — a short line from near-center pointing up-and-right, with a
  // small hub circle at its pivot.
  final needlePaint = Paint()
    ..color = kGlyphColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth * 0.6
    ..strokeCap = StrokeCap.round;
  const needleAngle = -0.3; // radians
  final needleEnd = Offset(
    center.dx + gaugeRadius * 0.7 * math.cos(needleAngle),
    center.dy + gaugeRadius * 0.7 * math.sin(needleAngle),
  );
  canvas.drawLine(center, needleEnd, needlePaint);
  canvas.drawCircle(center, strokeWidth * 0.5, Paint()..color = kGlyphColor);

  // Small wrench overlaid at the gauge's own center: a bar with a real
  // open ring at each jaw (punched with BlendMode.clear so the hole is
  // true transparency, not a colored dot) — rotated off the needle's own
  // angle so the two read as distinct shapes rather than a second needle.
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(0.9);
  final wrenchLength = gaugeRadius * 0.95;
  final barWidth = strokeWidth * 0.55;
  final jawOuterRadius = strokeWidth * 0.75;
  final jawInnerRadius = strokeWidth * 0.4;

  canvas.saveLayer(
    Rect.fromCircle(center: Offset.zero, radius: wrenchLength),
    Paint(),
  );
  final wrenchPaint = Paint()..color = kGlyphColor;
  final barRect = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: wrenchLength, height: barWidth),
    Radius.circular(barWidth / 2),
  );
  canvas.drawRRect(barRect, wrenchPaint);
  canvas.drawCircle(Offset(-wrenchLength / 2, 0), jawOuterRadius, wrenchPaint);
  canvas.drawCircle(Offset(wrenchLength / 2, 0), jawOuterRadius, wrenchPaint);

  final holePaint = Paint()..blendMode = BlendMode.clear;
  canvas.drawCircle(Offset(-wrenchLength / 2, 0), jawInnerRadius, holePaint);
  canvas.drawCircle(Offset(wrenchLength / 2, 0), jawInnerRadius, holePaint);
  canvas.restore(); // ends saveLayer
  canvas.restore(); // ends translate/rotate
}

/// Renders the glyph at [kIconSize]x[kIconSize]. When [opaqueBackground] is
/// true, fills the entire canvas edge-to-edge with [kBackgroundColor]
/// first (the launcher/store icon); when false, the canvas stays
/// transparent except for the glyph itself (the adaptive-icon foreground).
Future<ui.Image> renderIcon({required bool opaqueBackground}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(1024, 1024);
  if (opaqueBackground) {
    canvas.drawRect(Offset.zero & size, Paint()..color = kBackgroundColor);
  }
  paintGlyph(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(kIconSize, kIconSize);
  picture.dispose();
  return image;
}

Future<void> writePng(ui.Image image, String path) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(byteData!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates the opaque 1024x1024 launcher icon and the transparent '
      'adaptive-icon foreground, both safe-zone-respecting', () async {
    // --- Opaque launcher/store icon ---
    final opaqueImage = await renderIcon(opaqueBackground: true);
    addTearDown(opaqueImage.dispose);

    expect(opaqueImage.width, kIconSize);
    expect(opaqueImage.height, kIconSize);

    final opaqueBytes = await opaqueImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    expect(opaqueBytes, isNotNull);
    final opaqueRgba = opaqueBytes!.buffer.asUint8List();

    // Sample the four corners and the center — Play rejects a launcher
    // icon with any transparent pixel, so this is asserted against the
    // raw RGBA bytes, not by eye.
    final edge = kIconSize.toDouble() - 1;
    final mid = kIconSize.toDouble() / 2;
    final samplePoints = <Offset>[
      const Offset(0, 0),
      Offset(edge, 0),
      Offset(0, edge),
      Offset(edge, edge),
      Offset(mid, mid),
    ];
    for (final point in samplePoints) {
      final x = point.dx.toInt();
      final y = point.dy.toInt();
      final index = (y * kIconSize + x) * 4;
      final alpha = opaqueRgba[index + 3];
      expect(alpha, 255, reason: 'pixel ($x,$y) must be fully opaque');
    }

    await writePng(opaqueImage, 'assets/icon/motonote_icon.png');
    expect(File('assets/icon/motonote_icon.png').existsSync(), isTrue);

    // --- Transparent adaptive-icon foreground ---
    final foregroundImage = await renderIcon(opaqueBackground: false);
    addTearDown(foregroundImage.dispose);

    final foregroundBytes = await foregroundImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    expect(foregroundBytes, isNotNull);
    final foregroundRgba = foregroundBytes!.buffer.asUint8List();

    // Compute the non-transparent bounding box and assert it lies
    // entirely inside the inner 66% safe zone (the outer ring a
    // circular/squircle/rounded-square OEM mask crops away).
    var minX = kIconSize;
    var minY = kIconSize;
    var maxX = -1;
    var maxY = -1;
    for (var y = 0; y < kIconSize; y++) {
      for (var x = 0; x < kIconSize; x++) {
        final index = (y * kIconSize + x) * 4;
        final alpha = foregroundRgba[index + 3];
        if (alpha > 0) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    expect(
      maxX,
      greaterThanOrEqualTo(minX),
      reason: 'foreground glyph must not be empty',
    );

    final margin = kIconSize * kSafeZoneMarginFraction;
    expect(minX, greaterThanOrEqualTo(margin));
    expect(minY, greaterThanOrEqualTo(margin));
    expect(maxX, lessThanOrEqualTo(kIconSize - margin));
    expect(maxY, lessThanOrEqualTo(kIconSize - margin));

    await writePng(foregroundImage, 'assets/icon/motonote_icon_foreground.png');
    expect(
      File('assets/icon/motonote_icon_foreground.png').existsSync(),
      isTrue,
    );
  });
}
