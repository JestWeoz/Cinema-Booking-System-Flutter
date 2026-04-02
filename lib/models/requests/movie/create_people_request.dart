class CreatePeopleRequest {
  final String name;
  final String nation;
  final String avatarUrl;
  final DateTime? dob;

  const CreatePeopleRequest({
    required this.name,
    required this.nation,
    required this.avatarUrl,
    this.dob,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'nation': nation,
        'avatarUrl': avatarUrl,
        'dob': dob?.toIso8601String().split('T').first,
      };
}
