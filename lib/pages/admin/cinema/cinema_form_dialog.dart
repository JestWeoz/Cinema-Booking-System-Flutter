import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/shared/widgets/image_picker_button.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_dialog_form.dart';

class CinemaFormPayload {
  final String name;
  final String address;
  final String phone;
  final String hotline;
  final String logoUrl;

  const CinemaFormPayload({
    required this.name,
    required this.address,
    required this.phone,
    required this.hotline,
    required this.logoUrl,
  });
}

Future<CinemaFormPayload?> showCinemaFormDialog(
  BuildContext context, {
  CinemaFormPayload? initial,
}) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: initial?.name ?? '');
  final addressController = TextEditingController(text: initial?.address ?? '');
  final phoneController = TextEditingController(text: initial?.phone ?? '');
  final hotlineController = TextEditingController(text: initial?.hotline ?? '');
  String? logoUrl = initial?.logoUrl;

  return showDialog<CinemaFormPayload>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocalState) => AppDialogForm(
        title: initial == null ? 'Tao rap chieu' : 'Chinh sua rap chieu',
        submitLabel: initial == null ? 'Tao rap' : 'Luu thay doi',
        onSubmit: () {
          if (!formKey.currentState!.validate()) {
            return;
          }
          if (logoUrl == null || logoUrl!.trim().isEmpty) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(content: Text('Vui long tai logo rap len')),
            );
            return;
          }
          Navigator.of(dialogContext, rootNavigator: true).pop(
            CinemaFormPayload(
              name: nameController.text.trim(),
              address: addressController.text.trim(),
              phone: phoneController.text.trim(),
              hotline: hotlineController.text.trim(),
              logoUrl: logoUrl!.trim(),
            ),
          );
        },
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 140,
                child: ImagePickerButton(
                  label: '',
                  currentImageUrl: logoUrl,
                  size: 140,
                  shape: ImagePickerButtonShape.square,
                  onUploaded: (url) => setLocalState(() => logoUrl = url),
                  onError: (error) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui long nhap ten rap'
                    : null,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Ten rap'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui long nhap dia chi'
                    : null,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Dia chi'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui long nhap so dien thoai'
                    : null,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'So dien thoai'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: hotlineController,
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui long nhap hotline'
                    : null,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Hotline'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
