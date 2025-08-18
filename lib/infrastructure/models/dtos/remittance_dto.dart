import 'package:yo_te_pago/business/domain/entities/remittance.dart';


class RemittanceDto extends Remittance {

  RemittanceDto({
    required super.id,
    required super.customer,
    required super.amount,
    required super.createdAt,
    required super.currencyId,
    required super.bankAccountId,
    required super.rate,
    required super.state,
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
        bankAccountId: (json['bank_account_id'] as int?) ?? 0,
        rate: json['rate']?.toDouble()
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
      bankAccountId: bankAccountId,
      rate: rate
    );
  }

}