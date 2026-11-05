import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real isolate replies must be serviced outside FakeAsync, interleaved with
/// frames. This does not mock ranking or bypass failures/timeouts.
extension SettleApp on WidgetTester {
  Future<void> settleApp() async {
    for (var i = 0; i < 240; i++) {
      await runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await pump(const Duration(milliseconds: 16));
      if (i >= 3 &&
          !binding.hasScheduledFrame &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    await pumpAndSettle();
  }
}
