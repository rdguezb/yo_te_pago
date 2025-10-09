import 'package:yo_te_pago/business/config/helpers/human_formats.dart';


class Remittance {

  int? id;
  String customer;
  double amount;
  DateTime createdAt;
  String state;
  int currencyId;
  double rate;
  String currencyName;
  String currencySymbol;
  int bankAccountId;
  String bankAccountName;
  String? bankName;
  String? code;


  Remittance({
    this.id,
    required this.customer,
    this.code,
    required this.createdAt,
    required this.amount,
    required this.state,
    required this.currencyId,
    required this.currencyName,
    required this.currencySymbol,
    required this.rate,
    required this.bankAccountId,
    required this.bankAccountName,
    this.bankName
  });

  factory Remittance.fromJson(Map<String, dynamic> json) {

    return Remittance(
        id: (json['id'] as int?) ?? 0,
        customer: json['name'] as String,
        code: json['code'] as String,
        createdAt: DateTime.parse(json['date']),
        amount: json['amount']?.toDouble(),
        state: json['state'] as String,
        currencyId: (json['payment_currency_id'] as int?) ?? 0,
        currencyName: json['currency_name'] as String,
        currencySymbol: json['currency_symbol'] as String,
        rate: json['rate']?.toDouble(),
        bankAccountId: (json['bank_id'] as int?) ?? 0,
        bankAccountName: json['acc_number'] as String,
        bankName: json['bank_name'] as String
    );
  }

  bool get isPaid => state == 'paid';
  bool get isConfirmed => state == 'confirmed';
  bool get isWaiting => state == 'waiting';
  bool get isCanceled => state == 'cancelled';
  String get createdAtToStr => HumanFormats.toShortDate(createdAt);
  double get total => rate * amount;

  Remittance copyWith({
    int? id,
    String? customer,
    String? code,
    DateTime? createdAt,
    double? amount,
    String? state,
    int? currencyId,
    String? currencyName,
    String? currencySymbol,
    double? rate,
    int? bankAccountId,
    String? bankAccountName,
    String? bankName
  }) {

    return Remittance(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      amount: amount ?? this.amount,
      state: state ?? this.state,
      currencyId: currencyId ?? this.currencyId,
      currencyName: currencyName ?? this.currencyName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      rate: rate ?? this.rate,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankName: bankName ?? this.bankName
    );
  }

  Map<String, dynamic> toMap() {

    return {
      'name': customer,
      'code': code ?? '',
      'remittance_date': HumanFormats.toShortDate(createdAt, isShortFormat: false),
      'amount': amount,
      'payment_currency_id': currencyId,
      'bank_id': bankAccountId
    };
  }

  String currencyInfo() => '$amount | $currencyName [$rate] | $createdAtToStr';

  String totalToString() => HumanFormats.toAmount(total, currencySymbol);

  String bankAccountInfo() => '$bankAccountName - $bankName';

}
