class AppConstants {
  // CSV File Names
  static const String userProfileFileName = 'user_profile.csv';
  static const String weightEntriesFileName = 'weight_entries.csv';
  static const String appSettingsFileName = 'app_settings.csv';
  static const String exportFilePrefix = 'baritrack_export_';
  static const String backupFilePrefix = 'baritrack_backup_';

  // CSV Headers
  static const String userProfileHeader = 'surgeryDate,sex,age,weight,height,race,surgeryType,startingWeight,name,email';
  static const String weightEntriesHeader = 'date,weight,notes';
  static const String appSettingsHeader = 'key,value,type';

  // App Settings Keys
  static const String isFirstTimeKey = 'isFirstTime';
  static const String entriesCountKey = 'entriesCount';
  static const String lastBackupKey = 'lastBackup';
  static const String weightUnitKey = 'weightUnit';
  static const String heightUnitKey = 'heightUnit';
  static const String notificationsEnabledKey = 'notificationsEnabled';
  static const String themeKey = 'theme';
  static const String reminderTimeKey = 'reminderTime';
  static const String weeklyGoalKey = 'weeklyGoal';
  static const String dataVersionKey = 'dataVersion';

  // Weight Loss Milestones (in weeks)
  static const Map<String, Map<int, double>> surgeryMilestones = {
    'Gastric Bypass': {
      0: 0.0,   // Week 0: 0% loss
      4: 0.10,  // Month 1: 10% loss
      12: 0.25, // Month 3: 25% loss
      24: 0.50, // Month 6: 50% loss
      52: 0.60, // Month 12: 60% loss
      104: 0.65, // Month 24: 65% loss (maintenance)
    },
    'Gastric Sleeve': {
      0: 0.0,   // Week 0: 0% loss
      4: 0.08,  // Month 1: 8% loss
      12: 0.20, // Month 3: 20% loss
      24: 0.45, // Month 6: 45% loss
      52: 0.55, // Month 12: 55% loss
      104: 0.60, // Month 24: 60% loss (maintenance)
    },
    'Duodenal Switch': {
      0: 0.0,   // Week 0: 0% loss
      4: 0.12,  // Month 1: 12% loss
      12: 0.35, // Month 3: 35% loss
      24: 0.70, // Month 6: 70% loss
      52: 0.80, // Month 12: 80% loss
      104: 0.85, // Month 24: 85% loss (maintenance)
    },
    'Gastric Band': {
      0: 0.0,   // Week 0: 0% loss
      4: 0.05,  // Month 1: 5% loss
      12: 0.15, // Month 3: 15% loss
      24: 0.30, // Month 6: 30% loss
      52: 0.40, // Month 12: 40% loss
      104: 0.45, // Month 24: 45% loss (maintenance)
    },
  };

  // Surgery Types
  static const List<String> surgeryTypes = [
    'Gastric Sleeve',
    'Gastric Bypass',
    'Duodenal Switch',
    'Gastric Band',
    'Mini Gastric Bypass',
    'Revision Surgery',
  ];

  // Sex Options
  static const List<String> sexOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  // Race Options
  static const List<String> raceOptions = [
    'Asian',
    'Black or African American',
    'Hispanic or Latino',
    'Native American',
    'Pacific Islander',
    'White or Caucasian',
    'Mixed Race',
    'Other',
    'Prefer not to say',
  ];

  // Weight Units
  static const List<String> weightUnits = ['lbs', 'kg', 'stone'];
  static const List<String> heightUnits = ['cm', 'inches', 'feet'];

  // Theme Options
  static const List<String> themeOptions = ['system', 'light', 'dark'];

  // Default Values
  static const double defaultWeight = 0.0;
  static const double defaultHeight = 0.0;
  static const int defaultAge = 0;
  static const bool defaultNotificationsEnabled = true;
  static const String defaultWeightUnit = 'lbs';
  static const String defaultHeightUnit = 'cm';
  static const String defaultTheme = 'system';
  static const String defaultReminderTime = '09:00';
  static const double defaultWeeklyGoal = 2.0; // 2 lbs per week
  static const String currentDataVersion = '1.0';

