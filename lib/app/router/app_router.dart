import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/pages/login_page.dart';
import 'package:cinema_booking_system_app/pages/register_page.dart';
import 'package:cinema_booking_system_app/pages/home_page.dart';
import 'package:cinema_booking_system_app/pages/movie_catalog_page.dart';
import 'package:cinema_booking_system_app/pages/movie_detail_page.dart';
import 'package:cinema_booking_system_app/pages/movie_search_page.dart';
import 'package:cinema_booking_system_app/pages/seat_selection_page.dart';
import 'package:cinema_booking_system_app/pages/profile_page.dart';
import 'package:cinema_booking_system_app/pages/tickets_page.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_pages.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_schedule_page.dart';
import 'package:cinema_booking_system_app/pages/offers_page.dart';
import 'package:cinema_booking_system_app/pages/edit_profile_page.dart';
import 'package:cinema_booking_system_app/pages/change_password_page.dart';
import 'package:cinema_booking_system_app/pages/notifications_page.dart';
import 'package:cinema_booking_system_app/pages/user_settings_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_menu_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_movie_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_showtime_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/showtime/admin_showtime_form_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_voucher_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_user_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/cinema/admin_cinema_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_stat_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_settings_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_category_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_product_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_people_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/cinema/admin_room_list_page.dart';
import 'package:cinema_booking_system_app/pages/admin/cinema/admin_seat_list_page.dart';
import 'package:cinema_booking_system_app/pages/staff/staff_checkin_page.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_payment_result_page.dart';
import 'package:cinema_booking_system_app/app/shell/main_shell.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: false,
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
      GoRoute(
        path: AppRoutes.paymentResult,
        name: 'paymentResult',
        builder: (_, state) => BookingPaymentResultPage(
          bookingId: state.uri.queryParameters['bookingId'] ?? '',
          bookingCode: state.uri.queryParameters['bookingCode'],
          rawStatus: state.uri.queryParameters['status'],
          responseCode: state.uri.queryParameters['responseCode'],
          transactionId: state.uri.queryParameters['transactionId'],
        ),
      ),

      // ─── Admin (no bottom nav shell) ─────────────────────────────────────
      GoRoute(
        path: AppRoutes.movieCatalog,
        name: 'movieCatalog',
        builder: (_, state) => MovieCatalogPage(
          section: state.pathParameters['section'] ?? 'now-showing',
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (_, __) => const MovieSearchPage(),
      ),
      GoRoute(
        path: AppRoutes.movieDetail,
        name: 'movieDetail',
        builder: (context, state) => MovieDetailPage(
          movieId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        builder: (_, __) => const AdminMenuPage(),
      ),
      GoRoute(
        path: AppRoutes.staff,
        name: 'staff',
        builder: (_, __) => const StaffCheckInPage(),
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
        path: AppRoutes.adminShowtimeCreate,
        name: 'adminShowtimeCreate',
        builder: (_, __) => const AdminShowtimeFormPage(),
      ),
      GoRoute(
        path: AppRoutes.adminShowtimeEdit,
        name: 'adminShowtimeEdit',
        builder: (_, state) => AdminShowtimeFormPage(
          showtimeId: state.pathParameters['id'],
        ),
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
        path: AppRoutes.adminSeats,
        name: 'adminSeats',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId'] ?? '';
          final roomName = state.uri.queryParameters['roomName'] ?? '';
          final cinemaName = state.uri.queryParameters['cinemaName'] ?? '';
          return AdminSeatListPage(
            roomId: roomId,
            roomName: roomName,
            cinemaName: cinemaName,
          );
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
      GoRoute(
        path: AppRoutes.adminCategories,
        name: 'adminCategories',
        builder: (_, __) => const AdminCategoryListPage(),
      ),
      GoRoute(
        path: AppRoutes.adminProducts,
        name: 'adminProducts',
        builder: (_, __) => const AdminProductListPage(),
      ),
      GoRoute(
        path: AppRoutes.adminPeople,
        name: 'adminPeople',
        builder: (_, __) => const AdminPeopleListPage(),
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
            builder: (_, __) => const CinemaPages(),
          ),
          GoRoute(
            path: AppRoutes.scheduleDetail,
            name: 'scheduleDetail',
            builder: (_, state) => CinemaSchedulePage(
              cinemaId: state.pathParameters['cinemaId'] ?? '',
            ),
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
    errorBuilder: (context, state) {
      if (kDebugMode) {
        debugPrint('Router error: ${state.error}');
      }
      return Scaffold(
        body: Center(
          child: Text('Không tìm thấy trang: ${state.error}'),
        ),
      );
    },
  );
}
