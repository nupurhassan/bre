import '../models/user_profile.dart';
import '../models/weight_entry.dart';
import '../utils/constants.dart';
import '../utils/csv_helpers.dart';
import '../utils/date_helpers.dart';

/// Validation result class
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  /// Creates a successful validation result
  static ValidationResult success({List<String> warnings = const []}) {
    return ValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  /// Creates a failed validation result
  static ValidationResult failure(List<String> errors, {List<String> warnings = const []}) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Combines multiple validation results
  static ValidationResult combine(List<ValidationResult> results) {
    List<String> allErrors = [];
    List<String> allWarnings = [];

    for (var result in results) {
      allErrors.addAll(result.errors);
      allWarnings.addAll(result.warnings);
    }

    return ValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      warnings: allWarnings,
    );
  }

  @override
  String toString() {
    String result = 'ValidationResult(isValid: $isValid';
    if (hasErrors) result += ', errors: $errors';
    if (hasWarnings) result += ', warnings: $warnings';
    result += ')';
    return result;
  }
}

class DataValidationService {
  /// Validates a UserProfile object comprehensively
  static ValidationResult validateUserProfile(UserProfile profile) {
    List<String> errors = [];
    List<String> warnings = [];

    // Surgery Date validation
    if (profile.surgeryDate == null) {
      errors.add('Surgery date is required');
    } else {
      if (!DateHelpers.isValidSurgeryDate(profile.surgeryDate!)) {
        errors.add('Surgery date must be within the last 5 years and not more than 1 month in the future');
      }

      // Check if surgery date is too recent (less than 1 day ago)
      if (profile.surgeryDate!.isAfter(DateTime.now().subtract(Duration(days: 1)))) {
        warnings.add('Surgery date is very recent - ensure this is correct');
      }

      // Check if surgery date is more than 2 years ago
      if (profile.surgeryDate!.isBefore(DateTime.now().subtract(Duration(days: 730)))) {
        warnings.add('Surgery was more than 2 years ago - consider updating tracking goals');
      }
    }

    // Sex validation
    if (profile.sex == null || profile.sex!.isEmpty) {
      errors.add('Sex is required');
    } else if (!AppConstants.sexOptions.contains(profile.sex)) {
      errors.add('Invalid sex option selected');
    }

    // Age validation
    if (profile.age == null) {
      errors.add('Age is required');
    } else {
      if (profile.age! < AppConstants.minAge || profile.age! > AppConstants.maxAge) {
        errors.add('Age must be between ${AppConstants.minAge} and ${AppConstants.maxAge}');
      }
      if (profile.age! < 18) {
        warnings.add('Age is below 18 - ensure parental consent is obtained for medical tracking');
      }
      if (profile.age! > 80) {
        warnings.add('Age is above 80 - weight loss expectations may differ from standard guidelines');
      }
    }

    // Weight validation
    if (profile.weight == null) {
      errors.add('Current weight is required');
    } else {
      if (profile.weight! < AppConstants.minWeight || profile.weight! > AppConstants.maxWeight) {
        errors.add(AppConstants.errorInvalidWeight);
      }

      // Sanity checks for weight
      if (profile.weight! < 80) {
        warnings.add(AppConstants.warningLowWeight);
      } else if (profile.weight! > 600) {
        warnings.add(AppConstants.warningHighWeight);
      }
    }

    // Starting weight validation
    if (profile.startingWeight == null) {
      errors.add('Starting weight is required');
    } else {
      if (profile.startingWeight! < AppConstants.minWeight || profile.startingWeight! > AppConstants.maxWeight) {
        errors.add('Starting weight must be between ${AppConstants.minWeight} and ${AppConstants.maxWeight} lbs');
      }

      // Cross-validate with current weight
      if (profile.weight != null && profile.startingWeight != null) {
        if (profile.weight! > profile.startingWeight!) {
          warnings.add('Current weight is higher than starting weight - this may indicate weight regain');
        }

        double weightLoss = profile.startingWeight! - profile.weight!;
        double percentLoss = (weightLoss / profile.startingWeight!) * 100;

        if (percentLoss > 90) {
          errors.add('Weight loss percentage seems unrealistic (over 90%) - please verify data accuracy');
        } else if (percentLoss > 70) {
          warnings.add('Very high weight loss percentage (${percentLoss.toStringAsFixed(1)}%) - please verify accuracy');
        } else if (percentLoss < 0) {
          warnings.add('Weight gain detected since starting weight');
        }

        // Check for rapid initial weight loss
        if (profile.surgeryDate != null) {
          int weeksPostOp = DateHelpers.getWeeksPostOp(profile.surgeryDate!);
          if (weeksPostOp > 0 && percentLoss > 0) {
            double weeklyLossRate = percentLoss / weeksPostOp;
            if (weeklyLossRate > 3.0) {
              warnings.add('Very rapid weekly weight loss rate detected (${weeklyLossRate.toStringAsFixed(1)}% per week)');
            }
          }
        }
      }
    }

    // Height validation
    if (profile.height == null) {
      errors.add('Height is required');
    } else {
      if (profile.height! < AppConstants.minHeight || profile.height! > AppConstants.maxHeight) {
        errors.add(AppConstants.errorInvalidHeight);
      }
    }

    // BMI validation (if height and weight are available)
    if (profile.height != null && profile.weight != null) {
      double bmi = profile.bmi;
      if (bmi < 10 || bmi > 80) {
        errors.add('Calculated BMI (${bmi.toStringAsFixed(1)}) is outside realistic range');
      } else if (bmi < AppConstants.bmiUnderweight) {
        warnings.add('Current BMI indicates underweight status - monitor closely');
      }
    }

    // Race validation
    if (profile.race == null || profile.race!.isEmpty) {
      warnings.add('Race information not provided - this may affect weight loss expectations');
    } else if (!AppConstants.raceOptions.contains(profile.race)) {
      errors.add('Invalid race option selected');
    }

    // Surgery type validation
    if (profile.surgeryType == null || profile.surgeryType!.isEmpty) {
      errors.add('Surgery type is required');
    } else if (!AppConstants.surgeryTypes.contains(profile.surgeryType)) {
      errors.add('Invalid surgery type selected');
    }

    // Name validation
    if (profile.name != null && profile.name!.isNotEmpty) {
      String sanitizedName = CSVHelpers.sanitizeString(profile.name!);
      if (sanitizedName.length < 2) {
        errors.add('Name must be at least 2 characters long');
      }
      if (sanitizedName.length > 50) {
        warnings.add('Name is very long and may be truncated in reports');
      }

      // Check for valid name characters
      if (!RegExp(AppConstants.nameRegex).hasMatch(sanitizedName)) {
        warnings.add('Name contains unusual characters that may not display correctly');
      }
    } else {
      warnings.add('Name not provided - reports will show generic identifier');
    }

    // Email validation
    if (profile.email != null && profile.email!.isNotEmpty) {
      if (!CSVHelpers.isValidEmail(profile.email!)) {
        errors.add(AppConstants.errorInvalidEmail);
      }

      // Additional email format checks
      if (profile.email!.length > 100) {
        warnings.add('Email address is very long');
      }
    } else {
      warnings.add('Email not provided - cannot send progress reports or reminders');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates a WeightEntry object
  static ValidationResult validateWeightEntry(WeightEntry entry, {UserProfile? profile}) {
    List<String> errors = [];
    List<String> warnings = [];

    // Date validation
    if (DateHelpers.isFuture(entry.date)) {
      errors.add(AppConstants.errorFutureDate);
    }

    // Check if date is too far in the past
    final fiveYearsAgo = DateTime.now().subtract(Duration(days: 1825));
    if (entry.date.isBefore(fiveYearsAgo)) {
      warnings.add('Weight entry is more than 5 years old');
    }

    // Validate against surgery date if profile is provided
    if (profile?.surgeryDate != null) {
      if (!DateHelpers.isValidWeightEntryDate(entry.date, profile!.surgeryDate)) {
        errors.add('Weight entry date is not valid relative to surgery date');
      }

      // Check if entry is before surgery
      if (entry.date.isBefore(profile.surgeryDate!)) {
        warnings.add('Weight entry is before surgery date - this will be treated as pre-surgery weight');
      }
    }

    // Weight validation
    if (entry.weight < AppConstants.minWeight || entry.weight > AppConstants.maxWeight) {
      errors.add(AppConstants.errorInvalidWeight);
    }

    // Additional weight sanity checks
    if (entry.weight < 80) {
      warnings.add(AppConstants.warningLowWeight);
    } else if (entry.weight > 600) {
      warnings.add(AppConstants.warningHighWeight);
    }

    // Notes validation
    if (entry.notes != null && entry.notes!.isNotEmpty) {
      String sanitizedNotes = CSVHelpers.sanitizeString(entry.notes!);
      if (sanitizedNotes.length > 500) {
        warnings.add('Notes are very long (${sanitizedNotes.length} characters) and may be truncated');
      }

      // Check for potentially sensitive information in notes
      String notesLower = sanitizedNotes.toLowerCase();
      List<String> sensitivePatterns = ['password', 'ssn', 'social security', 'credit card'];
      for (String pattern in sensitivePatterns) {
        if (notesLower.contains(pattern)) {
          warnings.add('Notes may contain sensitive information - please review');
          break;
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates a list of weight entries for consistency and patterns
  static ValidationResult validateWeightEntries(List<WeightEntry> entries, {UserProfile? profile}) {
    List<String> errors = [];
    List<String> warnings = [];

    if (entries.isEmpty) {
      return ValidationResult.success();
    }

    // Sort entries by date for analysis
    List<WeightEntry> sortedEntries = List.from(entries);
    sortedEntries.sort((a, b) => a.date.compareTo(b.date));

    // Check for duplicate dates
    Set<String> seenDates = {};
    for (var entry in entries) {
      String dateKey = DateHelpers.formatDate(entry.date);
      if (seenDates.contains(dateKey)) {
        warnings.add('${AppConstants.warningDuplicateEntry} for $dateKey');
      }
      seenDates.add(dateKey);
    }

    // Analyze weight change patterns
    for (int i = 1; i < sortedEntries.length; i++) {
      double weightChange = (sortedEntries[i].weight - sortedEntries[i-1].weight).abs();
      int daysBetween = sortedEntries[i].date.difference(sortedEntries[i-1].date).inDays;

      if (daysBetween > 0) {
        double dailyChangeRate = weightChange / daysBetween;

        // Check for extremely rapid changes
        if (dailyChangeRate > AppConstants.maxDailyWeightChange) {
          warnings.add('Large weight change (${weightChange.toStringAsFixed(1)} lbs) detected between ${DateHelpers.formatDate(sortedEntries[i-1].date)} and ${DateHelpers.formatDate(sortedEntries[i].date)}');
        }

        // Check for weekly change rates
        if (daysBetween >= 7) {
          double weeklyChange = weightChange * (7.0 / daysBetween);
          if (weeklyChange > AppConstants.maxWeeklyWeightLoss) {
            warnings.add('High weekly weight change rate (${weeklyChange.toStringAsFixed(1)} lbs/week) detected');
          }
        }
      }
    }

    // Check overall progression pattern
    if (sortedEntries.length >= 3) {
      double firstWeight = sortedEntries.first.weight;
      double lastWeight = sortedEntries.last.weight;
      int totalDays = sortedEntries.last.date.difference(sortedEntries.first.date).inDays;

      if (lastWeight > firstWeight) {
        double totalGain = lastWeight - firstWeight;
        warnings.add('Overall weight trend shows gain of ${totalGain.toStringAsFixed(1)} lbs over ${totalDays} days');
      }

      // Check for stagnation periods
      _checkForStagnation(sortedEntries, warnings);
    }

    // Validate each entry individually
    for (var entry in entries) {
      var entryValidation = validateWeightEntry(entry, profile: profile);
      errors.addAll(entryValidation.errors);
      warnings.addAll(entryValidation.warnings);
    }

    // Check frequency of entries
    if (entries.length >= 2) {
      DateTime oldestEntry = sortedEntries.first.date;
      DateTime newestEntry = sortedEntries.last.date;
      int dayspan = newestEntry.difference(oldestEntry).inDays;

      if (dayspan > 0) {
        double averageDaysBetweenEntries = dayspan / (entries.length - 1);

        if (averageDaysBetweenEntries > 14) {
          warnings.add('Infrequent weight logging detected (average ${averageDaysBetweenEntries.toStringAsFixed(1)} days between entries)');
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates weight entry against user profile expectations
  static ValidationResult validateWeightEntryAgainstProfile(WeightEntry entry, UserProfile profile) {
    List<String> errors = [];
    List<String> warnings = [];

    if (profile.surgeryDate == null || profile.startingWeight == null) {
      return ValidationResult.success();
    }

    // Calculate weeks post-op for this entry
    int weeksPostOp = DateHelpers.getWeeksFromSurgery(profile.surgeryDate!, entry.date);

    if (weeksPostOp < 0) {
      // Entry is before surgery - validate as pre-surgery weight
      if (entry.weight > (profile.startingWeight! * 1.1)) {
        warnings.add('Pre-surgery weight is significantly higher than recorded starting weight');
      }
      return ValidationResult(isValid: true, warnings: warnings);
    }

    // Get expected weight for this time point
    double expectedWeight = profile.getExpectedWeight(weeksPostOp);
    double actualWeight = entry.weight;
    double startingWeight = profile.startingWeight!;

    // Calculate percentage loss
    double expectedLossPercent = ((startingWeight - expectedWeight) / startingWeight) * 100;
    double actualLossPercent = ((startingWeight - actualWeight) / startingWeight) * 100;

    // Check if significantly behind expected progress
    if (actualLossPercent < expectedLossPercent * AppConstants.progressBehindThreshold) {
      double deficit = expectedLossPercent - actualLossPercent;
      warnings.add('Weight loss appears ${deficit.toStringAsFixed(1)}% behind expected progress for ${profile.surgeryType} at ${weeksPostOp} weeks post-op');
    }

    // Check if significantly ahead of expected progress
    else if (actualLossPercent > expectedLossPercent * AppConstants.progressAheadThreshold) {
      double excess = actualLossPercent - expectedLossPercent;
      warnings.add('Weight loss appears ${excess.toStringAsFixed(1)}% ahead of expected progress - monitor for rapid loss');
    }

    // Check for concerning rapid loss patterns
    if (weeksPostOp > 0) {
      double weeklyLossRate = (startingWeight - actualWeight) / weeksPostOp;

      if (weeklyLossRate > 5.0) {
        warnings.add('Very rapid average weekly loss rate (${weeklyLossRate.toStringAsFixed(1)} lbs/week) - consider consulting healthcare provider');
      }

      // Check against surgery-specific safe rates
      double maxSafeWeeklyRate = _getMaxSafeWeeklyRate(profile.surgeryType ?? '', weeksPostOp);
      if (weeklyLossRate > maxSafeWeeklyRate) {
        warnings.add('Weekly loss rate exceeds safe guidelines for ${profile.surgeryType}');
      }
    }

    // Check for plateau detection
    if (weeksPostOp > 12 && actualLossPercent < 5) {
      warnings.add('Minimal weight loss detected after 12+ weeks - may indicate need for program adjustment');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates app settings
  static ValidationResult validateAppSettings(Map<String, dynamic> settings) {
    List<String> errors = [];
    List<String> warnings = [];

    // Check required settings
    List<String> requiredKeys = [
      AppConstants.isFirstTimeKey,
      AppConstants.entriesCountKey,
    ];

    for (String key in requiredKeys) {
      if (!settings.containsKey(key)) {
        errors.add('Required setting missing: $key');
      }
    }

    // Validate specific settings
    if (settings.containsKey(AppConstants.entriesCountKey)) {
      var entriesCount = settings[AppConstants.entriesCountKey];
      if (entriesCount is! int || entriesCount < 0) {
        errors.add('Entries count must be a non-negative integer');
      } else if (entriesCount > 10000) {
        warnings.add('Very high entries count (${entriesCount}) - consider data cleanup');
      }
    }

    if (settings.containsKey(AppConstants.weightUnitKey)) {
      var weightUnit = settings[AppConstants.weightUnitKey];
      if (weightUnit is! String || !AppConstants.weightUnits.contains(weightUnit)) {
        errors.add('Invalid weight unit: $weightUnit');
      }
    }

    if (settings.containsKey(AppConstants.heightUnitKey)) {
      var heightUnit = settings[AppConstants.heightUnitKey];
      if (heightUnit is! String || !AppConstants.heightUnits.contains(heightUnit)) {
        errors.add('Invalid height unit: $heightUnit');
      }
    }

    if (settings.containsKey(AppConstants.notificationsEnabledKey)) {
      var notifications = settings[AppConstants.notificationsEnabledKey];
      if (notifications is! bool) {
        errors.add('Notifications setting must be boolean');
      }
    }

    if (settings.containsKey(AppConstants.themeKey)) {
      var theme = settings[AppConstants.themeKey];
      if (theme is! String || !AppConstants.themeOptions.contains(theme)) {
        errors.add('Invalid theme setting: $theme');
      }
    }

    // Validate reminder time format
    if (settings.containsKey(AppConstants.reminderTimeKey)) {
      var reminderTime = settings[AppConstants.reminderTimeKey];
      if (reminderTime is! String || !RegExp(r'^\d{2}:\d{2}$').hasMatch(reminderTime)) {
        errors.add('Invalid reminder time format - must be HH:mm');
      }
    }

    // Validate weekly goal
    if (settings.containsKey(AppConstants.weeklyGoalKey)) {
      var weeklyGoal = settings[AppConstants.weeklyGoalKey];
      if (weeklyGoal is! num || weeklyGoal <= 0 || weeklyGoal > 10) {
        errors.add('Weekly goal must be a positive number between 0.1 and 10 lbs');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Comprehensive data integrity check across all data
  static ValidationResult checkDataIntegrity(
      UserProfile? profile,
      List<WeightEntry> entries,
      Map<String, dynamic> settings,
      ) {
    List<ValidationResult> results = [];

    // Validate profile if exists
    if (profile != null) {
      results.add(validateUserProfile(profile));
    }

    // Validate entries
    results.add(validateWeightEntries(entries, profile: profile));

    // Validate settings
    results.add(validateAppSettings(settings));

    // Cross-validate entries count
    int actualEntriesCount = entries.length;
    int settingsEntriesCount = settings[AppConstants.entriesCountKey] ?? 0;

    if (actualEntriesCount != settingsEntriesCount) {
      results.add(ValidationResult.success(warnings: [
        'Entries count mismatch: actual ($actualEntriesCount) vs settings ($settingsEntriesCount)'
      ]));
    }

    // Check for data consistency issues
    if (profile != null && entries.isNotEmpty) {
      results.add(_validateDataConsistency(profile, entries));
    }

    return ValidationResult.combine(results);
  }

  /// Sanitizes user input data
  static UserProfile sanitizeUserProfile(UserProfile profile) {
    return UserProfile(
      surgeryDate: profile.surgeryDate,
      sex: profile.sex?.trim(),
      age: profile.age,
      weight: profile.weight,
      height: profile.height,
      race: profile.race?.trim(),
      surgeryType: profile.surgeryType?.trim(),
      startingWeight: profile.startingWeight,
      name: profile.name != null ? CSVHelpers.sanitizeString(profile.name!) : null,
      email: profile.email?.trim().toLowerCase(),
    );
  }

  /// Sanitizes weight entry data
  static WeightEntry sanitizeWeightEntry(WeightEntry entry) {
    return WeightEntry(
      date: entry.date,
      weight: entry.weight,
      notes: entry.notes != null ? CSVHelpers.sanitizeString(entry.notes!) : null,
    );
  }

  /// Validates CSV file structure
  static ValidationResult validateCsvFileStructure(String csvContent, String expectedHeader) {
    List<String> errors = [];
    List<String> warnings = [];

    if (csvContent.isEmpty) {
      errors.add('CSV file is empty');
      return ValidationResult.failure(errors);
    }

    if (!CSVHelpers.validateCsvFormat(csvContent, expectedHeader)) {
      errors.add('CSV file format does not match expected structure');
    }

    // Analyze structure
    Map<String, dynamic> analysis = CSVHelpers.analyzeCsvStructure(csvContent);

    if (!(analysis['isValid'] as bool)) {
      errors.addAll(List<String>.from(analysis['errors']));
    }

    warnings.addAll(List<String>.from(analysis['warnings']));

    // Check data volume
    int dataRows = analysis['dataRows'] as int;
    if (dataRows == 0) {
      warnings.add('CSV file contains no data rows');
    } else if (dataRows > 10000) {
      warnings.add('CSV file contains a very large number of rows (${dataRows})');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates imported data before processing
  static ValidationResult validateImportedData(
      Map<String, dynamic> data,
      String dataType,
      ) {
    List<String> errors = [];
    List<String> warnings = [];

    switch (dataType.toLowerCase()) {
      case 'profile':
        try {
          UserProfile profile = UserProfile.fromJson(data);
          return validateUserProfile(profile);
        } catch (e) {
          errors.add('Failed to parse profile data: ${e.toString()}');
        }
        break;

      case 'weight_entry':
        try {
          WeightEntry entry = WeightEntry.fromJson(data);
          return validateWeightEntry(entry);
        } catch (e) {
          errors.add('Failed to parse weight entry data: ${e.toString()}');
        }
        break;

      default:
        errors.add('Unknown data type for validation: $dataType');
    }

    return ValidationResult.failure(errors, warnings: warnings);
  }

  // Private helper methods

  /// Checks for weight stagnation periods
  static void _checkForStagnation(List<WeightEntry> sortedEntries, List<String> warnings) {
    const int stagnationThreshold = AppConstants.stagnationDays;
    const double stagnationWeightRange = 2.0; // lbs

    for (int i = 0; i < sortedEntries.length - 1; i++) {
      for (int j = i + 1; j < sortedEntries.length; j++) {
        int daysBetween = sortedEntries[j].date.difference(sortedEntries[i].date).inDays;
        double weightDifference = (sortedEntries[j].weight - sortedEntries[i].weight).abs();

        if (daysBetween >= stagnationThreshold && weightDifference <= stagnationWeightRange) {
          warnings.add('Weight stagnation detected: minimal change (${weightDifference.toStringAsFixed(1)} lbs) over $daysBetween days');
          break;
        }
      }
    }
  }

  /// Gets maximum safe weekly weight loss rate for surgery type
  static double _getMaxSafeWeeklyRate(String surgeryType, int weeksPostOp) {
    Map<String, double> baseSafeRates = {
      'Gastric Sleeve': 3.0,
      'Gastric Bypass': 4.0,
      'Duodenal Switch': 5.0,
      'Gastric Band': 2.0,
    };

    double baseRate = baseSafeRates[surgeryType] ?? 3.0;

    // Reduce safe rate as time progresses
    if (weeksPostOp > 12) {
      baseRate *= 0.7; // 30% reduction after 3 months
    }
    if (weeksPostOp > 24) {
      baseRate *= 0.5; // 50% reduction after 6 months
    }

    return baseRate;
  }

  /// Validates data consistency between profile and entries
  static ValidationResult _validateDataConsistency(UserProfile profile, List<WeightEntry> entries) {
    List<String> warnings = [];

    if (entries.isEmpty) {
      return ValidationResult.success();
    }

    // Check if profile weight matches most recent entry
    entries.sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
    WeightEntry mostRecentEntry = entries.first;

    if (profile.weight != null && profile.weight != mostRecentEntry.weight) {
      double difference = (profile.weight! - mostRecentEntry.weight).abs();
      if (difference > 1.0) { // More than 1 lb difference
        warnings.add('Profile weight (${profile.weight}) differs from most recent entry (${mostRecentEntry.weight}) by ${difference.toStringAsFixed(1)} lbs');
      }
    }

    // Check for entries before starting weight was recorded
    if (profile.startingWeight != null && profile.surgeryDate != null) {
      for (var entry in entries) {
        if (entry.date.isBefore(profile.surgeryDate!) && entry.weight > profile.startingWeight!) {
          warnings.add('Found weight entry (${entry.weight} lbs) higher than starting weight before surgery date');
          break;
        }
      }
    }

    return ValidationResult.success(warnings: warnings);
  }
}