import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:pulse/core/config/app_config.dart';

/// Creates an [http.Client] with [AppConfig.connectTimeout] on the socket connect phase.
///
/// Response delivery is capped separately by [ApiClient] using [AppConfig.receiveTimeout].
http.Client createPulseHttpClient(AppConfig config) {
  final underlying = HttpClient()..connectionTimeout = config.connectTimeout;
  return IOClient(underlying);
}
