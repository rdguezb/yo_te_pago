class Currency {

  int? id;
  String name;
  String fullName;
  String symbol;
  double rate;
  bool isActive;
  bool isReference;

  Currency({
    this.id,
    required this.name,
    required this.fullName,
    required this.symbol,
    this.rate = 0,
    this.isReference = false,
    this.isActive = false
  });

  factory Currency.fromJson(Map<String, dynamic> json) {

    return Currency(
        id: (json['id'] as int?) ?? 0,
        fullName: json['fullName'] as String,
        name: json['name'] as String,
        symbol: json['symbol'] as String,
        rate: (json['rate'] as double?) ?? 0,
        isReference: json['is_company_currency'] as bool,
        isActive: json['is_allow'] as bool
    );
  }

  Currency copyWith({
    int? id,
    String? name,
    String? fullName,
    String? symbol,
    double? rate,
    bool? isReference,
    bool? isActive
  }) {

    return Currency(
        id: id ?? this.id,
        name: name ?? this.name,
        fullName: fullName ?? this.fullName,
        symbol: symbol ?? this.symbol,
        rate: rate ?? this.rate,
        isReference: isReference ?? this.isReference,
        isActive: isActive ?? this.isActive
    );
  }

  @override
  String toString() {

    return '[$name] $fullName';
  }

}