  // Validation Limits
  static const double minWeight = 50.0;  // 50 lbs
  static const double maxWeight = 1000.0; // 1000 lbs
  static const double minWeightKg = 22.7; // 50 lbs in kg
  static const double maxWeightKg = 453.6; // 1000 lbs in kg
  static const double minHeight = 100.0; // 100 cm
  static const double maxHeight = 250.0; // 250 cm
  static const double minHeightInches = 39.4; // 100 cm in inches
  static const double maxHeightInches = 98.4; // 250 cm in inches
  static const int minAge = 16;
  static const int maxAge = 120;

  // Weight Change Limits (for validation)
  static const double maxDailyWeightChange = 5.0; // 5 lbs max change per day
  static const double maxWeeklyWeightLoss = 10.0; // 10 lbs max loss per week
  static const double maxMonthlyWeightLoss = 40.0; // 40 lbs max loss per month

  // BMI Categories
  static const double bmiUnderweight = 18.5;
  static const double bmiNormal = 24.9;
  static const double bmiOverweight = 29.9;
  static const double bmiObese = 34.9;
  static const double bmiSeverelyObese = 39.9;

  // Error Messages
  static const String errorInvalidWeight = 'Please enter a valid weight between 50-1000 lbs';
  static const String errorInvalidWeightKg = 'Please enter a valid weight between 23-454 kg';
  static const String errorInvalidHeight = 'Please enter a valid height between 100-250 cm';
  static const String errorInvalidHeightInches = 'Please enter a valid height between 39-98 inches';
  static const String errorInvalidAge = 'Please enter a valid age between 16-120';
  static const String errorEmptyField = 'This field cannot be empty';
  static const String errorInvalidEmail = 'Please enter a valid email address';
  static const String errorInvalidDate = 'Please select a valid date';
  static const String errorFutureDate = 'Date cannot be in the future';
  static const String errorSaveProfile = 'Failed to save user profile';
  static const String errorLoadProfile = 'Failed to load user profile';
  static const String errorSaveWeight = 'Failed to save weight entry';
  static const String errorLoadWeight = 'Failed to load weight entries';
  static const String errorExportData = 'Failed to export data';
  static const String errorClearData = 'Failed to clear data';
  static const String errorInvalidCsvFormat = 'Invalid CSV file format';
  static const String errorFileNotFound = 'Data file not found';
  static const String errorPermissionDenied = 'File access permission denied';
  static const String errorInsufficientSpace = 'Insufficient storage space';
  static const String errorNetworkRequired = 'Network connection required';

  // Success Messages
  static const String successProfileSaved = 'Profile saved successfully!';
  static const String successWeightSaved = 'Weight logged successfully!';
  static const String successDataExported = 'Data exported successfully!';
  static const String successDataCleared = 'All data cleared successfully!';
  static const String successDataImported = 'Data imported successfully!';
  static const String successBackupCreated = 'Backup created successfully!';
  static const String successDataRestored = 'Data restored from backup!';
  static const String successReminderSet = 'Reminder set successfully!';
  static const String successGoalUpdated = 'Goal updated successfully!';

  // Warning Messages
  static const String warningLargeWeightChange = 'Large weight change detected';
  static const String warningOldData = 'This data is more than 6 months old';
  static const String warningDuplicateEntry = 'Entry already exists for this date';
  static const String warningBehindGoal = 'You are behind your weight loss goal';
  static const String warningAheadGoal = 'You are ahead of your expected progress';
  static const String warningNoRecentEntries = 'No recent weight entries found';
  static const String warningLowWeight = 'Weight seems unusually low';
  static const String warningHighWeight = 'Weight seems unusually high';

