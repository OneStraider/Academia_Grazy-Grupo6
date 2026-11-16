import 'package:flutter_test/flutter_test.dart';

import 'package:academia_grazy_grupo6/screens/admin/chart_axis_scale.dart';

void main() {
  test('axis rounds the maximum up to a readable interval', () {
    final scale = ChartAxisScale.fromValues([43, 16, 9]);

    expect(scale.largestValue, 43);
    expect(scale.interval, 20);
    expect(scale.maximum, 60);
    expect(scale.ticks, [0, 20, 40, 60]);
  });

  test('axis follows larger data instead of an arbitrary ceiling', () {
    final scale = ChartAxisScale.fromValues([1001, 0]);

    expect(scale.largestValue, 1001);
    expect(scale.maximum, greaterThanOrEqualTo(scale.largestValue));
    expect(scale.maximum, lessThan(scale.largestValue + scale.interval));
    expect(scale.ticks.last, scale.maximum);
  });

  test('zero data still receives a valid axis', () {
    final scale = ChartAxisScale.fromValues([0, 0]);

    expect(scale.maximum, 1);
    expect(scale.ticks, [0, 1]);
  });
}
