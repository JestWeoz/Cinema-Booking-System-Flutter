import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/features/auth/presentation/pages/login_page.dart';
import 'package:cinema_booking_system_app/features/auth/presentation/pages/register_page.dart';
import 'package:cinema_booking_system_app/features/home/presentation/pages/home_page.dart';
import 'package:cinema_booking_system_app/features/movies/presentation/pages/movie_detail_page.dart';
import 'package:cinema_booking_system_app/features/booking/presentation/pages/seat_selection_page.dart';
import 'package:cinema_booking_system_app/features/profile/presentation/pages/profile_page.dart';
import 'package:cinema_booking_system_app/features/ticket/presentation/pages/tickets_page.dart';
import 'package:cinema_booking_system_app/app/shell/main_shell.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterPage(),
      ),

      // Main app shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.movieDetail,
            name: 'movieDetail',
            builder: (context, state) => MovieDetailPage(
              movieId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.seatSelection,
            name: 'seatSelection',
            builder: (_, __) => const SeatSelectionPage(),
          ),
          GoRoute(
            path: AppRoutes.tickets,
            name: 'tickets',
            builder: (_, __) => const TicketsPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (_, __) => const ProfilePage(),
          ),
        ],
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}
