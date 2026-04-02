// models/models.dart — Barrel export cho toàn bộ models
// Dùng: import 'package:cinema_booking_system_app/models/models.dart';

// Enums
export 'enums.dart';

// ─── Requests ─────────────────────────────────────────────────────────────
export 'requests/auth_requests.dart';
export 'requests/user_requests.dart';
export 'requests/create_booking_request.dart';
export 'requests/payment_requests.dart';
export 'requests/showtime_requests.dart';
export 'requests/seat_requests.dart';
export 'requests/movie_requests.dart';

// ─── Responses ────────────────────────────────────────────────────────────
export 'responses/api_response.dart';
export 'responses/paginated_response.dart';
export 'responses/auth_response.dart';
export 'responses/movie_response.dart';
export 'responses/showtime_response.dart';
export 'responses/booking_response.dart';
export 'responses/ticket_response.dart';
export 'responses/payment_response.dart';
export 'responses/misc_responses.dart';

// ─── Domain Models ────────────────────────────────────────────────────────
export 'user_model.dart';
export 'movie_model.dart';
export 'booking_model.dart';
