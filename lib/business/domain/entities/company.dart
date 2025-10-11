class Company {
  final int id;
  final String name;
  final int hoursKeeps;

  Company({
    required this.id,
    required this.name,
    this.hoursKeeps = 0
  });

  factory Company.fromJson(Map<String, dynamic> json) {

    return Company(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'N/A',
      hoursKeeps: json['hours_keeps'] as int? ?? 0,
    );
  }

  Company copyWith({
    int? id,
    String? name,
    int? hoursKeeps,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      hoursKeeps: hoursKeeps ?? this.hoursKeeps
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'hours_keeps': hoursKeeps,
    };
  }

}