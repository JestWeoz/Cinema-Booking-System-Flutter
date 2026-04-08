import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color cinemaPageAccent = AppColors.primary;
const Color cinemaPageAccentSoft = Color(0x33E50914);
const Color cinemaPageBackground = AppColors.backgroundDark;
const Color cinemaPageCard = AppColors.surfaceDark;
const Color cinemaPageCardAlt = AppColors.cardDark;
const Color cinemaPageText = AppColors.textPrimaryDark;
const Color cinemaPageMuted = AppColors.textSecondaryDark;
const Color cinemaPageBorder = AppColors.dividerDark;

DateTime parseShowtimeDateTime(String value) {
  return DateTime.tryParse(value) ?? DateTime(2000);
}

bool isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String weekdayLabel(DateTime value) {
  switch (value.weekday) {
    case DateTime.monday:
      return 'Thứ 2';
    case DateTime.tuesday:
      return 'Thứ 3';
    case DateTime.wednesday:
      return 'Thứ 4';
    case DateTime.thursday:
      return 'Thứ 5';
    case DateTime.friday:
      return 'Thứ 6';
    case DateTime.saturday:
      return 'Thứ 7';
    case DateTime.sunday:
      return 'C.Nhật';
  }
  return '';
}

String durationLabel(int minutes) {
  final hours = minutes ~/ 60;
  final remain = minutes % 60;
  if (hours == 0) {
    return '$remain phút';
  }
  return '$hours giờ ${remain.toString().padLeft(2, '0')} phút';
}

String moneyLabel(double value) {
  final formatter = NumberFormat('#,###', 'vi');
  return '${formatter.format(value)}đ';
}

String ageLabel(AgeRating rating) {
  return switch (rating) {
    AgeRating.P => 'P',
    AgeRating.C13 => '13+',
    AgeRating.C16 => '16+',
    AgeRating.C18 => '18+',
  };
}

String languageLabel(String? rawLanguage, Language? language) {
  if (rawLanguage != null && rawLanguage.trim().isNotEmpty) {
    return rawLanguage;
  }

  return switch (language) {
    Language.ORIGINAL => 'Nguyên bản',
    Language.DUBBED => 'Lồng tiếng',
    Language.SUBTITLED => 'Phụ đề',
    null => 'Định dạng chuẩn',
  };
}

class CinemaStatusView extends StatelessWidget {
  final IconData icon;
  final String message;
  final Future<void> Function()? onRetry;

  const CinemaStatusView({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onRetry == null ? cinemaPageMuted : cinemaPageAccent,
              size: 50,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: cinemaPageMuted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cinemaPageAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
