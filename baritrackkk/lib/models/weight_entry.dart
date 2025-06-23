class WeightEntry {
  DateTime date;
  double weight;
  String? notes;

  WeightEntry({
    required this.date,
    required this.weight,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
    'notes': notes,
  };

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      date: DateTime.parse(json['date']),
      weight: json['weight'].toDouble(),
      notes: json['notes'],
    );
  }
}