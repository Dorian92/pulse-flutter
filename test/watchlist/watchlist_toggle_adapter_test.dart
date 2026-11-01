import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/watchlist/repository/watchlist_repository.dart';
import 'package:pulse/watchlist/watchlist_toggle_adapter.dart';

class MockWatchlistRepository extends Mock implements WatchlistRepository {}

void main() {
  late MockWatchlistRepository repository;
  late WatchlistRepositoryToggle toggle;

  setUp(() {
    repository = MockWatchlistRepository();
    toggle = WatchlistRepositoryToggle(repository);
  });

  test('isWatched delegates to repository', () async {
    when(() => repository.isWatched('bitcoin')).thenAnswer((_) async => true);
    expect(await toggle.isWatched('bitcoin'), isTrue);
    verify(() => repository.isWatched('bitcoin')).called(1);
  });

  test('setWatched delegates to repository', () async {
    when(
      () => repository.setWatched('solana', watched: false),
    ).thenAnswer((_) async {});
    await toggle.setWatched('solana', watched: false);
    verify(() => repository.setWatched('solana', watched: false)).called(1);
  });
}
