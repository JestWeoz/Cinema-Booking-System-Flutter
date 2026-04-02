import 'package:cinema_booking_system_app/models/enums.dart';

class UpdateMovieStatusRequest {
  final MovieStatus status;

  const UpdateMovieStatusRequest({required this.status});

  Map<String, dynamic> toJson() => {'status': status.name};
}
