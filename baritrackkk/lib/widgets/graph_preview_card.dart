import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weight_entry.dart';
import '../models/user_profile.dart';
import '../services/weight_repository.dart';
import '../utils/date_helpers.dart';
import '../theme/app_theme.dart';
import '../screens/graph/full_graph_screen.dart';

class GraphPreviewCard extends StatefulWidget {
  final UserProfile userProfile;
  const GraphPreviewCard({Key? key, required this.userProfile}) : super(key: key);

  @override
  _GraphPreviewCardState createState() => _GraphPreviewCardState();
}

class _GraphPreviewCardState extends State<GraphPreviewCard> {
  List<WeightEntry> _weightEntries = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await WeightRepository.getWeightLogs();
    setState(() => _weightEntries = logs);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullGraphScreen())),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.accentTaupe, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Weight Journey", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _weightEntries.isEmpty
                ? Text("No logs yet", style: TextStyle(color: Colors.grey))
                : Text("Last: ${DateHelpers.formatDate(_weightEntries.last.date)}"),
          ],
        ),
      ),
    );
  }
}
