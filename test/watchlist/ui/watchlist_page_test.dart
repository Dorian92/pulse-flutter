import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/realtime/realtime_status.dart';
import 'package:pulse/l10n/app_localizations.dart';
import 'package:pulse/markets/models/market_coin.dart';
import 'package:pulse/settings/bloc/settings_cubit.dart';
import 'package:pulse/settings/bloc/settings_state.dart';
import 'package:pulse/watchlist/bloc/watchlist_bloc.dart';
import 'package:pulse/watchlist/models/watchlist_snapshot.dart';
import 'package:pulse/watchlist/ui/watchlist_page.dart';

class MockWatchlistBloc extends MockBloc<WatchlistEvent, WatchlistState>
    implements WatchlistBloc {}

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

void main() {
  late MockWatchlistBloc watchlistBloc;
  late MockSettingsCubit settingsCubit;

  const coin = MarketCoin(
    id: 'bitcoin',
    symbol: 'btc',
    name: 'Bitcoin',
    imageUrl: '',
    currentPriceEur: 100,
    priceChangePercent24h: 1,
    marketCapRank: 1,
    sparkline7d: [1, 2],
    binanceSymbol: 'BTCUSDT',
  );

  setUp(() {
    watchlistBloc = MockWatchlistBloc();
    settingsCubit = MockSettingsCubit();
    when(() => settingsCubit.state).thenReturn(const SettingsState.initial());
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<WatchlistBloc>.value(value: watchlistBloc),
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
        ],
        child: child,
      ),
    );
  }

  testWidgets('shows undo snackbar after swipe remove', (tester) async {
    whenListen(
      watchlistBloc,
      Stream.fromIterable([
        const WatchlistState(
          status: WatchlistStatus.loaded,
          entries: [WatchlistEntry(coinId: 'bitcoin', coin: coin)],
          isStale: false,
          isEditing: false,
          realtimeStatus: RealtimeStatus.offline(),
        ),
        const WatchlistState(
          status: WatchlistStatus.loaded,
          entries: [],
          isStale: false,
          isEditing: false,
          realtimeStatus: RealtimeStatus.offline(),
          pendingUndo: WatchlistUndoPayload(
            coinId: 'bitcoin',
            index: 0,
            entry: WatchlistEntry(coinId: 'bitcoin', coin: coin),
          ),
        ),
      ]),
      initialState: const WatchlistState(
        status: WatchlistStatus.loaded,
        entries: [WatchlistEntry(coinId: 'bitcoin', coin: coin)],
        isStale: false,
        isEditing: false,
        realtimeStatus: RealtimeStatus.offline(),
      ),
    );

    await tester.pumpWidget(wrap(WatchlistPage(bloc: watchlistBloc)));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Bitcoin'), findsWidgets);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('edit toggles reorder mode label', (tester) async {
    whenListen(
      watchlistBloc,
      Stream.fromIterable([
        const WatchlistState(
          status: WatchlistStatus.loaded,
          entries: [WatchlistEntry(coinId: 'bitcoin', coin: coin)],
          isStale: false,
          isEditing: true,
          realtimeStatus: RealtimeStatus.offline(),
        ),
      ]),
      initialState: const WatchlistState(
        status: WatchlistStatus.loaded,
        entries: [WatchlistEntry(coinId: 'bitcoin', coin: coin)],
        isStale: false,
        isEditing: false,
        realtimeStatus: RealtimeStatus.offline(),
      ),
    );

    await tester.pumpWidget(wrap(WatchlistPage(bloc: watchlistBloc)));
    await tester.pump();
    await tester.pump();

    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('shows unavailable placeholder copy', (tester) async {
    whenListen(
      watchlistBloc,
      Stream.value(
        const WatchlistState(
          status: WatchlistStatus.loaded,
          entries: [WatchlistEntry.unavailable(coinId: 'ghostcoin')],
          isStale: false,
          isEditing: false,
          realtimeStatus: RealtimeStatus.offline(),
        ),
      ),
      initialState: const WatchlistState(
        status: WatchlistStatus.loaded,
        entries: [WatchlistEntry.unavailable(coinId: 'ghostcoin')],
        isStale: false,
        isEditing: false,
        realtimeStatus: RealtimeStatus.offline(),
      ),
    );

    await tester.pumpWidget(wrap(WatchlistPage(bloc: watchlistBloc)));
    await tester.pump();

    expect(find.text('ghostcoin'), findsOneWidget);
    expect(find.text('Price data unavailable'), findsOneWidget);
  });
}
