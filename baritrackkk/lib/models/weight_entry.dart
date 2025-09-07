class WeightEntry {
  final DateTime date;
  final double weight;
  final String? notes;

  WeightEntry({
    required this.date,
    required this.weight,
    this.notes,
  });

  /// Convert to JSON for saving
  Map<String, dynamic> toJson() => {
    'date': DateTime(date.year, date.month, date.day).toIso8601String(), // normalized date
    'weight': weight,
    'notes': notes,
  };

  /// Create from JSON when loading
  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      date: DateTime.parse(json['date']), // safely parse ISO string
      weight: (json['weight'] as num).toDouble(),
      notes: json['notes'],
    );
  }
}
