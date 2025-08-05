class Currency {

  final int id;
  final String name;
  final String fullName;
  final String symbol;
  final double rate;

  Currency({
    required this.id,
    required this.name,
    required this.fullName,
    required this.symbol,
    required this.rate
  });

  factory Currency.fromJson(Map<String, dynamic> json) {

    return Currency(
        id: json['id'],
        fullName: json['fullName'],
        name: json['name'],
        symbol: json['symbol'],
        rate: (json['rate'] as num?)?.toDouble() ?? 0.0
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fullName': fullName,
      'rate': rate,
      'symbol': symbol
    };
  }

}