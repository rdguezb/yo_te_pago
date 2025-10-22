class User {

  int? id;
  final int partnerId;
  final String name;
  final int roleId;
  final String roleName;
  final String login;
  final String? email;

  User({
    this.id,
    required this.partnerId,
    required this.name,
    required this.roleId,
    required this.roleName,
    required this.login,
    this.email
  });

  factory User.fromJson(Map<String, dynamic> json) {

    return User(
      id: (json['uid'] as int?) ?? (json['id'] as int?),
      partnerId: (json['partner_id'] as int?) ?? 0,
      name: (json['name'] as String?) ?? '',
      login: (json['username'] as String?) ?? (json['login'] as String?) ?? '',
      email: json['email'] as String?,
      roleId: (json['role_id'] as int?) ?? 0,
      roleName: (json['role_name'] as String?) ?? 'N/A',
    );
  }

  User copyWith({
    int? id,
    int? partnerId,
    String? name,
    int? roleId,
    String? roleName,
    String? login,
    String? email
  }) {

    return User(
        id: id ?? this.id,
        partnerId: partnerId ?? this.partnerId,
        name: name ?? this.name,
        roleId: roleId ?? this.roleId,
        roleName: roleName ?? this.roleName,
        login: login ?? this.login,
        email: email ?? this.email);
  }

  Map<String, dynamic> toMap() {

    return {
      'name': name,
      'login': login,
      'role_id': roleId,
      'email': email
    };
  }

}
