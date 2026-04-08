import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/services/room_seat_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_dialog_form.dart';

String _seatTypeDisplayName(String? seatTypeName) {
  final normalized = (seatTypeName ?? '').trim().toLowerCase();
  if (normalized.contains('vip')) return 'Ghế VIP';
  if (normalized.contains('couple') ||
      normalized.contains('double') ||
      normalized.contains('doi') ||
      normalized.contains('đôi')) {
    return 'Ghế đôi';
  }
  if (normalized.contains('standard') || normalized.contains('thuong')) {
    return 'Ghế thường';
  }
  final fallback = seatTypeName?.trim();
  if (fallback == null || fallback.isEmpty) {
    return 'Không rõ';
  }
  return fallback;
}

class SeatFormPayload {
  final String seatRow;
  final int seatNumber;
  final String seatTypeId;
  final bool active;

  const SeatFormPayload({
    required this.seatRow,
    required this.seatNumber,
    required this.seatTypeId,
    required this.active,
  });
}

class SeatBulkPayload {
  final List<String> rows;
  final List<int> numbers;
  final String seatTypeId;

  const SeatBulkPayload({
    required this.rows,
    required this.numbers,
    required this.seatTypeId,
  });
}

Future<SeatFormPayload?> showSeatFormDialog(
  BuildContext context, {
  required List<SeatTypeResponse> seatTypes,
  SeatResponse? initial,
}) {
  final formKey = GlobalKey<FormState>();
  final rowController = TextEditingController(text: initial?.seatRow ?? '');
  final numberController = TextEditingController(
    text: initial?.seatNumber.toString() ?? '',
  );
  SeatTypeResponse selected = seatTypes.firstWhere(
    (type) => type.id == initial?.seatTypeId,
    orElse: () => seatTypes.first,
  );
  bool active = initial?.active ?? true;

  return showDialog<SeatFormPayload>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AppDialogForm(
        title: initial == null ? 'Tao ghe moi' : 'Chinh sua ghe',
        submitLabel: initial == null ? 'Tao ghe' : 'Luu thay doi',
        onSubmit: () {
          if (!formKey.currentState!.validate()) {
            return;
          }
          Navigator.of(dialogContext, rootNavigator: true).pop(
            SeatFormPayload(
              seatRow: rowController.text.trim().toUpperCase(),
              seatNumber: int.parse(numberController.text.trim()),
              seatTypeId: selected.id,
              active: active,
            ),
          );
        },
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: rowController,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui long nhap hang ghe'
                    : null,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Hang ghe'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: numberController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'So ghe phai lon hon 0';
                  }
                  return null;
                },
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'So ghe'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SeatTypeResponse>(
                initialValue: selected,
                isExpanded: true,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Loai ghe'),
                items: seatTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_seatTypeDisplayName(type.name)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selected = value);
                  }
                },
              ),
              if (initial != null) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  value: active,
                  onChanged: (value) => setDialogState(() => active = value),
                  activeThumbColor: AppColors.success,
                  title: const Text('Ghe dang hoat dong',
                      style: TextStyle(color: Colors.white)),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Future<SeatBulkPayload?> showSeatBulkDialog(
  BuildContext context, {
  required List<SeatTypeResponse> seatTypes,
}) {
  final formKey = GlobalKey<FormState>();
  final rowsController = TextEditingController();
  final fromController = TextEditingController();
  final toController = TextEditingController();
  SeatTypeResponse selected = seatTypes.first;

  return showDialog<SeatBulkPayload>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AppDialogForm(
        title: 'Tao nhieu ghe',
        submitLabel: 'Tao hang loat',
        onSubmit: () {
          if (!formKey.currentState!.validate()) {
            return;
          }
          final from = int.parse(fromController.text.trim());
          final to = int.parse(toController.text.trim());
          final rows = rowsController.text
              .split(',')
              .map((item) => item.trim().toUpperCase())
              .where((item) => item.isNotEmpty)
              .toList();
          Navigator.of(dialogContext, rootNavigator: true).pop(
            SeatBulkPayload(
              rows: rows,
              numbers: [for (int value = from; value <= to; value++) value],
              seatTypeId: selected.id,
            ),
          );
        },
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: rowsController,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui long nhap danh sach hang ghe'
                    : null,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Hang ghe',
                  hintText: 'Vi du: A,B,C,D',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: fromController,
                      keyboardType: TextInputType.number,
                      validator: (value) => int.tryParse(value ?? '') == null
                          ? 'Nhap so hop le'
                          : null,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Tu so ghe'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: toController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final from = int.tryParse(fromController.text);
                        final to = int.tryParse(value ?? '');
                        if (to == null) return 'Nhap so hop le';
                        if (from != null && to < from) {
                          return 'Phai >= so bat dau';
                        }
                        return null;
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          const InputDecoration(labelText: 'Den so ghe'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SeatTypeResponse>(
                initialValue: selected,
                isExpanded: true,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Loai ghe'),
                items: seatTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_seatTypeDisplayName(type.name)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selected = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
