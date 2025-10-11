class Bank {

  int? id;
  String name;

  Bank({
    this.id,
    required this.name
  });

  factory Bank.fromJson(Map<String, dynamic> json) {

    return Bank(
        id: (json['id'] as int?) ?? 0,
        name: json['name'] as String
    );
  }

  Bank copyWith({
    int? id,
    String? name
  }) {

    return Bank(
        id: id ?? this.id,
        name: name ?? this.name
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name
    };
  }

}