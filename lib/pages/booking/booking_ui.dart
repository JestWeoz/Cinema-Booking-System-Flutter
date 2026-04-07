import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';

String bookingFormatCurrency(num value) {
  final formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );
  return formatter.format(value);
}

String bookingFormatDate(DateTime value) => DateFormat('dd/MM').format(value);

String bookingFormatWeekday(DateTime value) {
  const labels = [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'CN',
  ];
  return labels[value.weekday - 1];
}

String bookingFormatDateLong(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value);
}

String bookingFormatTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return DateFormat('HH:mm').format(parsed.toLocal());
}

String bookingFormatDateTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return DateFormat('HH:mm • dd/MM/yyyy').format(parsed.toLocal());
}

String bookingFormatTimeRange(String start, String end) {
  return '${bookingFormatTime(start)} ~ ${bookingFormatTime(end)}';
}

String bookingAgeLabel(AgeRating? value) {
  switch (value) {
    case AgeRating.C13:
      return '13+';
    case AgeRating.C16:
      return '16+';
    case AgeRating.C18:
      return '18+';
    case AgeRating.P:
      return 'P';
    default:
      return 'T';
  }
}

Color bookingSeatFillColor(SeatTypeEnum? type, {required bool selected}) {
  if (selected) return AppColors.primary;
  switch (type) {
    case SeatTypeEnum.VIP:
      return const Color(0xFF2E2411);
    case SeatTypeEnum.COUPLE:
      return const Color(0xFF311D27);
    case SeatTypeEnum.STANDARD:
    default:
      return const Color(0xFF221A31);
  }
}

Color bookingSeatBorderColor(SeatTypeEnum? type, {required bool selected}) {
  if (selected) return AppColors.primaryLight;
  switch (type) {
    case SeatTypeEnum.VIP:
      return const Color(0xFFD9A400);
    case SeatTypeEnum.COUPLE:
      return const Color(0xFFE27AA8);
    case SeatTypeEnum.STANDARD:
    default:
      return const Color(0xFFA575FF);
  }
}

Color bookingSeatTextColor(SeatTypeEnum? type, {required bool selected}) {
  if (selected) return Colors.white;
  switch (type) {
    case SeatTypeEnum.VIP:
      return const Color(0xFFFFD76A);
    case SeatTypeEnum.COUPLE:
      return const Color(0xFFFF9BC7);
    case SeatTypeEnum.STANDARD:
    default:
      return const Color(0xFFE0CCFF);
  }
}

class BookingPageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;

  const BookingPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.bottomNavigationBar,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: actions,
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6AA2).withValues(alpha: 0.10),
              AppColors.backgroundDark,
              AppColors.backgroundDark,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: child,
      ),
    );
  }
}

class BookingSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const BookingSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: child,
    );
  }
}

class BookingMovieStrip extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final AgeRating? ageRating;
  final String subtitle;

  const BookingMovieStrip({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.ageRating,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return BookingSectionCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AppNetworkImage(
              url: posterUrl,
              width: 74,
              height: 104,
              fit: BoxFit.cover,
              fallbackIcon: Icons.movie_outlined,
              backgroundColor: AppColors.cardDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        bookingAgeLabel(ageRating),
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookingBottomBar extends StatelessWidget {
  final String label;
  final String value;
  final String buttonText;
  final VoidCallback? onPressed;
  final String? note;
  final bool loading;

  const BookingBottomBar({
    super.key,
    required this.label,
    required this.value,
    required this.buttonText,
    required this.onPressed,
    this.note,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (note != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          note!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: loading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
