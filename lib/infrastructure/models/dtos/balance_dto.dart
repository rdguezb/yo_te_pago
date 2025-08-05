import 'package:yo_te_pago/business/domain/entities/balance.dart';


class BalanceDto extends Balance {

  BalanceDto({
    required super.name,
    required super.fullName,
    required super.debit,
    required super.credit,
    required super.balance
  });

  factory BalanceDto.fromJson(Map<String, dynamic> json) {

    return BalanceDto(
        name: json['name'],
        fullName: json['fullName'],
        debit: json['debit']?.toDouble(),
        credit: json['credit']?.toDouble(),
        balance: json['balance']?.toDouble()
    );
  }

  Balance toModel() {

    return Balance(
      name: name,
      fullName: fullName,
      debit: debit,
      credit: credit,
      balance: balance
    );
  }

}
