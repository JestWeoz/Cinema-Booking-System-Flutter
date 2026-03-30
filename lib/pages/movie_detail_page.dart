import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/models/movie_model.dart';
import 'package:cinema_booking_system_app/services/movie_service.dart';

class MovieDetailPage extends StatefulWidget {
  final String movieId;

  const MovieDetailPage({super.key, required this.movieId});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  MovieModel? _movie;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovie();
  }

  Future<void> _loadMovie() async {
    try {
      final movie = await MovieService.instance.getById(widget.movieId);
      if (mounted) setState(() { _movie = movie; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Không tải được phim', style: Theme.of(context).textTheme.bodyMedium),
                      TextButton(onPressed: () => context.pop(), child: const Text('Quay lại')),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _movie!.posterUrl.isNotEmpty
                            ? Image.network(
                                _movie!.posterUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.cardDark,
                                  child: const Center(child: Icon(Icons.movie, size: 80, color: Colors.grey)),
                                ),
                              )
                            : Container(
                                color: AppColors.cardDark,
                                child: const Center(child: Icon(Icons.movie, size: 80, color: Colors.grey)),
                              ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(_movie!.title, style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.secondary, size: 18),
                              const SizedBox(width: 4),
                              Text(_movie!.rating.toStringAsFixed(1),
                                  style: const TextStyle(color: AppColors.secondary)),
                              const SizedBox(width: 12),
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(_movie!.formattedDuration,
                                  style: const TextStyle(color: Colors.grey)),
                              const SizedBox(width: 12),
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(_movie!.releaseDate,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          if (_movie!.genres.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: _movie!.genres.map((g) => Chip(
                                label: Text(g, style: const TextStyle(fontSize: 11)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              )).toList(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text('Overview', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(_movie!.overview, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _movie == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.seatSelection),
                child: const Text('Book Tickets'),
              ),
            ),
    );
  }
}
