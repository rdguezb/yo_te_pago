class Role {

  final int? id;
  final String name;

  Role({
    this.id,
    required this.name
  });

  factory Role.fromJson(Map<String, dynamic> json) {

    return Role(
        id: (json['id'] as int?) ?? 0,
        name: json['name'] as String
    );
  }

}