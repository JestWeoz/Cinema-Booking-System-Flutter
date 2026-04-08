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
  final Future<void> Function() onRefresh;
  final ValueChanged<CinemaResponse> onOpenCinema;

  const CinemaListView({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.brands,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.cinemas,
    required this.onRefresh,
    required this.onOpenCinema,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cinemaPageCard,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: const TextStyle(color: cinemaPageText),
                  decoration: InputDecoration(
                    hintText: 'Tìm rạp phim...',
                    hintStyle: const TextStyle(color: cinemaPageMuted),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: cinemaPageMuted,
                    ),
                    filled: true,
                    fillColor: cinemaPageCardAlt,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: cinemaPageBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: cinemaPageAccent,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: brands.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      final item = brands[index];
                      final selected = item.key == selectedBrand;
                      return GestureDetector(
                        onTap: () => onBrandChanged(item.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 82,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? cinemaPageAccentSoft
                                : cinemaPageCardAlt,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? cinemaPageAccent
                                  : cinemaPageBorder,
                              width: selected ? 1.6 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: cinemaPageCard,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: item.key == '__all__'
                                    ? const Icon(
                                        Icons.theaters_rounded,
                                        color: cinemaPageAccent,
                                      )
                                    : AppNetworkImage(
                                        url: item.logoUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.contain,
                                        borderRadius: 14,
                                        backgroundColor: cinemaPageCard,
                                        fallbackIcon: Icons.theaters_rounded,
                                        iconColor: cinemaPageAccent,
                                      ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected
                                      ? cinemaPageAccent
                                      : cinemaPageText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            'Danh sách rạp (${cinemas.length})',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cinemaPageText,
                ),
          ),
        ),
        Expanded(
          child: cinemas.isEmpty
              ? const CinemaStatusView(
                  icon: Icons.location_off_outlined,
                  message: 'Không tìm thấy rạp phù hợp.',
                )
              : RefreshIndicator(
                  color: cinemaPageAccent,
                  onRefresh: onRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: cinemas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final cinema = cinemas[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => onOpenCinema(cinema),
                          child: Ink(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cinemaPageCard,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: cinemaPageBorder),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: cinemaPageCardAlt,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: AppNetworkImage(
                                        url: cinema.logoUrl,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.contain,
                                        borderRadius: 18,
                                        backgroundColor: cinemaPageCardAlt,
                                        fallbackIcon: Icons.theaters_rounded,
                                        iconColor: cinemaPageAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cinema.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: cinemaPageText,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            cinemaBrandOf(cinema),
                                            style: const TextStyle(
                                              color: cinemaPageAccent,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: cinemaPageMuted,
                                      size: 28,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  cinema.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: cinemaPageMuted,
                                    height: 1.4,
                                  ),
                                ),
                                if (cinema.phone?.isNotEmpty == true) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 16,
                                        color: cinemaPageMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        cinema.phone!,
                                        style: const TextStyle(
                                          color: cinemaPageMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
