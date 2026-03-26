import 'package:equatable/equatable.dart';

class CinemaEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? phoneNumber;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  const CinemaEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.phoneNumber,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [id];
}
