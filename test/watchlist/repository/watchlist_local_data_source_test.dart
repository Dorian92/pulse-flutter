import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pulse/core/storage/hive_boxes.dart';
import 'package:pulse/watchlist/repository/data_sources/watchlist_local_data_source.dart';

void main() {
  late Directory tempDir;
  late WatchlistLocalDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pulse_watchlist_local');
    await HiveBoxes.init(path: tempDir.path);
    dataSource = WatchlistLocalDataSource(
      persistBox: Hive.box<String>(HiveBoxes.pulsePersist),
    );
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('persists add remove and reorder', () async {
    await dataSource.writeOrderedIds(['bitcoin', 'ethereum']);
    expect(await dataSource.readOrderedIds(), ['bitcoin', 'ethereum']);

    final ids = List<String>.from(await dataSource.readOrderedIds());
    ids.remove('bitcoin');
    await dataSource.writeOrderedIds(ids);
    expect(await dataSource.readOrderedIds(), ['ethereum']);

    await dataSource.writeOrderedIds(['a', 'b', 'c']);
    final reordered = ['a', 'c', 'b'];
    await dataSource.writeOrderedIds(reordered);
    expect(await dataSource.readOrderedIds(), reordered);
  });

  test('deduplicates corrupt duplicate ids on read', () async {
    await dataSource.writeOrderedIds(['bitcoin', 'bitcoin', 'ethereum']);
    expect(await dataSource.readOrderedIds(), ['bitcoin', 'ethereum']);
  });
}
