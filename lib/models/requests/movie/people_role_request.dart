import 'package:cinema_booking_system_app/models/enums.dart';

class PeopleRoleRequest {
  final String peopleId;
  final MovieRole role;

  const PeopleRoleRequest({required this.peopleId, required this.role});

  Map<String, dynamic> toJson() => {
        'peopleId': peopleId,
        'role': role.name,
      };
}
