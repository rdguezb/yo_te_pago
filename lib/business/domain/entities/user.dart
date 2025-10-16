class User {

  int? id;
  final int partnerId;
  final String name;
  final String role;
  final String login;
  final String? email;

  User({
    this.id,
    required this.partnerId,
    required this.name,
    required this.role,
    required this.login,
    this.email
  });

  factory User.fromJson(Map<String, dynamic> json) {

    return User(
        id: (json['id'] as int?) ?? 0,
        partnerId: (json['partner_id'] as int?) ?? 0,
        name: json['name'] as String,
        role: json['role'] as String,
        login: json['login'] as String,
        email: json['email'] as String);
  }

  User copyWith({
    int? id,
    int? partnerId,
    String? name,
    String? role,
    String? login,
    String? email
  }) {

    return User(
        id: id ?? this.id,
        partnerId: partnerId ?? this.partnerId,
        name: name ?? this.name,
        role: role ?? this.role,
        login: login ?? this.login,
        email: email ?? this.email);
  }

  Map<String, dynamic> toMap() {

    return {
      'name': name,
      'role': role,
      'login': login,
      'email': email
    };
  }

}