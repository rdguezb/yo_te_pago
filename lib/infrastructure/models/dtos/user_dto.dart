import 'package:yo_te_pago/business/domain/entities/user.dart';

class UserDto extends User {

  UserDto({
    required super.id,
    required super.name
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {

    return UserDto(
        id: (json['id'] as int?) ?? 0,
        name: json['name']
    );
  }

  User toModel() {

    return User(
        id: id,
        name: name
    );
  }



}