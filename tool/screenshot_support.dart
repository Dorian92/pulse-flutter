import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Root [RepaintBoundary] for phone screenshots.
const pulseScreenshotBoundaryKey = Key('pulse_screenshot_root');

const phoneLogicalWidth = 390.0;
const phoneLogicalHeight = 844.0;
const phoneDevicePixelRatio = 3.0;

/// Output directory for PNGs (`SCREENSHOT_DIR` dart-define).
String screenshotOutputDir = const String.fromEnvironment(
  'SCREENSHOT_DIR',
  defaultValue: '/opt/cursor/artifacts/screenshots',
);

Future<void> configurePhoneSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = phoneDevicePixelRatio;
  tester.view.physicalSize = Size(
    phoneLogicalWidth * phoneDevicePixelRatio,
    phoneLogicalHeight * phoneDevicePixelRatio,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> loadScreenshotFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final regular = await _readRoboto('Roboto-Regular.ttf');
  final medium = await _readRoboto('Roboto-Medium.ttf');
  if (regular == null) {
    return;
  }
  final loader = FontLoader('Roboto')..addFont(Future.value(regular));
  if (medium != null) {
    loader.addFont(Future.value(medium));
  }
  await loader.load();
}

Future<ByteData?> _readRoboto(String fileName) async {
  final roots = <String>[
    Platform.environment['FLUTTER_ROOT'] ?? '',
    '${Platform.environment['HOME'] ?? ''}/development/flutter',
    '/opt/flutter',
  ].where((path) => path.isNotEmpty);

  for (final root in roots) {
    final file = File('$root/bin/cache/artifacts/material_fonts/$fileName');
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      return ByteData.sublistView(bytes);
    }
  }
  return null;
}

Future<void> captureScreenshotPng(WidgetTester tester, String fileName) async {
  await tester.pump(const Duration(milliseconds: 400));
  final outDir = Directory(screenshotOutputDir);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(pulseScreenshotBoundaryKey),
    );
    final image = await boundary.toImage(pixelRatio: phoneDevicePixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw TestFailure('Failed to encode PNG for $fileName');
    }
    await File(
      '${outDir.path}/$fileName',
    ).writeAsBytes(byteData.buffer.asUint8List());
  });
}

Widget screenshotBoundary({required Widget child}) {
  return RepaintBoundary(key: pulseScreenshotBoundaryKey, child: child);
}
