import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_models.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_utils.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

class CinemaListView extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final List<CinemaBrandItem> brands;
  final String selectedBrand;
  final ValueChanged<String> onBrandChanged;
  final List<CinemaResponse> cinemas;
  final Set<String> favoriteCinemaIds;
  final ValueChanged<String> onFavoriteToggle;
  final Future<void> Function() onRefresh;
  final ValueChanged<CinemaResponse> onOpenCinema;
  final ValueChanged<CinemaResponse> onOpenDirection;

  const CinemaListView({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.brands,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.cinemas,
    required this.favoriteCinemaIds,
    required this.onFavoriteToggle,
    required this.onRefresh,
    required this.onOpenCinema,
    required this.onOpenDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Tìm rạp phim...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 112,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final item = brands[index];
              final selected = item.key == selectedBrand;
              return GestureDetector(
                onTap: () => onBrandChanged(item.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 92,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: item.key == '__all__'
                            ? const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.primary,
                              )
                            : AppNetworkImage(
                                url: item.logoUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                                borderRadius: 16,
                                backgroundColor: Colors.white,
                                fallbackIcon: Icons.theaters_rounded,
                                iconColor: AppColors.primary,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? AppColors.primary : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Rạp gần bạn (${cinemas.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location_rounded,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Gần bạn',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: cinemas.isEmpty
              ? const CinemaStatusView(
                  icon: Icons.location_off_outlined,
                  message: 'Không tìm thấy rạp phù hợp.',
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: onRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: cinemas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final cinema = cinemas[index];
                      final distance = cinemaDistanceForIndex(index);
                      final favorite = favoriteCinemaIds.contains(cinema.id);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => onOpenCinema(cinema),
                          child: Ink(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: AppNetworkImage(
                                        url: cinema.logoUrl,
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.contain,
                                        borderRadius: 22,
                                        backgroundColor: Colors.white,
                                        fallbackIcon: Icons.theaters_rounded,
                                        iconColor: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cinema.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(fontWeight: FontWeight.w800),
                                          ),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: TextSpan(
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(color: Colors.white70),
                                              children: [
                                                TextSpan(
                                                  text: cinemaDistanceLabel(distance),
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: ' • ${formatDistance(distance)}',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Text(
                                              'Đang mở bán vé',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        InkWell(
                                          onTap: () => onFavoriteToggle(cinema.id),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Ink(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.04),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Icon(
                                              favorite
                                                  ? Icons.favorite_rounded
                                                  : Icons.favorite_border_rounded,
                                              color: favorite
                                                  ? AppColors.primary
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Ink(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.04),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  cinema.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    if (cinema.phone != null &&
                                        cinema.phone!.isNotEmpty) ...[
                                      const Icon(Icons.phone_outlined,
                                          size: 16, color: Colors.white54),
                                      const SizedBox(width: 6),
                                      Text(
                                        cinema.phone!,
                                        style: const TextStyle(color: Colors.white54),
                                      ),
                                    ],
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => onOpenDirection(cinema),
                                      child: const Text('Tìm đường'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