  // Info Messages
  static const String infoFirstWeigh = 'Best time to weigh: first thing in the morning';
  static const String infoDataStored = 'Data is stored securely on your device';
  static const String infoExportLocation = 'Exported files are saved to your Downloads folder';
  static const String infoBackupRecommended = 'Regular backups are recommended';
  static const String infoWeightFluctuations = 'Daily weight fluctuations are normal';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;
  static const double tinyPadding = 4.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double iconSize = 24.0;
  static const double smallIconSize = 16.0;
  static const double largeIconSize = 32.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double cardElevation = 8.0;

  // Animation Constants
  static const int animationDuration = 300; // milliseconds
  static const int longAnimationDuration = 500; // milliseconds
  static const int shortAnimationDuration = 150; // milliseconds
  static const int splashDuration = 2500; // milliseconds

  // Chart Constants
  static const int maxWeeksToShow = 104; // 2 years
  static const int defaultWeeksToShow = 52; // 1 year
  static const int previewWeeksToShow = 24; // 6 months
  static const double chartHeight = 300.0;
  static const double previewChartHeight = 120.0;
  static const double miniChartHeight = 80.0;
  static const int gridHorizontalInterval = 25; // weight intervals
  static const int gridVerticalInterval = 4; // week intervals (monthly)
  static const double chartPadding = 20.0;
  static const double dotRadius = 4.0;
  static const double lineWidth = 2.0;
  static const double thickLineWidth = 3.0;

  // File Constants
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const int maxBackups = 10; // Keep max 10 backups
  static const String csvMimeType = 'text/csv';
  static const String jsonMimeType = 'application/json';
  static const String zipMimeType = 'application/zip';

  // Notification Constants
  static const String notificationChannelId = 'baritrack_reminders';
  static const String notificationChannelName = 'Weight Tracking Reminders';
  static const String notificationChannelDescription = 'Reminders to log your weight';
  static const int defaultNotificationId = 1001;

  // Progress Tracking Constants
  static const double progressBehindThreshold = 0.85; // 15% behind expected
  static const double progressAheadThreshold = 1.15; // 15% ahead of expected
  static const int stagnationDays = 14; // 2 weeks without progress
  static const int inactivityDays = 7; // 1 week without logging

  // Data Export Constants
  static const String exportDateFormat = 'yyyy-MM-dd_HH-mm-ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String shortDateFormat = 'MM/dd/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';

  // Security Constants
  static const int maxLoginAttempts = 5;
  static const int lockoutDuration = 300; // 5 minutes in seconds
  static const int sessionTimeout = 3600; // 1 hour in seconds

  // App Metadata
  static const String appName = 'BariTrack';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Bariatric Surgery Weight Tracking App';
  static const String supportEmail = 'support@baritrack.com';
  static const String privacyPolicyUrl = 'https://baritrack.com/privacy';
  static const String termsOfServiceUrl = 'https://baritrack.com/terms';

  // Conversion Constants
  static const double lbsToKg = 0.453592;
  static const double kgToLbs = 2.20462;
  static const double cmToInches = 0.393701;
  static const double inchesToCm = 2.54;
  static const double stoneToPounds = 14.0;
  static const double poundsToStone = 0.071429;

  // URL Constants
  static const String helpUrl = 'https://baritrack.com/help';
  static const String faqUrl = 'https://baritrack.com/faq';
  static const String contactUrl = 'https://baritrack.com/contact';
  static const String feedbackUrl = 'https://baritrack.com/feedback';

  // Regular Expressions
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[\d\s\-\(\)]+$';
  static const String nameRegex = r'^[a-zA-Z\s\-\.]+$';

  // Feature Flags
  static const bool enableNotifications = true;
  static const bool enableDataExport = true;
  static const bool enableBackups = true;
  static const bool enableAnalytics = false;
  static const bool enableBiometrics = false;
  static const bool enableCloudSync = false;
  static const bool enableSocialSharing = true;
  static const bool enableGoalSetting = true;
  static const bool enableProgressPhotos = false;
}