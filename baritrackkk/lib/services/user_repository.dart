import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserRepository {
  static const String _profileKey = "userProfile";

  /// Save profile
  static Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  /// Load profile
  static Future<UserProfile?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_profileKey);
    if (jsonString == null) return null;
    return UserProfile.fromJson(jsonDecode(jsonString));
  }

  /// Clear profile
  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}
