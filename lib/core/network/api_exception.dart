import 'package:pulse/core/error/app_failure.dart';

/// Internal exception carrying a mapped [AppFailure] for [ApiClient] boundaries.
class ApiException implements Exception {
  /// Creates an API exception.
  ApiException(this.failure);

  /// Mapped failure.
  final AppFailure failure;

  @override
  String toString() => 'ApiException($failure)';
}
