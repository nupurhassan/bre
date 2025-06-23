class UserProfile {
  DateTime? surgeryDate;
  String? sex;
  int? age;
  double? weight;
  double? height;
  String? race;
  String? surgeryType;
  double? startingWeight;
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
    // Convert height from cm to m
    double heightInM = height! / 100;
    return weight! / (heightInM * heightInM);
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
          0: 0.0,   // Week 0: 0% loss
          4: 0.10,  // Month 1: 10% loss
          12: 0.25, // Month 3: 25% loss
          24: 0.50, // Month 6: 50% loss
          52: 0.60, // Month 12: 60% loss (maintenance)
        };
        break;
      case 'Gastric Sleeve':
        milestones = {
          0: 0.0,   // Week 0: 0% loss
          4: 0.08,  // Month 1: 8% loss
          12: 0.20, // Month 3: 20% loss
          24: 0.45, // Month 6: 45% loss
          52: 0.55, // Month 12: 55% loss (maintenance)
        };
        break;
      case 'Duodenal Switch':
        milestones = {
          0: 0.0,   // Week 0: 0% loss
          4: 0.12,  // Month 1: 12% loss
          12: 0.35, // Month 3: 35% loss
          24: 0.70, // Month 6: 70% loss
          52: 0.80, // Month 12: 80% loss (maintenance)
        };
        break;
      default:
        return startingWeight!; // No loss if surgery type unknown
    }

    // Interpolate between milestones
    double percentageLoss = _interpolatePercentageLoss(weeks, milestones);

    // Calculate expected weight: starting weight - (starting weight * percentage loss)
    return startingWeight! * (1 - percentageLoss);
  }

  double _interpolatePercentageLoss(int weeks, Map<int, double> milestones) {
    // If exact milestone exists, return it
    if (milestones.containsKey(weeks)) {
      return milestones[weeks]!;
    }

    // Find the two milestones to interpolate between
    List<int> sortedWeeks = milestones.keys.toList()..sort();

    // If before first milestone, return 0
    if (weeks <= sortedWeeks.first) {
      return milestones[sortedWeeks.first]!;
    }

    // If after last milestone, return last milestone value
    if (weeks >= sortedWeeks.last) {
      return milestones[sortedWeeks.last]!;
    }

    // Find the two milestones to interpolate between
    int lowerWeek = 0;
    int upperWeek = 0;

    for (int i = 0; i < sortedWeeks.length - 1; i++) {
      if (weeks >= sortedWeeks[i] && weeks <= sortedWeeks[i + 1]) {
        lowerWeek = sortedWeeks[i];
        upperWeek = sortedWeeks[i + 1];
        break;
      }
    }

    // Linear interpolation
    double lowerPercentage = milestones[lowerWeek]!;
    double upperPercentage = milestones[upperWeek]!;

    double ratio = (weeks - lowerWeek) / (upperWeek - lowerWeek);
    return lowerPercentage + (upperPercentage - lowerPercentage) * ratio;
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
      surgeryDate: json['surgeryDate'] != null ? DateTime.parse(json['surgeryDate']) : null,
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