import 'dart:math' as math;

/// Numeric axis bounds and ticks shared by the dashboard painter and reports.
class ChartAxisScale {
  final int largestValue;
  final int maximum;
  final int interval;

  const ChartAxisScale({
    required this.largestValue,
    required this.maximum,
    required this.interval,
  });

  List<int> get ticks => [
    for (var value = 0; value <= maximum; value += interval) value,
  ];

  factory ChartAxisScale.fromValues(Iterable<int> values) {
    final largest = values.fold<int>(0, (a, b) => a > b ? a : b);
    if (largest <= 0) {
      return const ChartAxisScale(largestValue: 0, maximum: 1, interval: 1);
    }

    final roughInterval = largest / 4;
    final magnitude = math
        .pow(10, (math.log(roughInterval) / math.ln10).floor())
        .toDouble();
    final normalized = roughInterval / magnitude;
    final factor = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    final interval = math.max(1, (factor * magnitude).ceil()).toInt();
    final maximum = ((largest + interval - 1) ~/ interval) * interval;

    return ChartAxisScale(
      largestValue: largest,
      maximum: maximum,
      interval: interval,
    );
  }
}
