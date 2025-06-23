import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/weight_entry.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../services/csv_data_service.dart';
import '../../utils/date_helpers.dart';

class FullGraphScreen extends StatefulWidget {
  @override
  _FullGraphScreenState createState() => _FullGraphScreenState();
}

class _FullGraphScreenState extends State<FullGraphScreen> {
  UserProfile? _userProfile;
  List<WeightEntry> _weightEntries = [];
  List<FlSpot> _actualWeightSpots = [];
  List<FlSpot> _expectedWeightSpots = [];
  final _weightController = TextEditingController();
  final CSVDataService _dataService = CSVDataService();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user profile and weight entries from CSV
      _userProfile = await _dataService.loadUserProfile();
      _weightEntries = await _dataService.loadWeightEntries();

      print('Loaded ${_weightEntries.length} weight entries for graph');

      if (_userProfile != null) {
        _generateChartData();
      }
    } catch (e) {
      print('Error loading data for graph: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading graph data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateChartData() {
    if (_userProfile == null) return;

    _actualWeightSpots.clear();
    _expectedWeightSpots.clear();

    // Generate expected weight loss curve with more data points for smooth curve
    for (int week = 0; week <= 52; week++) { // Extended to 52 weeks (1 year)
      double expectedWeight = _userProfile!.getExpectedWeight(week);
      _expectedWeightSpots.add(FlSpot(week.toDouble(), expectedWeight));
    }

    print('Generated ${_expectedWeightSpots.length} expected weight points');

    // Generate actual weight spots
    if (_userProfile!.surgeryDate != null && _weightEntries.isNotEmpty) {
      for (var entry in _weightEntries) {
        int weeksFromSurgery = DateHelpers.getWeeksFromSurgery(_userProfile!.surgeryDate!, entry.date);
        if (weeksFromSurgery >= 0 && weeksFromSurgery <= 52) {
          _actualWeightSpots.add(FlSpot(weeksFromSurgery.toDouble(), entry.weight));
          print('Added weight point: Week $weeksFromSurgery, Weight ${entry.weight}');
        }
      }
    }

    print('Generated ${_actualWeightSpots.length} actual weight points');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weight Progress Graph'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading graph data...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLogWeightCard(),
            SizedBox(height: 24),
            _buildWeightChart(),
            SizedBox(height: 24),
            _buildDataSummary(),
            if (_userProfile != null) ...[
              SizedBox(height: 24),
              _buildMilestonesCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogWeightCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
            children: [
              Icon(Icons.add, color: AppTheme.accentOrange, size: 20),
              SizedBox(width: 8),
              Text(
                "Log Today's Weight",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter weight (lbs)',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSaving ? null : _logWeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Best time to weigh: first thing in the morning',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
            children: [
              Icon(Icons.trending_down, color: AppTheme.accentOrange, size: 20),
              SizedBox(width: 8),
              Text(
                'Weight Journey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              if (_actualWeightSpots.isNotEmpty)
                Text(
                  '${_actualWeightSpots.length} entries',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 300,
            child: _userProfile != null
                ? LineChart(_buildLineChartData())
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Complete your profile to see progress',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData() {
    if (_userProfile == null) {
      return LineChartData();
    }

    double maxWeight = _userProfile!.startingWeight ?? 200;
    double minWeight = 0;

    // Calculate weight range from data
    if (_expectedWeightSpots.isNotEmpty) {
      double expectedMax = _expectedWeightSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      double expectedMin = _expectedWeightSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      maxWeight = expectedMax + 10;
      minWeight = expectedMin - 10;
    }
    if (_actualWeightSpots.isNotEmpty) {
      double actualMax = _actualWeightSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      double actualMin = _actualWeightSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      maxWeight = maxWeight > actualMax ? maxWeight : actualMax + 10;
      minWeight = minWeight < actualMin ? minWeight : actualMin - 10;
    }

    // Ensure minimum range
    if (minWeight < 0) minWeight = 0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: 25,
        verticalInterval: 4, // Every 4 weeks (monthly)
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[700] ?? Colors.grey,
            strokeWidth: 0.5,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey[700] ?? Colors.grey,
            strokeWidth: 0.5,
          );
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 4, // Show every 4 weeks (monthly)
            getTitlesWidget: (value, meta) {
              if (value % 4 == 0) { // Only show multiples of 4 (months)
                int month = (value / 4).round();
                return Text(
                  month.toString(),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                );
              }
              return Container();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 25,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(color: Colors.grey, fontSize: 12),
              );
            },
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 52, // Extended to 52 weeks (1 year)
      minY: minWeight,
      maxY: maxWeight,
      lineBarsData: [
        // Expected weight line
        if (_expectedWeightSpots.isNotEmpty)
          LineChartBarData(
            spots: _expectedWeightSpots,
            isCurved: true,
            color: AppTheme.accentOrange,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Only show dots at key milestones (months 1, 3, 6, 12)
                if (spot.x == 4 || spot.x == 12 || spot.x == 24 || spot.x == 52) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.accentOrange,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        // Actual weight points
        if (_actualWeightSpots.isNotEmpty)
          LineChartBarData(
            spots: _actualWeightSpots,
            isCurved: false,
            color: AppTheme.primaryBlue,
            barWidth: 0, // No connecting lines, just dots
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: AppTheme.primaryBlue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(AppTheme.accentOrange, 'Expected'),
        SizedBox(width: 24),
        _buildLegendItem(AppTheme.primaryBlue, 'Your Weight'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDataSummary() {
    if (_weightEntries.isEmpty || _userProfile == null) {
      return Container();
    }

    // Sort entries by date
    List<WeightEntry> sortedEntries = List.from(_weightEntries);
    sortedEntries.sort((a, b) => a.date.compareTo(b.date));

    double startingWeight = _userProfile!.startingWeight ?? 0;
    double currentWeight = sortedEntries.last.weight;
    double totalLoss = startingWeight - currentWeight;
    double percentLoss = startingWeight > 0 ? (totalLoss / startingWeight) * 100 : 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldenYellow.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Progress Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem('Total Loss', '${totalLoss.toStringAsFixed(1)} lbs'),
              _buildSummaryItem('% Lost', '${percentLoss.toStringAsFixed(1)}%'),
              _buildSummaryItem('Entries', '${_weightEntries.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppTheme.primaryBlue,
            fontSize: 18,
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

  Widget _buildMilestonesCard() {
    if (_userProfile == null || _userProfile!.surgeryType == null) {
      return Container();
    }

    Map<String, String> milestones = {};
    String surgeryType = _userProfile!.surgeryType!;

    switch (surgeryType) {
      case 'Gastric Bypass':
        milestones = {
          'Month 1': '10% loss',
          'Month 3': '25% loss',
          'Month 6': '50% loss',
        };
        break;
      case 'Gastric Sleeve':
        milestones = {
          'Month 1': '8% loss',
          'Month 3': '20% loss',
          'Month 6': '45% loss',
        };
        break;
      case 'Duodenal Switch':
        milestones = {
          'Month 1': '12% loss',
          'Month 3': '35% loss',
          'Month 6': '70% loss',
        };
        break;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
            children: [
              Icon(Icons.flag, color: AppTheme.goldenYellow, size: 20),
              SizedBox(width: 8),
              Text(
                '$surgeryType Expected Milestones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: milestones.entries.map((entry) =>
                _buildMilestoneItem(entry.key, entry.value)
            ).toList(),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Percentages are based on your starting weight of ${_userProfile!.startingWeight?.toStringAsFixed(1)} lbs',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(String period, String target) {
    return Column(
      children: [
        Text(
          target,
          style: TextStyle(
            color: AppTheme.accentOrange,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          period,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _logWeight() async {
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final weight = double.tryParse(_weightController.text);
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final entry = WeightEntry(
        date: DateTime.now(),
        weight: weight,
        notes: null,
      );

      // Save weight entry to CSV
      await _dataService.addWeightEntry(entry);

      // Update user profile with new weight
      if (_userProfile != null) {
        _userProfile!.weight = weight;
        await _dataService.saveUserProfile(_userProfile!);
      }

      // Update entries count in app settings
      final currentCount = await _dataService.getAppSetting<int>('entriesCount') ?? 0;
      await _dataService.setAppSetting('entriesCount', currentCount + 1);

      // Clear input and refresh chart
      _weightController.clear();
      await _loadData(); // This will refresh the graph with new data

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Weight logged successfully! Graph updated.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging weight: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}