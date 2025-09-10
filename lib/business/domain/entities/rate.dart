class Rate {

  int? id;
  String name;
  String fullName;
  String symbol;
  double rate;
  int currencyId;
  int? partnerId;
  String? partnerName;

  Rate({
    this.id,
    required this.currencyId,
    required this.name,
    required this.fullName,
    required this.symbol,
    required this.rate,
    this.partnerId,
    this.partnerName
  });

  factory Rate.fromJson(Map<String, dynamic> json) {

    return Rate(
      id: (json['id'] as int?) ?? 0,
      currencyId: (json['currency_id'] as int?) ?? 0,
      fullName: json['fullName'],
      name: json['name'],
      symbol: json['symbol'],
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      partnerId: (json['partner_id'] as int?) ?? 0,
      partnerName: json['partner_name']
    );
  }

  Rate copyWith({
    int? id,
    String? name,
    String? fullName,
    String? symbol,
    double? rate,
    int? currencyId,
    int? partnerId,
    String? partnerName
  }) {

    return Rate(
        id: id ?? this.id,
        name: name ?? this.name,
        fullName: fullName ?? this.fullName,
        symbol: symbol ?? this.symbol,
        rate: rate ?? this.rate,
        currencyId: currencyId ?? this.currencyId,
        partnerId: partnerId ?? this.partnerId,
        partnerName: partnerName ?? this.partnerName
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'currency_id': currencyId,
      'partner_id': partnerId,
      'rate': rate
    };
  }

  @override
  String toString() {

    return '[$name] $fullName';
  }
}