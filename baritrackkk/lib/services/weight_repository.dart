import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../models/weight_entry.dart';

class WeightRepository {
  static const String _fileName = "weight_logs.json";

  /// Get the file path
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$_fileName");
  }

  /// Load weight logs
  static Future<List<WeightEntry>> getWeightLogs() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final contents = await file.readAsString();
      final List<dynamic> data = jsonDecode(contents);
      return data.map((e) => WeightEntry.fromJson(e)).toList();
    } catch (e) {
      print("Error loading weight logs: $e");
      return [];
    }
  }

  /// Add new weight log
  static Future<void> addWeightLog(WeightEntry entry) async {
    try {
      final logs = await getWeightLogs();
      logs.add(entry);

      final file = await _getFile();
      await file.writeAsString(
        jsonEncode(logs.map((e) => e.toJson()).toList()),
        flush: true,
      );
    } catch (e) {
      print("Error adding weight log: $e");
    }
  }

  /// Clear all logs
  static Future<void> clearLogs() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Error clearing logs: $e");
    }
  }
}
