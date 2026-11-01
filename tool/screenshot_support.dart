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

/// Matches [MaterialApp.debugShowCheckedModeBanner] in screenshot harnesses.
const screenshotDebugShowCheckedModeBanner = false;

/// Output directory for PNGs (`SCREENSHOT_DIR` dart-define).
String screenshotOutputDir = const String.fromEnvironment(
  'SCREENSHOT_DIR',
  defaultValue: '/opt/cursor/artifacts/screenshots',
);

Future<void> configurePhoneSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = phoneDevicePixelRatio;
  tester.view.physicalSize = const Size(
    phoneLogicalWidth * phoneDevicePixelRatio,
    phoneLogicalHeight * phoneDevicePixelRatio,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> loadScreenshotFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFontFamily('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await _loadFontFamily('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

Future<void> _loadFontFamily(String family, List<String> fileNames) async {
  final loader = FontLoader(family);
  var loadedAny = false;
  for (final name in fileNames) {
    final data = await _readFlutterMaterialFont(name);
    if (data != null) {
      loader.addFont(Future.value(data));
      loadedAny = true;
    }
  }
  if (loadedAny) {
    await loader.load();
  }
}

Future<ByteData?> _readFlutterMaterialFont(String fileName) async {
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

/// Ensures [ThemeData] uses loaded Roboto files (incl. app bar title weights).
ThemeData prepareScreenshotTheme(ThemeData theme) {
  final textTheme = theme.textTheme.apply(fontFamily: 'Roboto');
  return theme.copyWith(
    textTheme: textTheme,
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: textTheme.titleLarge,
    ),
  );
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
