import 'package:cinema_booking_system_app/models/requests/movie/people_role_request.dart';

class AddPeopleToMovieRequest {
  final List<PeopleRoleRequest> people;

  const AddPeopleToMovieRequest({required this.people});

  Map<String, dynamic> toJson() => {
        'people': people.map((p) => p.toJson()).toList(),
      };
}
