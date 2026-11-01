import 'package:equatable/equatable.dart';

/// One sample on the coin detail price chart (EUR, UTC timestamp).
class ChartPoint extends Equatable {
  /// Creates a chart point.
  const ChartPoint({required this.timestamp, required this.priceEur});

  /// Sample time (UTC).
  final DateTime timestamp;

  /// Price in EUR at [timestamp].
  final double priceEur;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'priceEur': priceEur,
  };

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
      priceEur: (json['priceEur'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [timestamp, priceEur];
}
