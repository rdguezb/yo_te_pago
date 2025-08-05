class Balance {

  final String name;
  final String fullName;
  final double debit;
  final double credit;
  final double balance;


  Balance({
    required this.name,
    required this.fullName,
    required this.debit,
    required this.credit,
    this.balance = 0
  });

  double get amount {
    return credit - debit;
  }

  factory Balance.fromJson(Map<String, dynamic> json) {

    return Balance(
        name: json['name'],
        fullName: json['fullName'],
        debit: json['debit'],
        credit: json['credit'],
        balance: json['balance']
    );
  }

}

// el debit - es lo que paga el remesero
// el credit- es lo que el banco paga al remesero