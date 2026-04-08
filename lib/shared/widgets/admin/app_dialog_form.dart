import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

class AppDialogForm extends StatelessWidget {
  final String title;
  final Widget child;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;
  final bool scrollable;

  const AppDialogForm({
    super.key,
    required this.title,
    required this.child,
    required this.submitLabel,
    this.onSubmit,
    this.onCancel,
    this.isLoading = false,
    this.scrollable = true,
  });

  void _close(BuildContext context, [Object? result]) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;
    final content = scrollable ? SingleChildScrollView(child: child) : child;

    return Dialog(
      backgroundColor: AppColors.cardDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                fit: FlexFit.loose,
                child: content,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  TextButton(
                    onPressed:
                        isLoading ? null : onCancel ?? () => _close(context),
                    child: const Text('Huy'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : onSubmit,
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(submitLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
