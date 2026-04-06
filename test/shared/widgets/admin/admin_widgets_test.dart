import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_dialog_form.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_pagination.dart';

void main() {
  group('Admin reusable widgets', () {
    testWidgets('AppPagination emits next page callback', (tester) async {
      int? selectedPage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPagination(
              page: 2,
              totalPages: 4,
              onPageChanged: (page) => selectedPage = page,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('2 / 4'), findsOneWidget);
      expect(selectedPage, 3);
    });

    testWidgets('AppDialogForm triggers submit action', (tester) async {
      var submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => AppDialogForm(
                        title: 'Create Cinema',
                        submitLabel: 'Save',
                        onSubmit: () => submitted = true,
                        child: const SizedBox(width: 200, height: 80),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(submitted, isTrue);
    });
  });
}
