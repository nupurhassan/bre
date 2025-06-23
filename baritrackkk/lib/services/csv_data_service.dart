import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/weight_entry.dart';
import '../utils/constants.dart';
import '../utils/csv_helpers.dart';

class CSVDataService {
  // SharedPreferences keys for CSV content
  static const String _userProfileCsvKey = 'user_profile_csv';
  static const String _weightEntriesCsvKey = 'weight_entries_csv';
  static const String _appSettingsCsvKey = 'app_settings_csv';

  // User Profile CSV Operations
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Create CSV content
      const header = AppConstants.userProfileHeader;
      final data = CSVHelpers.createCsvRow([
        profile.surgeryDate?.toIso8601String() ?? '',
        profile.sex ?? '',
        profile.age ?? '',
        profile.weight ?? '',
        profile.height ?? '',
        profile.race ?? '',
        profile.surgeryType ?? '',
        profile.startingWeight ?? '',
        profile.name ?? '',
        profile.email ?? '',
      ]);

      final csvContent = '$header\n$data';
      await prefs.setString(_userProfileCsvKey, csvContent);

      print('User profile saved to SharedPreferences as CSV');
    } catch (e) {
      print('Error saving user profile: $e');
      throw Exception('Failed to save user profile: $e');
    }
  }

  Future<UserProfile?> loadUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? csvContent = prefs.getString(_userProfileCsvKey);

      if (csvContent == null || csvContent.isEmpty) {
        print('User profile CSV not found');
        return null;
      }

      final lines = csvContent.split('\n');
      if (lines.length < 2) {
        print('Invalid user profile CSV format');
        return null;
      }

      // Skip header, parse data row
      final dataRow = lines[1];
      final fields = CSVHelpers.parseCsvRow(dataRow);

      if (fields.length < 10) {
        print('Incomplete user profile data');
        return null;
      }

      return UserProfile(
        surgeryDate: fields[0].isNotEmpty ? DateTime.parse(fields[0]) : null,
        sex: fields[1].isNotEmpty ? fields[1] : null,
        age: fields[2].isNotEmpty ? int.tryParse(fields[2]) : null,
        weight: fields[3].isNotEmpty ? double.tryParse(fields[3]) : null,
        height: fields[4].isNotEmpty ? double.tryParse(fields[4]) : null,
        race: fields[5].isNotEmpty ? fields[5] : null,
        surgeryType: fields[6].isNotEmpty ? fields[6] : null,
        startingWeight: fields[7].isNotEmpty ? double.tryParse(fields[7]) : null,
        name: fields[8].isNotEmpty ? fields[8] : null,
        email: fields[9].isNotEmpty ? fields[9] : null,
      );
    } catch (e) {
      print('Error loading user profile: $e');
      return null;
    }
  }

  // Weight Entries CSV Operations
  Future<void> saveWeightEntries(List<WeightEntry> entries) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Create CSV content
      StringBuffer csvContent = StringBuffer();
      csvContent.writeln(AppConstants.weightEntriesHeader);

      for (var entry in entries) {
        final row = CSVHelpers.createCsvRow([
          entry.date.toIso8601String(),
          entry.weight,
          entry.notes ?? '',
        ]);
        csvContent.writeln(row);
      }

      await prefs.setString(_weightEntriesCsvKey, csvContent.toString());
      print('Weight entries saved to SharedPreferences as CSV');
    } catch (e) {
      print('Error saving weight entries: $e');
      throw Exception('Failed to save weight entries: $e');
    }
  }

  Future<List<WeightEntry>> loadWeightEntries() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? csvContent = prefs.getString(_weightEntriesCsvKey);

      if (csvContent == null || csvContent.isEmpty) {
        print('Weight entries CSV not found');
        return [];
      }

      final lines = csvContent.split('\n');
      List<WeightEntry> entries = [];

      // Skip header and empty lines
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;

        final fields = CSVHelpers.parseCsvRow(lines[i]);
        if (fields.length >= 2) {
          try {
            entries.add(WeightEntry(
              date: DateTime.parse(fields[0]),
              weight: double.parse(fields[1]),
              notes: fields.length > 2 && fields[2].isNotEmpty ? fields[2] : null,
            ));
          } catch (e) {
            print('Error parsing weight entry row: ${lines[i]}');
          }
        }
      }

      entries.sort((a, b) => a.date.compareTo(b.date));
      print('Loaded ${entries.length} weight entries');
      return entries;
    } catch (e) {
      print('Error loading weight entries: $e');
      return [];
    }
  }

  // Add a single weight entry
  Future<void> addWeightEntry(WeightEntry newEntry) async {
    try {
      List<WeightEntry> entries = await loadWeightEntries();

      // Remove any existing entry for the same date
      entries.removeWhere((entry) =>
      entry.date.year == newEntry.date.year &&
          entry.date.month == newEntry.date.month &&
          entry.date.day == newEntry.date.day
      );

      // Add new entry
      entries.add(newEntry);

      // Save updated list
      await saveWeightEntries(entries);
    } catch (e) {
      print('Error adding weight entry: $e');
      throw Exception('Failed to add weight entry: $e');
    }
  }

  // Remove a weight entry
  Future<void> removeWeightEntry(WeightEntry entryToRemove) async {
    try {
      List<WeightEntry> entries = await loadWeightEntries();

      entries.removeWhere((entry) =>
      entry.date.year == entryToRemove.date.year &&
          entry.date.month == entryToRemove.date.month &&
          entry.date.day == entryToRemove.date.day
      );

      await saveWeightEntries(entries);
    } catch (e) {
      print('Error removing weight entry: $e');
      throw Exception('Failed to remove weight entry: $e');
    }
  }

  // App Settings CSV Operations
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Create CSV content
      StringBuffer csvContent = StringBuffer();
      csvContent.writeln(AppConstants.appSettingsHeader);

      settings.forEach((key, value) {
        String type = CSVHelpers.getTypeString(value);
        String valueStr = CSVHelpers.convertTypeToString(value);
        final row = CSVHelpers.createCsvRow([key, valueStr, type]);
        csvContent.writeln(row);
      });

      await prefs.setString(_appSettingsCsvKey, csvContent.toString());
      print('App settings saved to SharedPreferences as CSV');
    } catch (e) {
      print('Error saving app settings: $e');
      throw Exception('Failed to save app settings: $e');
    }
  }

  Future<Map<String, dynamic>> loadAppSettings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? csvContent = prefs.getString(_appSettingsCsvKey);

      if (csvContent == null || csvContent.isEmpty) {
        print('App settings CSV not found');
        return {};
      }

      final lines = csvContent.split('\n');
      Map<String, dynamic> settings = {};

      // Skip header and empty lines
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;

        final fields = CSVHelpers.parseCsvRow(lines[i]);
        if (fields.length >= 3) {
          String key = fields[0];
          String valueStr = fields[1];
          String type = fields[2];

          // Convert string back to appropriate type
          dynamic value = CSVHelpers.convertStringToType(valueStr, type);
          settings[key] = value;
        }
      }

      print('Loaded ${settings.length} app settings');
      return settings;
    } catch (e) {
      print('Error loading app settings: $e');
      return {};
    }
  }

  // Helper method to get app setting
  Future<T?> getAppSetting<T>(String key) async {
    final settings = await loadAppSettings();
    return settings[key] as T?;
  }

  // Helper method to set app setting
  Future<void> setAppSetting(String key, dynamic value) async {
    final settings = await loadAppSettings();
    settings[key] = value;
    await saveAppSettings(settings);
  }

  // Export all data to a single CSV string
  Future<String> exportAllData() async {
    try {
      StringBuffer exportData = StringBuffer();

      // Export User Profile
      exportData.writeln('=== USER PROFILE ===');
      String? profileCsv = (await SharedPreferences.getInstance()).getString(_userProfileCsvKey);
      if (profileCsv != null && profileCsv.isNotEmpty) {
        exportData.writeln(profileCsv);
      } else {
        exportData.writeln(AppConstants.userProfileHeader);
      }

      exportData.writeln('\n=== WEIGHT ENTRIES ===');
      String? entriesCsv = (await SharedPreferences.getInstance()).getString(_weightEntriesCsvKey);
      if (entriesCsv != null && entriesCsv.isNotEmpty) {
        exportData.writeln(entriesCsv);
      } else {
        exportData.writeln(AppConstants.weightEntriesHeader);
      }

      exportData.writeln('\n=== APP SETTINGS ===');
      String? settingsCsv = (await SharedPreferences.getInstance()).getString(_appSettingsCsvKey);
      if (settingsCsv != null && settingsCsv.isNotEmpty) {
        exportData.writeln(settingsCsv);
      } else {
        exportData.writeln(AppConstants.appSettingsHeader);
      }

      // Save export to SharedPreferences with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportKey = 'export_$timestamp';
      await (await SharedPreferences.getInstance()).setString(exportKey, exportData.toString());

      print('All data exported as CSV string');
      return exportData.toString();
    } catch (e) {
      print('Error exporting data: $e');
      throw Exception('Failed to export data: $e');
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.remove(_userProfileCsvKey);
      await prefs.remove(_weightEntriesCsvKey);
      await prefs.remove(_appSettingsCsvKey);

      // Also clear any export data
      Set<String> keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('export_')) {
          await prefs.remove(key);
        }
      }

      print('All CSV data cleared from SharedPreferences');
    } catch (e) {
      print('Error clearing data: $e');
      throw Exception('Failed to clear data: $e');
    }
  }

  // Get CSV content for debugging
  Future<Map<String, String>> getDebugCsvContent() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      return {
        'userProfile': prefs.getString(_userProfileCsvKey) ?? 'No data',
        'weightEntries': prefs.getString(_weightEntriesCsvKey) ?? 'No data',
        'appSettings': prefs.getString(_appSettingsCsvKey) ?? 'No data',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}