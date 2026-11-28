import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/detection/domain/confidence_gate.dart';

void main() {
  const gate = ConfidenceGate();

  test('a loose fix is rejected, however far inside', () {
    expect(
      gate.judge(
        accuracyMeters: 250,
        insideMeters: 20000,
        alreadyPending: true,
      ),
      GateVerdict.reject,
    );
  });

  test('an accurate fix well inside a county is accepted at once', () {
    expect(
      gate.judge(accuracyMeters: 20, insideMeters: 5000, alreadyPending: false),
      GateVerdict.accept,
    );
  });

  test('an unknown accuracy is judged on distance alone', () {
    expect(
      gate.judge(
        accuracyMeters: null,
        insideMeters: 5000,
        alreadyPending: false,
      ),
      GateVerdict.accept,
    );
  });

  test('near a border the first fix waits for a second', () {
    expect(
      gate.judge(accuracyMeters: 20, insideMeters: 600, alreadyPending: false),
      GateVerdict.needConfirmation,
    );
    expect(
      gate.judge(accuracyMeters: 20, insideMeters: 600, alreadyPending: true),
      GateVerdict.accept,
    );
  });

  test('accuracy eats into the distance from the border', () {
    // 1,050 m inside is clear of the 1,000 m buffer, but not with a 90 m
    // error radius.
    expect(
      gate.judge(accuracyMeters: 90, insideMeters: 1050, alreadyPending: false),
      GateVerdict.needConfirmation,
    );
  });

  test('thresholds are configurable', () {
    const strict = ConfidenceGate(ConfidenceGateConfig(maxAccuracyMeters: 30));
    expect(
      strict.judge(
        accuracyMeters: 50,
        insideMeters: 5000,
        alreadyPending: false,
      ),
      GateVerdict.reject,
    );
  });
}
