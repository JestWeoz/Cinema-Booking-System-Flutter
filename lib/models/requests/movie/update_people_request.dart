class UpdatePeopleRequest {
  final String? name;
  final String? nation;
  final String? avatarUrl;
  final DateTime? dob;

  const UpdatePeopleRequest({
    this.name,
    this.nation,
    this.avatarUrl,
    this.dob,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (nation != null) map['nation'] = nation;
    if (avatarUrl != null) map['avatarUrl'] = avatarUrl;
    if (dob != null) map['dob'] = dob!.toIso8601String().split('T').first;
    return map;
  }
}
