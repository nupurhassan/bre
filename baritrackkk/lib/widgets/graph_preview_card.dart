import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_profile.dart';
import '../models/weight_entry.dart';
import '../theme/app_theme.dart';
import '../screens/graph/full_graph_screen.dart';
import '../services/csv_data_service.dart';
import '../utils/date_helpers.dart';

class GraphPreviewCard extends StatefulWidget {
  final UserProfile userProfile;

  const GraphPreviewCard({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  _GraphPreviewCardState createState() => _GraphPreviewCardState();
}

class _GraphPreviewCardState extends State<GraphPreviewCard> {
  List<WeightEntry> _weightEntries = [];
  List<FlSpot> _actualWeightSpots = [];
  List<FlSpot> _expectedWeightSpots = [];
  final CSVDataService _dataService = CSVDataService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeightEntries();
  }

  @override
  void didUpdateWidget(GraphPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if the user profile changes
    if (oldWidget.userProfile != widget.userProfile) {
      _loadWeightEntries();
    }
  }

  Future<void> _loadWeightEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<WeightEntry> entries = await _dataService.loadWeightEntries();

      setState(() {
        _weightEntries = entries;
        _weightEntries.sort((a, b) => a.date.compareTo(b.date));
        _generateChartData();
        _isLoading = false;
      });

      print('Graph Preview: Loaded ${_weightEntries.length} weight entries');
    } catch (e) {
      print('Error loading weight entries for preview: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateChartData() {
    _actualWeightSpots.clear();
    _expectedWeightSpots.clear();

    // Generate expected weight loss curve (first 24 weeks for preview)
    for (int week = 0; week <= 24; week++) {
      double expectedWeight = widget.userProfile.getExpectedWeight(week);
      _expectedWeightSpots.add(FlSpot(week.toDouble(), expectedWeight));
    }

    // Generate actual weight spots
    if (widget.userProfile.surgeryDate != null && _weightEntries.isNotEmpty) {
      for (var entry in _weightEntries) {
        int weeksFromSurgery = DateHelpers.getWeeksFromSurgery(widget.userProfile.surgeryDate!, entry.date);
        if (weeksFromSurgery >= 0 && weeksFromSurgery <= 24) {
          _actualWeightSpots.add(FlSpot(weeksFromSurgery.toDouble(), entry.weight));
          print('Preview: Added weight point at week $weeksFromSurgery with weight ${entry.weight}');
        }
      }
    }

    print('Preview: Generated ${_actualWeightSpots.length} actual weight points');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FullGraphScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_down, color: AppTheme.accentOrange, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Weight Journey',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_weightEntries.isNotEmpty)
                      Text(
                        '${_weightEntries.length} entries',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 120,
              child: _isLoading
                  ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : _expectedWeightSpots.isNotEmpty
                  ? LineChart(_buildMiniLineChartData())
                  : _buildEmptyState(),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniLegendItem(AppTheme.accentOrange, 'Expected'),
                SizedBox(width: 16),
                _buildMiniLegendItem(AppTheme.primaryBlue, 'Your Weight'),
              ],
            ),
            if (_weightEntries.isNotEmpty) ...[
              SizedBox(height: 8),
              _buildQuickStats(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 32, color: AppTheme.primaryBlue),
          SizedBox(height: 8),
          Text(
            'Start logging to see progress',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_weightEntries.isEmpty || widget.userProfile.startingWeight == null) {
      return Container();
    }

    // Calculate quick stats
    List<WeightEntry> sortedEntries = List.from(_weightEntries);
    sortedEntries.sort((a, b) => a.date.compareTo(b.date));

    double startingWeight = widget.userProfile.startingWeight!;
    double currentWeight = sortedEntries.last.weight;
    double totalLoss = startingWeight - currentWeight;

    String lastLoggedDate = DateHelpers.formatDate(sortedEntries.last.date);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Lost ${totalLoss.toStringAsFixed(1)} lbs',
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Last: $lastLoggedDate',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildMiniLineChartData() {
    double maxWeight = widget.userProfile.startingWeight ?? 200;
    double minWeight = 0;

    // Calculate max weight from data
    if (_expectedWeightSpots.isNotEmpty) {
      double expectedMax = _expectedWeightSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      double expectedMin = _expectedWeightSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      maxWeight = expectedMax + 5;
      minWeight = expectedMin - 5;
    }
    if (_actualWeightSpots.isNotEmpty) {
      double actualMax = _actualWeightSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      double actualMin = _actualWeightSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      maxWeight = maxWeight > actualMax ? maxWeight : actualMax + 5;
      minWeight = minWeight < actualMin ? minWeight : actualMin - 5;
    }

    // Ensure reasonable bounds
    if (minWeight < 0) minWeight = 0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: (maxWeight - minWeight) / 3,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[700]!.withOpacity(0.3),
            strokeWidth: 0.5,
          );
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 24, // 6 months preview
      minY: minWeight,
      maxY: maxWeight,
      lineBarsData: [
        // Expected weight line
        if (_expectedWeightSpots.isNotEmpty)
          LineChartBarData(
            spots: _expectedWeightSpots,
            isCurved: true,
            color: AppTheme.accentOrange,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        // Actual weight points
        if (_actualWeightSpots.isNotEmpty)
          LineChartBarData(
            spots: _actualWeightSpots,
            isCurved: false,
            color: AppTheme.primaryBlue,
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: AppTheme.primaryBlue,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
      ],
    );
  }

  Widget _buildMiniLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}