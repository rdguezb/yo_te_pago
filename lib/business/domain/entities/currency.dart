class Currency {

  int? id;
  String name;
  String fullName;
  String symbol;

  Currency({
    this.id,
    required this.name,
    required this.fullName,
    required this.symbol
  });

  factory Currency.fromJson(Map<String, dynamic> json) {

    return Currency(
        id: (json['id'] as int?) ?? 0,
        fullName: json['fullName'] as String,
        name: json['name'] as String,
        symbol: json['symbol'] as String
    );
  }

  Currency copyWith({
    int? id,
    String? name,
    String? fullName,
    String? symbol
  }) {

    return Currency(
        id: id ?? this.id,
        name: name ?? this.name,
        fullName: fullName ?? this.fullName,
        symbol: symbol ?? this.symbol
    );
  }


  @override
  String toString() {

    return '[$name] $fullName';
  }

}