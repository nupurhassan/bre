class UserProfile {
  DateTime? surgeryDate;
  String? sex;
  int? age;
  double? weight; // in pounds (lbs)
  double? height; // in inches
  String? race;
  String? surgeryType;
  double? startingWeight; // in pounds (lbs)
  String? name;
  String? email;

  UserProfile({
    this.surgeryDate,
    this.sex,
    this.age,
    this.weight,
    this.height,
    this.race,
    this.surgeryType,
    this.startingWeight,
    this.name,
    this.email,
  });

  double get bmi {
    if (weight == null || height == null) return 0;
    return (weight! * 703) / (height! * height!); // Imperial BMI
  }

  int get weeksPostOp {
    if (surgeryDate == null) return 0;
    final difference = DateTime.now().difference(surgeryDate!);
    return (difference.inDays / 7).floor();
  }

  double getExpectedWeight(int weeks) {
    if (startingWeight == null || surgeryType == null) return weight ?? 0;

    Map<int, double> milestones = {};

    switch (surgeryType) {
      case 'Gastric Bypass':
        milestones = {0: 0.0, 4: 0.10, 12: 0.25, 24: 0.35, 52: 0.60};
        break;
      case 'Gastric Sleeve':
        milestones = {0: 0.0, 4: 0.08, 12: 0.20, 24: 0.30, 52: 0.55};
        break;
      case 'Duodenal Switch':
        milestones = {0: 0.0, 4: 0.12, 12: 0.30, 24: 0.50, 52: 0.80};
        break;
    }

    double percentageLoss = _interpolate(weeks, milestones);
    return startingWeight! * (1 - percentageLoss);
  }

  double _interpolate(int weeks, Map<int, double> milestones) {
    if (milestones.containsKey(weeks)) return milestones[weeks]!;

    final keys = milestones.keys.toList()..sort();
    if (weeks <= keys.first) return milestones[keys.first]!;
    if (weeks >= keys.last) return milestones[keys.last]!;

    for (int i = 0; i < keys.length - 1; i++) {
      if (weeks >= keys[i] && weeks <= keys[i + 1]) {
        final w1 = keys[i], w2 = keys[i + 1];
        final p1 = milestones[w1]!, p2 = milestones[w2]!;
        final ratio = (weeks - w1) / (w2 - w1);
        return p1 + (p2 - p1) * ratio;
      }
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
    'surgeryDate': surgeryDate?.toIso8601String(),
    'sex': sex,
    'age': age,
    'weight': weight,
    'height': height,
    'race': race,
    'surgeryType': surgeryType,
    'startingWeight': startingWeight,
    'name': name,
    'email': email,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    surgeryDate: json['surgeryDate'] != null
        ? DateTime.parse(json['surgeryDate'])
        : null,
    sex: json['sex'],
    age: json['age'],
    weight: (json['weight'] as num?)?.toDouble(),
    height: (json['height'] as num?)?.toDouble(),
    race: json['race'],
    surgeryType: json['surgeryType'],
    startingWeight: (json['startingWeight'] as num?)?.toDouble(),
    name: json['name'],
    email: json['email'],
  );
}
