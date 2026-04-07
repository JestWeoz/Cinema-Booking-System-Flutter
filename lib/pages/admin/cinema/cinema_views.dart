import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';

class CinemaCard extends StatelessWidget {
  final CinemaResponse cinema;
  final VoidCallback onOpenRooms;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const CinemaCard({
    super.key,
    required this.cinema,
    required this.onOpenRooms,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = cinema.status == Status.ACTIVE;
    final badgeColor = isActive ? AppColors.success : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: (cinema.logoUrl ?? '').trim().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AppNetworkImage(
                          url: cinema.logoUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          borderRadius: 14,
                          fallbackIcon: Icons.theaters_outlined,
                          backgroundColor: AppColors.surfaceDark,
                        ),
                      )
                    : Text(
                        cinema.name.isEmpty
                            ? '?'
                            : cinema.name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cinema.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cinema.address,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (_) => onToggle(),
                activeThumbColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if ((cinema.phone ?? '').trim().isNotEmpty)
                _CinemaPill(icon: Icons.phone_outlined, text: cinema.phone!.trim()),
              if ((cinema.hotline ?? '').trim().isNotEmpty)
                _CinemaPill(icon: Icons.support_agent_outlined, text: cinema.hotline!.trim()),
              _CinemaPill(
                icon: Icons.circle,
                text: isActive ? 'Hoạt động' : 'Tạm dừng',
                color: badgeColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenRooms,
                  icon: const Icon(Icons.meeting_room_outlined, size: 18),
                  label: const Text(
                    'Phòng chiếu',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: Colors.white54),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CinemaErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const CinemaErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 44),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class CinemaEmptyView extends StatelessWidget {
  const CinemaEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.theaters_outlined, size: 56, color: Colors.white.withValues(alpha: 0.18)),
            const SizedBox(height: 14),
            const Text(
              'Chưa có rạp nào',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tạo rạp đầu tiên để bắt đầu quản trị phòng chiếu và ghế.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _CinemaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _CinemaPill({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: effectiveColor, size: 12),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: effectiveColor, fontSize: 11)),
        ],
      ),
    );
  }
}
