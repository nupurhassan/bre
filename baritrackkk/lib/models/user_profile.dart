class UserProfile {
  DateTime? surgeryDate;
  String? sex;
  int? age;
  double? weight;       // in pounds (lbs)
  double? height;       // in inches
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
    // Imperial BMI formula: 703 * weight (lbs) / [height (in)]^2
    return (weight! * 703) / (height! * height!);
  }

  int get weeksPostOp {
    if (surgeryDate == null) return 0;
    final difference = DateTime.now().difference(surgeryDate!);
    return (difference.inDays / 7).floor();
  }

  double getExpectedWeight(int weeks) {
    if (startingWeight == null || surgeryType == null) return weight ?? 0;

    // Define milestone percentages based on surgery type
    Map<int, double> milestones = {};

    switch (surgeryType) {
      case 'Gastric Bypass':
        milestones = {
          0: 0.0,    // Week 0: 0%
          4: 0.10,   // Month 1: 10%
          12: 0.25,  // Month 3: 25%
          24: 0.35,  // Month 6: 35%  ← updated from 50%
          52: 0.60,  // Month 12: 60%
        };
        break;

      case 'Gastric Sleeve':
        milestones = {
          0: 0.0,
          4: 0.08,
          12: 0.20,
          24: 0.30,  // ← updated from 45%
          52: 0.55,
        };
        break;

      case 'Duodenal Switch':
        milestones = {
          0: 0.0,
          4: 0.12,
          12: 0.30,  // ← updated from 35%
          24: 0.50,  // ← updated from 70%
          52: 0.80,
        };
        break;

      default:
        return startingWeight!;
    }

    double percentageLoss = _interpolatePercentageLoss(weeks, milestones);
    return startingWeight! * (1 - percentageLoss);
  }

  double _interpolatePercentageLoss(int weeks, Map<int, double> milestones) {
    if (milestones.containsKey(weeks)) {
      return milestones[weeks]!;
    }

    List<int> sortedWeeks = milestones.keys.toList()..sort();
    if (weeks <= sortedWeeks.first) {
      return milestones[sortedWeeks.first]!;
    }
    if (weeks >= sortedWeeks.last) {
      return milestones[sortedWeeks.last]!;
    }

    int lowerWeek = 0, upperWeek = 0;
    for (int i = 0; i < sortedWeeks.length - 1; i++) {
      if (weeks >= sortedWeeks[i] && weeks <= sortedWeeks[i + 1]) {
        lowerWeek = sortedWeeks[i];
        upperWeek = sortedWeeks[i + 1];
        break;
      }
    }

    double lowerPerc = milestones[lowerWeek]!;
    double upperPerc = milestones[upperWeek]!;
    double ratio = (weeks - lowerWeek) / (upperWeek - lowerWeek);
    return lowerPerc + (upperPerc - lowerPerc) * ratio;
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

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      surgeryDate: json['surgeryDate'] != null
          ? DateTime.parse(json['surgeryDate'])
          : null,
      sex: json['sex'],
      age: json['age'],
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      race: json['race'],
      surgeryType: json['surgeryType'],
      startingWeight: json['startingWeight']?.toDouble(),
      name: json['name'],
      email: json['email'],
    );
  }
}
