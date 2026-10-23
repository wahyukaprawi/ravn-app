import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/core/widgets/status_chip.dart';

void main() {
  testWidgets('status chip shows a readable label for every leave status', (
    tester,
  ) async {
    for (final entry in {
      'pending': 'Pending',
      'held': 'Held',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'canceled': 'Canceled',
    }.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StatusChip(status: entry.key)),
        ),
      );

      expect(find.text(entry.value), findsOneWidget);
    }
  });
}
