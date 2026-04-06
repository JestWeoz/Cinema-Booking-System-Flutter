import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_dialog_form.dart';

class RoomFormPayload {
  final String name;
  final int totalSeats;
  final RoomType roomType;

  const RoomFormPayload({
    required this.name,
    required this.totalSeats,
    required this.roomType,
  });
}

Future<RoomFormPayload?> showRoomFormDialog(
  BuildContext context, {
  RoomFormPayload? initial,
}) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: initial?.name ?? '');
  final seatsController = TextEditingController(
    text: initial?.totalSeats.toString() ?? '100',
  );
  RoomType roomType = initial?.roomType ?? RoomType.TWO_D;

  return showDialog<RoomFormPayload>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AppDialogForm(
        title: initial == null ? 'Tao phong chieu' : 'Chinh sua phong chieu',
        submitLabel: initial == null ? 'Tao phong' : 'Luu thay doi',
        onSubmit: () {
          if (!formKey.currentState!.validate()) {
            return;
          }
          Navigator.of(dialogContext, rootNavigator: true).pop(
            RoomFormPayload(
              name: nameController.text.trim(),
              totalSeats: int.parse(seatsController.text.trim()),
              roomType: roomType,
            ),
          );
        },
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui long nhap ten phong'
                    : null,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Ten phong'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RoomType>(
                initialValue: roomType,
                isExpanded: true,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Loai phong'),
                items: const [
                  RoomType.TWO_D,
                  RoomType.THREE_D,
                  RoomType.FOUR_D,
                  RoomType.IMAX,
                  RoomType.SWEETBOX,
                ]
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(roomTypeLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => roomType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: seatsController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'So ghe phai lon hon 0';
                  }
                  return null;
                },
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Tong so ghe'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
