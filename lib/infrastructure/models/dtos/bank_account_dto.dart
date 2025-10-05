import 'package:yo_te_pago/business/domain/entities/bank_account.dart';


class BankAccountDto extends BankAccount {

  BankAccountDto({
    required super.id,
    required super.name,
    required super.bankName
  });

  factory BankAccountDto.fromJson(Map<String, dynamic> json) {

    return BankAccountDto(
        id: (json['id'] as int?) ?? 0,
        name: (json['acc_number'] as String?) ?? 'N/A',
        bankName: (json['bank_name'] as String?) ?? 'No Bank'
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
