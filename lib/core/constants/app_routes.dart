class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String home = '/home';
  static const String movies = '/movies';
  static const String movieDetail = '/movies/:id';
  static const String movieCatalog = '/movie-catalog/:section';
  static const String search = '/search';
  static const String schedules = '/schedules';
  static const String scheduleDetail = '/schedules/:cinemaId';
  static const String offers = '/offers';

  static const String cinemas = '/cinemas';
  static const String showtime = '/showtime';
  static const String seatSelection = '/seat-selection';
  static const String checkout = '/checkout';
  static const String payment = '/payment';
  static const String paymentResult = '/payment-result';
  static const String bookingSuccess = '/booking-success';

  static const String profile = '/profile';
  static const String tickets = '/tickets';
  static const String ticketDetail = '/tickets/:id';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  static const String admin = '/admin';
  static const String adminMovies = '/admin/movies';
  static const String adminShowtimes = '/admin/showtimes';
  static const String adminShowtimeCreate = '/admin/showtimes/create';
  static const String adminShowtimeEdit = '/admin/showtimes/:id/edit';
  static const String adminVouchers = '/admin/vouchers';
  static const String adminUsers = '/admin/users';
  static const String adminCinema = '/admin/cinema';
  static const String adminRooms = '/admin/rooms';
  static const String adminSeats = '/admin/seats';
  static const String adminStats = '/admin/stats';
  static const String adminSettings = '/admin/settings';
  static const String adminCategories = '/admin/categories';
  static const String adminProducts = '/admin/products';
  static const String adminPeople = '/admin/people';

  static String adminShowtimeEditById(String id) => '/admin/showtimes/$id/edit';
  static String movieCatalogBySection(String section) =>
      '/movie-catalog/$section';
  static String scheduleByCinemaId(String cinemaId) => '/schedules/$cinemaId';
}
