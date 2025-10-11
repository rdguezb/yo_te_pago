import 'package:yo_te_pago/business/domain/entities/bank.dart';


class BankDto extends Bank {

  BankDto({
    required super.id,
    required super.name
  });

  factory BankDto.fromJson(Map<String, dynamic> json) {

    return BankDto(
        id: (json['id'] as int?) ?? 0,
        name: (json['name'] as String?) ?? 'N/A'
    );
  }

  Bank toModel() {

    return Bank(
        id: id,
        name: name
    );
  }

}
