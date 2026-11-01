import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pulse/app.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/realtime/symbol_mapper_loader.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import 'package:pulse/settings/repository/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  await configureDependencies();
  await sl<SettingsRepository>().load();
  unawaited(sl<SymbolMapperLoader>().warmUp());
  runApp(const PulseApp());
}
