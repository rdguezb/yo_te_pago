import 'package:yo_te_pago/business/domain/entities/rate.dart';


class RateDto extends Rate {

  RateDto({
    required super.id,
    required super.currencyId,
    required super.name,
    required super.fullName,
    required super.symbol,
    required super.rate,
    super.partnerId,
    super.partnerName
  });

  factory RateDto.fromJson(Map<String, dynamic> json) {

    return RateDto(
        id: (json['id'] as int?) ?? 0,
        currencyId: (json['currency_id'] as int?) ?? 0,
        name: (json['name'] as String?) ?? 'N/A',
        fullName: (json['fullName'] as String?) ?? '',
        symbol: (json['symbol'] as String?) ?? '',
        rate: ((json['rate'] as num?)?.toDouble()) ?? 0.0,
        partnerId: (json['partner_id'] as int?) ?? 0,
        partnerName: json['partner_name'] as String?
    );
  }

  Rate toModel() {

    return Rate(
      id: id,
      currencyId: currencyId,
      name: name,
      fullName: fullName,
      symbol: symbol,
      rate: rate,
      partnerId: partnerId,
      partnerName: partnerName
    );
  }

}
