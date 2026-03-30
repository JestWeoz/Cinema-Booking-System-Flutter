import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

/// Trang Lịch Chiếu — tìm theo phim hoặc theo rạp
class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Chiếu'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.movie_outlined), text: 'Theo Phim'),
            Tab(icon: Icon(Icons.location_on_outlined), text: 'Theo Rạp'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Tìm phim hoặc rạp...',
              leading: const Icon(Icons.search),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ByMovieTab(query: _searchController.text),
                _ByCinemaTab(query: _searchController.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Theo Phim ──────────────────────────────────
class _ByMovieTab extends StatelessWidget {
  final String query;
  const _ByMovieTab({required this.query});

  static const List<Map<String, String>> _movies = [
    {'title': 'Avengers: Doomsday', 'genre': 'Action • Sci-Fi', 'time': '2h 30m'},
    {'title': 'Minecraft Movie', 'genre': 'Adventure • Comedy', 'time': '1h 50m'},
    {'title': 'Mission Impossible 8', 'genre': 'Action • Thriller', 'time': '2h 15m'},
    {'title': 'Moana 2', 'genre': 'Animation • Family', 'time': '1h 40m'},
    {'title': 'Inside Out 3', 'genre': 'Animation • Drama', 'time': '1h 35m'},
  ];

  @override
  Widget build(BuildContext context) {
    final items = query.isEmpty
        ? _movies
        : _movies.where((m) => m['title']!.toLowerCase().contains(query.toLowerCase())).toList();

    if (items.isEmpty) {
      return const Center(child: Text('Không tìm thấy phim', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final m = items[i];
        return _MovieScheduleCard(title: m['title']!, genre: m['genre']!, duration: m['time']!);
      },
    );
  }
}

class _MovieScheduleCard extends StatelessWidget {
  final String title;
  final String genre;
  final String duration;
  const _MovieScheduleCard({required this.title, required this.genre, required this.duration});

  static const List<String> _times = ['09:00', '11:30', '14:00', '16:30', '19:00', '21:30'];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50, height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.dividerDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.movie, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      Text(genre, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(duration, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Suất chiếu hôm nay:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _times.map((t) => GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t, style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                    ),
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab: Theo Rạp ────────────────────────────────────
class _ByCinemaTab extends StatelessWidget {
  final String query;
  const _ByCinemaTab({required this.query});

  static const List<Map<String, String>> _cinemas = [
    {'name': 'CGV Vincom Center', 'address': 'Vincom Center, Q.1, TP.HCM', 'screens': '8 phòng chiếu'},
    {'name': 'Lotte Cinema Nowzone', 'address': 'Nowzone, Q.1, TP.HCM', 'screens': '6 phòng chiếu'},
    {'name': 'Galaxy Nguyễn Du', 'address': '116 Nguyễn Du, Q.1, TP.HCM', 'screens': '5 phòng chiếu'},
    {'name': 'BHD Star Bitexco', 'address': 'Bitexco, Q.1, TP.HCM', 'screens': '7 phòng chiếu'},
  ];

  @override
  Widget build(BuildContext context) {
    final items = query.isEmpty
        ? _cinemas
        : _cinemas.where((c) => c['name']!.toLowerCase().contains(query.toLowerCase())).toList();

    if (items.isEmpty) {
      return const Center(child: Text('Không tìm thấy rạp', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final c = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.theaters, color: Colors.white, size: 22),
            ),
            title: Text(c['name']!),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['address']!, style: const TextStyle(fontSize: 12)),
                Text(c['screens']!, style: const TextStyle(color: AppColors.secondary, fontSize: 11)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),
        );
      },
    );
  }
}
