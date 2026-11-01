import 'package:flutter/material.dart';
import 'package:pulse/app.dart';
import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/storage/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  await configureDependencies();
  runApp(PulseApp());
}
