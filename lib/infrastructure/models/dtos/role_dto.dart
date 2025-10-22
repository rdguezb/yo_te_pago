import 'package:yo_te_pago/business/domain/entities/role.dart';

class RoleDto extends Role {

  RoleDto({
    required super.id,
    required super.name
  });

  factory RoleDto.fromJson(Map<String, dynamic> json) {

    return RoleDto(
        id: (json['id'] as int?) ?? 0,
        name: json['name'] as String
    );
  }

  Role toModel() {

    return Role(
        id: id,
        name: name);
  }

}