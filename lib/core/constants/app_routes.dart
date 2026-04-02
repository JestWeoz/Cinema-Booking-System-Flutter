// Route names - centralized route constants
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main
  static const String home = '/home';
  static const String movies = '/movies';
  static const String movieDetail = '/movies/:id';
  static const String search = '/search';
  static const String schedules = '/schedules';
  static const String offers = '/offers';

  // Booking Flow
  static const String cinemas = '/cinemas';
  static const String showtime = '/showtime';
  static const String seatSelection = '/seat-selection';
  static const String checkout = '/checkout';
  static const String payment = '/payment';
  static const String bookingSuccess = '/booking-success';

  // Profile & Tickets
  static const String profile = '/profile';
  static const String tickets = '/tickets';
  static const String ticketDetail = '/tickets/:id';
  static const String editProfile = '/edit-profile';
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  // Admin
  static const String admin = '/admin';
  static const String adminMovies = '/admin/movies';
  static const String adminShowtimes = '/admin/showtimes';
  static const String adminVouchers = '/admin/vouchers';
  static const String adminUsers = '/admin/users';
  static const String adminStaff = '/admin/staff';
  static const String adminCinema = '/admin/cinema';
  static const String adminRooms = '/admin/rooms';
  static const String adminSeats = '/admin/seats';
  static const String adminStats = '/admin/stats';
  static const String adminSettings = '/admin/settings';
}
