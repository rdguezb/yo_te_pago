import 'package:yo_te_pago/business/domain/entities/remittance.dart';


class RemittanceDto extends Remittance {

  RemittanceDto({
    required super.id,
    required super.customer,
    required super.amount,
    required super.createdAt,
    required super.state,
    required super.currencyId,
    required super.currencyName,
    required super.currencySymbol,
    required super.rate,
    required super.bankAccountId,
    required super.bankAccountName,
    required super.bankName,
    super.code
  });

  factory RemittanceDto.fromJson(Map<String, dynamic> json) {

    return RemittanceDto(
        id: (json['id'] as int?) ?? 0,
        customer: json['customer'],
        code: json['code'],
        createdAt: DateTime.parse(json['date']),
        amount: json['amount']?.toDouble(),
        state: json['state'],
        currencyId: (json['currency_id'] as int?) ?? 0,
        currencyName: json['currency_name'],
        currencySymbol: json['currency_symbol'],
        rate: json['rate']?.toDouble(),
        bankAccountId: (json['bank_id'] as int?) ?? 0,
        bankAccountName: json['acc_number'],
        bankName: json['bank_name']
    );
  }

  Remittance toModel() {

    return Remittance(
      id: id,
      customer: customer,
      code: code,
      createdAt: createdAt,
      amount: amount,
      state: state,
      currencyId: currencyId,
      currencyName: currencyName,
      currencySymbol: currencySymbol,
      rate: rate,
      bankAccountId: bankAccountId,
      bankAccountName: bankAccountName,
      bankName: bankName
    );
  }

}