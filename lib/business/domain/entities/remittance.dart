import 'package:yo_te_pago/business/config/helpers/human_formats.dart';


class Remittance {

  int? id;
  String customer;
  double amount;
  DateTime createdAt;
  int currencyId;
  double rate;
  String? code;
  String? state;

  Remittance({
    this.id,
    required this.customer,
    this.code,
    required this.createdAt,
    required this.amount,
    this.state,
    required this.currencyId,
    required this.rate
  });

  factory Remittance.fromJson(Map<String, dynamic> json) {

    return Remittance(
        id: (json['id'] as int?) ?? 0,
        customer: json['customer'],
        code: json['code'],
        createdAt: DateTime.parse(json['date']),
        amount: json['amount']?.toDouble(),
        state: json['state'],
        currencyId: (json['currency_id'] as int?) ?? 0,
        rate: json['rate']?.toDouble()
    );
  }

  bool get isPaid => state == 'paid';
  bool get isConfirmed => state == 'confirmed';
  bool get isWaiting => state == 'waiting';
  bool get isCanceled => state == 'cancelled';

  Remittance copyWith({
    int? id,
    String? customer,
    String? code,
    DateTime? createdAt,
    double? amount,
    int? currencyId,
    String? state,
    double? rate
  }) {
    return Remittance(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      amount: amount ?? this.amount,
      state: state ?? this.state,
      currencyId: currencyId ?? this.currencyId,
      rate: rate ?? this.rate
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': customer,
      'code': code ?? '',
      'remittance_date': HumanFormats.toShortDate(createdAt, isShortFormat: false),
      'amount': amount,
      'payment_currency_id': currencyId
    };
  }

}
