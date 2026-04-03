import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/pages/login_page.dart';
import 'package:cinema_booking_system_app/pages/register_page.dart';
import 'package:cinema_booking_system_app/pages/home_page.dart';
import 'package:cinema_booking_system_app/pages/movie_detail_page.dart';
import 'package:cinema_booking_system_app/pages/seat_selection_page.dart';
import 'package:cinema_booking_system_app/pages/profile_page.dart';
import 'package:cinema_booking_system_app/pages/tickets_page.dart';
import 'package:cinema_booking_system_app/pages/schedules_page.dart';
import 'package:cinema_booking_system_app/pages/offers_page.dart';
import 'package:cinema_booking_system_app/pages/edit_profile_page.dart';
import 'package:cinema_booking_system_app/pages/change_password_page.dart';
import 'package:cinema_booking_system_app/pages/notifications_page.dart';
import 'package:cinema_booking_system_app/pages/user_settings_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_menu_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_movie_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_showtime_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_voucher_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_user_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_cinema_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_room_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_stat_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_settings_page.dart';
import 'package:cinema_booking_system_app/app/shell/main_shell.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
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
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'changePassword',
        builder: (_, __) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (_, __) => const UserSettingsPage(),
      ),

      // ─── Admin (no bottom nav shell) ─────────────────────────────────────
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        builder: (_, __) => const AdminMenuPage(),
      ),
      GoRoute(
        path: AppRoutes.adminMovies,
        name: 'adminMovies',
        builder: (_, __) => const AdminMovieListPage(),
      ),
      GoRoute(
        path: AppRoutes.adminShowtimes,
        name: 'adminShowtimes',
        builder: (_, __) => const AdminShowtimeListPage(),
      ),
      GoRoute(
        path: AppRoutes.adminVouchers,
        name: 'adminVouchers',
        builder: (_, __) => const AdminVoucherListPage(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        name: 'adminUsers',
        builder: (_, __) => const AdminUserListPage(),
      ),
      GoRoute(
        path: AppRoutes.adminStaff,
        name: 'adminStaff',
        builder: (_, __) => const AdminUserListPage(staffOnly: true),
      ),
      GoRoute(
        path: AppRoutes.adminCinema,
        name: 'adminCinema',
        builder: (_, __) => const AdminCinemaListPage(),
      ),
      GoRoute(
        path: AppRoutes.adminRooms,
        name: 'adminRooms',
        builder: (context, state) {
          final cinemaId = state.uri.queryParameters['cinemaId'] ?? '';
          final cinemaName = state.uri.queryParameters['cinemaName'] ?? '';
          return AdminRoomListPage(cinemaId: cinemaId, cinemaName: cinemaName);
        },
      ),
      GoRoute(
        path: AppRoutes.adminStats,
        name: 'adminStats',
        builder: (_, __) => const AdminStatPage(),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        name: 'adminSettings',
        builder: (_, __) => const AdminSettingsPage(),
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
            path: AppRoutes.schedules,
            name: 'schedules',
            builder: (_, __) => const SchedulesPage(),
          ),
          GoRoute(
            path: AppRoutes.offers,
            name: 'offers',
            builder: (_, __) => const OffersPage(),
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
