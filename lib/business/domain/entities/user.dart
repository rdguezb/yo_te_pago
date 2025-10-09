class User {

  int? id;
  final int userId;
  final String name;
  final String role;
  final String login;
  final String? email;

  User({
    this.id,
    required this.userId,
    required this.name,
    required this.role,
    required this.login,
    this.email
  });

  factory User.fromJson(Map<String, dynamic> json) {

    return User(
        id: (json['id'] as int?) ?? 0,
        userId: (json['user_id'] as int?) ?? 0,
        name: json['name'] as String,
        role: json['role'] as String,
        login: json['login'] as String,
        email: json['email'] as String);
  }

  User copyWith({
    int? id,
    int? userId,
    String? name,
    String? role,
    String? login,
    String? email
  }) {

    return User(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        role: role ?? this.role,
        login: login ?? this.login,
        email: email ?? this.email);
  }

  Map<String, dynamic> toMap() {

    return {
      'user_id': userId,
      'name': name,
      'role': role,
      'login': login,
      'email': email
    };
  }

}