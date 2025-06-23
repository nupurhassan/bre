import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/weight_entry.dart';
import '../../theme/app_theme.dart';

class TimelineScreen extends StatefulWidget {
  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  DateTime _currentDate = DateTime.now();
  List<WeightEntry> _weightEntries = [];
  Set<DateTime> _loggedDates = {};

  @override
  void initState() {
    super.initState();
    _loadWeightEntries();
  }

  Future<void> _loadWeightEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> entries = prefs.getStringList('weightEntries') ?? [];

    setState(() {
      _weightEntries = entries.map((entry) => WeightEntry.fromJson(jsonDecode(entry))).toList();
      _loggedDates = _weightEntries.map((entry) => DateTime(entry.date.year, entry.date.month, entry.date.day)).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Surgery Timeline'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          Expanded(
            child: _buildCalendar(),
          ),
          _buildLegendAndStats(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
              });
            },
            icon: Icon(Icons.chevron_left, size: 28),
          ),
          Text(
            '${_getMonthName(_currentDate.month)} ${_currentDate.year}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
              });
            },
            icon: Icon(Icons.chevron_right, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildWeekdayHeaders(),
          SizedBox(height: 8),
          Expanded(
            child: _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: weekdays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Convert to 0-6 where 0 is Sunday
    final daysInMonth = lastDayOfMonth.day;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: firstWeekday + daysInMonth,
      itemBuilder: (context, index) {
        if (index < firstWeekday) {
          return Container(); // Empty cells before the first day
        }

        final day = index - firstWeekday + 1;
        final date = DateTime(_currentDate.year, _currentDate.month, day);
        final hasEntry = _loggedDates.contains(date);
        final isToday = _isSameDay(date, DateTime.now());

        return _buildCalendarDay(day, hasEntry, isToday);
      },
    );
  }

  Widget _buildCalendarDay(int day, bool hasEntry, bool isToday) {
    final date = DateTime(_currentDate.year, _currentDate.month, day);

    return GestureDetector(
      onTap: () => _handleDateTap(date, hasEntry),
      child: Container(
        margin: EdgeInsets.all(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isToday ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isToday ? Border.all(color: AppTheme.primaryBlue, width: 1) : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? AppTheme.primaryBlue : Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: hasEntry ? AppTheme.accentOrange : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDateTap(DateTime date, bool hasEntry) {
    if (hasEntry) {
      _showWeightEntryDetails(date);
    } else {
      _showLogWeightDialog(date);
    }
  }

  void _showLogWeightDialog(DateTime date) {
    final _weightController = TextEditingController();
    final _notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            'Log Weight',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Date: ${date.day}/${date.month}/${date.year}',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Weight (lbs)',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.monitor_weight, color: AppTheme.goldenYellow),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.goldenYellow),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.goldenYellow),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _notesController,
                style: TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.note, color: AppTheme.goldenYellow),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.goldenYellow),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.goldenYellow),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => _saveWeightEntry(date, _weightController, _notesController),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveWeightEntry(DateTime date, TextEditingController weightController, TextEditingController notesController) async {
    if (weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final weight = double.tryParse(weightController.text);
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final entry = WeightEntry(
      date: date,
      weight: weight,
      notes: notesController.text.isNotEmpty ? notesController.text : null,
    );

    // Save weight entry
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> entries = prefs.getStringList('weightEntries') ?? [];

    // Check if entry already exists for this date and replace it
    entries.removeWhere((entryJson) {
      final existingEntry = WeightEntry.fromJson(jsonDecode(entryJson));
      return _isSameDay(existingEntry.date, date);
    });

    entries.add(jsonEncode(entry.toJson()));
    await prefs.setStringList('weightEntries', entries);

    // Update user profile with new weight if it's the most recent entry
    String? userProfileJson = prefs.getString('userProfile');
    if (userProfileJson != null) {
      var userProfile = jsonDecode(userProfileJson);
      userProfile['weight'] = weight;
      await prefs.setString('userProfile', jsonEncode(userProfile));
    }

    // Update entries count
    int entriesCount = prefs.getInt('entriesCount') ?? 0;
    await prefs.setInt('entriesCount', entriesCount + 1);

    // Refresh the calendar
    await _loadWeightEntries();

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Weight saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showWeightEntryDetails(DateTime date) {
    final entry = _weightEntries.firstWhere(
          (entry) => _isSameDay(entry.date, date),
      orElse: () => WeightEntry(date: date, weight: 0),
    );

    if (entry.weight == 0) return; // No entry found

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            'Weight Entry',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: ${entry.date.day}/${entry.date.month}/${entry.date.year}',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Weight: ${entry.weight.toStringAsFixed(1)} lbs',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Notes: ${entry.notes}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditWeightDialog(entry);
              },
              child: Text('Edit', style: TextStyle(color: AppTheme.primaryBlue)),
            ),
            TextButton(
              onPressed: () => _deleteWeightEntry(entry),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showEditWeightDialog(WeightEntry existingEntry) {
    final _weightController = TextEditingController(text: existingEntry.weight.toString());
    final _notesController = TextEditingController(text: existingEntry.notes ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            'Edit Weight Entry',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Date: ${existingEntry.date.day}/${existingEntry.date.month}/${existingEntry.date.year}',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Weight (lbs)',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.monitor_weight, color: AppTheme.goldenYellow),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.goldenYellow),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.goldenYellow),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _notesController,
                style: TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.note, color: AppTheme.goldenYellow),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.goldenYellow),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.goldenYellow),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => _updateWeightEntry(existingEntry, _weightController, _notesController),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateWeightEntry(WeightEntry existingEntry, TextEditingController weightController, TextEditingController notesController) async {
    if (weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final weight = double.tryParse(weightController.text);
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedEntry = WeightEntry(
      date: existingEntry.date,
      weight: weight,
      notes: notesController.text.isNotEmpty ? notesController.text : null,
    );

    // Update weight entry
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> entries = prefs.getStringList('weightEntries') ?? [];

    // Remove old entry and add updated one
    entries.removeWhere((entryJson) {
      final entry = WeightEntry.fromJson(jsonDecode(entryJson));
      return _isSameDay(entry.date, existingEntry.date);
    });

    entries.add(jsonEncode(updatedEntry.toJson()));
    await prefs.setStringList('weightEntries', entries);

    // Update user profile if this is the most recent entry
    String? userProfileJson = prefs.getString('userProfile');
    if (userProfileJson != null) {
      var userProfile = jsonDecode(userProfileJson);
      userProfile['weight'] = weight;
      await prefs.setString('userProfile', jsonEncode(userProfile));
    }

    // Refresh the calendar
    await _loadWeightEntries();

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Weight updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteWeightEntry(WeightEntry entry) async {
    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('Delete Entry', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete this weight entry?',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> entries = prefs.getStringList('weightEntries') ?? [];

      // Remove the entry
      entries.removeWhere((entryJson) {
        final existingEntry = WeightEntry.fromJson(jsonDecode(entryJson));
        return _isSameDay(existingEntry.date, entry.date);
      });

      await prefs.setStringList('weightEntries', entries);

      // Update entries count
      int entriesCount = prefs.getInt('entriesCount') ?? 0;
      await prefs.setInt('entriesCount', entriesCount - 1);

      // Refresh the calendar
      await _loadWeightEntries();

      Navigator.of(context).pop(); // Close the details dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Weight entry deleted'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildLegendAndStats() {
    final currentMonthEntries = _weightEntries.where((entry) =>
    entry.date.year == _currentDate.year && entry.date.month == _currentDate.month).length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Weight logged',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('This Month', '$currentMonthEntries entries'),
              _buildStatItem('Total', '${_weightEntries.length} entries'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}