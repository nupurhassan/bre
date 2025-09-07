import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/weight_repository.dart';
import '../../models/weight_entry.dart';
import '../../utils/date_helpers.dart';
import '../../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<WeightEntry>> _entriesByDay = {};

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await WeightRepository.getWeightLogs();

    final Map<DateTime, List<WeightEntry>> grouped = {};
    for (var entry in logs) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      grouped.putIfAbsent(day, () => []).add(entry);
    }

    setState(() {
      _entriesByDay = grouped;
    });
  }

  List<WeightEntry> _getEventsForDay(DateTime day) {
    return _entriesByDay[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Weight Calendar")),
      body: Column(
        children: [
          TableCalendar<WeightEntry>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.accentBlueGrey,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppTheme.accentBeige,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppTheme.accentBeige,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focused) {
              _focusedDay = focused;
            },
          ),
          SizedBox(height: 12),
          Expanded(
            child: _selectedDay == null
                ? Center(child: Text("Select a date"))
                : _buildLogsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    final logs = _getEventsForDay(_selectedDay!);
    if (logs.isEmpty) {
      return Center(child: Text("No logs for this date"));
    }
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, i) {
        final entry = logs[i];
        return ListTile(
          leading: Icon(Icons.monitor_weight, color: AppTheme.accentBlueGrey),
          title: Text("${entry.weight.toStringAsFixed(1)} lbs"),
          subtitle: Text(DateHelpers.formatDate(entry.date)),
        );
      },
    );
  }
}
