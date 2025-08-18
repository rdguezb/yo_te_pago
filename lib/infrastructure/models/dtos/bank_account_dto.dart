import 'package:yo_te_pago/business/domain/entities/bank_account.dart';


class BankAccountDto extends BankAccount {

  BankAccountDto({
    required super.id,
    required super.name,
    required super.bankName
  });

  factory BankAccountDto.fromJson(Map<String, dynamic> json) {

    return BankAccountDto(
        id: json['id'],
        name: json['acc_number'],
        bankName: json['bank_name']
    );
  }

  BankAccount toModel() {

    return BankAccount(
        id: id,
        name: name,
        bankName: bankName
    );
  }

}
