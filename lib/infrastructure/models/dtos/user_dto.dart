import 'package:yo_te_pago/business/domain/entities/user.dart';

class UserDto extends User {

  UserDto({
    required super.id,
    required super.partnerId,
    required super.name,
    required super.role,
    required super.login,
    required super.email
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {

    return UserDto(
        id: (json['id'] as int?) ?? 0,
        partnerId: (json['partner_id'] as int?) ?? 0,
        name: json['name'] as String,
        role: json['role'] as String,
        login: json['login'] as String,
        email: json['email'] as String);
  }

  User toModel() {

    return User(
        id: id,
        partnerId: partnerId,
        name: name,
        role: role,
        login: login,
        email: email);
  }

}