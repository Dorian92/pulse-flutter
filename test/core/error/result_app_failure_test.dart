import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/error/app_failure.dart';
import 'package:pulse/core/error/result.dart';
import 'package:pulse/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  test('Success exposes value and stale flag', () {
    const result = Success<int>(42, isStale: true);
    expect(
      result.when(
        success: (value, isStale, refreshError) =>
            (value, isStale, refreshError),
        failure: (_) => null,
      ),
      (42, true, null),
    );
  });

  test('Failure carries AppFailure', () {
    const result = Failure<int>(NotFoundFailure(statusCode: 404));
    expect(
      result.when(success: (_, __, ___) => null, failure: (error) => error),
      isA<NotFoundFailure>(),
    );
  });

  test('AppFailure maps to localized messages', () {
    expect(
      const NetworkFailure(offline: true).message(l10n),
      l10n.errorOffline,
    );
    expect(const TimeoutFailure().message(l10n), l10n.errorTimeout);
    expect(
      const RateLimitFailure(retryAfterSeconds: 30).message(l10n),
      l10n.errorRateLimitRetryAfter(30),
    );
    expect(
      const ServerFailure(statusCode: 503).message(l10n),
      l10n.errorServer,
    );
    expect(const ParsingFailure().message(l10n), l10n.errorParsing);
    expect(const NotFoundFailure().message(l10n), l10n.errorNotFound);
    expect(const CacheFailure().message(l10n), l10n.errorCache);
    expect(const UnknownFailure().message(l10n), l10n.errorUnknown);
  });
}
