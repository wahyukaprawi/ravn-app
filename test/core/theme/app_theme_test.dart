import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/core/theme/app_colors.dart';
import 'package:ravn/core/theme/app_theme.dart';

void main() {
  testWidgets('snackbar action is legible on the inverse surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Message'),
                    action: SnackBarAction(label: 'View', onPressed: () {}),
                  ),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    final action = tester.widget<TextButton>(
      find.ancestor(of: find.text('View'), matching: find.byType(TextButton)),
    );

    expect(action.style?.foregroundColor?.resolve({}), AppColors.background);
  });
}
