class User {

  int? id;
  final String name;

  User({
    this.id,
    required this.name
  });

  factory User.fromJson(Map<String, dynamic> json) {

    return User(
        id: (json['id'] as int?) ?? 0,
        name: json['name']
    );
  }
  
}