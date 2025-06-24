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
    setState(() => _isLoading = true);
    try {
      _userProfile = await _dataService.loadUserProfile();
      _weightEntries = await _dataService.loadWeightEntries();
      if (_userProfile != null) _generateChartData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading graph data: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateChartData() {
    if (_userProfile == null) return;
    _actualWeightSpots.clear();
    _expectedWeightSpots.clear();

    for (int week = 0; week <= 52; week++) {
      final expected = _userProfile!.getExpectedWeight(week);
      _expectedWeightSpots.add(FlSpot(week.toDouble(), expected));
    }

    if (_userProfile!.surgeryDate != null && _weightEntries.isNotEmpty) {
      for (var e in _weightEntries) {
        final w = DateHelpers.getWeeksFromSurgery(_userProfile!.surgeryDate!, e.date);
        if (w >= 0 && w <= 52) {
          _actualWeightSpots.add(FlSpot(w.toDouble(), e.weight));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weight Progress (lbs)'),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Refresh Data'),
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
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add, color: AppTheme.accentOrange, size: 20),
              SizedBox(width: 8),
              Text("Log Today's Weight", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('Best time to weigh: first thing in the morning', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down, color: AppTheme.accentOrange, size: 20),
              SizedBox(width: 8),
              Text('Weight Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Spacer(),
              if (_actualWeightSpots.isNotEmpty)
                Text('${_actualWeightSpots.length} entries', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                children: [Icon(Icons.show_chart, size: 48, color: Colors.grey), SizedBox(height: 16), Text('Complete your profile to see progress', style: TextStyle(color: Colors.grey))],
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
    // determine axis bounds
    double maxW = _userProfile!.startingWeight ?? 200;
    double minW = 0;
    if (_expectedWeightSpots.isNotEmpty) {
      final maxE = _expectedWeightSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      final minE = _expectedWeightSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
      maxW = maxE + 10;
      minW = minE - 10;
    }
    if (_actualWeightSpots.isNotEmpty) {
      final maxA = _actualWeightSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      final minA = _actualWeightSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
      maxW = maxW > maxA ? maxW : maxA + 10;
      minW = minW < minA ? minW : minA - 10;
    }
    if (minW < 0) minW = 0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: 25,
        verticalInterval: 4,
        getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[700]!, strokeWidth: 0.5),
        getDrawingVerticalLine: (v) => FlLine(color: Colors.grey[700]!, strokeWidth: 0.5),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 4,
            getTitlesWidget: (v, _) => v % 4 == 0
                ? Text('${(v / 4).round()}', style: TextStyle(color: Colors.grey, fontSize: 12))
                : Container(),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25,
            getTitlesWidget: (value, _) => Text('${value.toInt()} lb', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 52,
      minY: minW,
      maxY: maxW,
      lineBarsData: [
        if (_expectedWeightSpots.isNotEmpty)
          LineChartBarData(
            spots: _expectedWeightSpots,
            isCurved: true,
            color: AppTheme.accentOrange,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, _, __, ___) {
                if (s.x == 4 || s.x == 12 || s.x == 24 || s.x == 52) {
                  return FlDotCirclePainter(radius: 4, color: AppTheme.accentOrange, strokeWidth: 2, strokeColor: Colors.white);
                }
                return FlDotCirclePainter(radius: 0, color: Colors.transparent);
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        if (_actualWeightSpots.isNotEmpty)
          LineChartBarData(
            spots: _actualWeightSpots,
            isCurved: false,
            color: AppTheme.primaryBlue,
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, _, __, ___) => FlDotCirclePainter(radius: 5, color: AppTheme.primaryBlue, strokeWidth: 2, strokeColor: Colors.white),
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
        _buildLegendItem(AppTheme.accentOrange, 'Expected (lbs)'),
        SizedBox(width: 24),
        _buildLegendItem(AppTheme.primaryBlue, 'Your Weight (lbs)'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildDataSummary() {
    if (_weightEntries.isEmpty || _userProfile == null) return Container();

    final sorted = List<WeightEntry>.from(_weightEntries)..sort((a, b) => a.date.compareTo(b.date));
    final start = _userProfile!.startingWeight ?? 0;
    final current = sorted.last.weight;
    final loss = start - current;
    final pct  = start > 0 ? loss / start * 100 : 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldenYellow.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('Progress Summary', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem('Total Loss', '${loss.toStringAsFixed(1)} lbs'),
              _buildSummaryItem('% Lost', '${pct.toStringAsFixed(1)}%'),
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
        Text(value, style: TextStyle(color: AppTheme.primaryBlue, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMilestonesCard() {
    if (_userProfile?.surgeryType == null) return Container();
    final type = _userProfile!.surgeryType!;
    final map = <String, String>{};
    switch (type) {
      case 'Gastric Bypass':
        map.addAll({'Month 1': '10% loss', 'Month 3': '25% loss', 'Month 6': '50% loss'});
        break;
      case 'Gastric Sleeve':
        map.addAll({'Month 1': '8% loss', 'Month 3': '20% loss', 'Month 6': '45% loss'});
        break;
      case 'Duodenal Switch':
        map.addAll({'Month 1': '12% loss', 'Month 3': '35% loss', 'Month 6': '70% loss'});
        break;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: AppTheme.goldenYellow, size: 20),
              SizedBox(width: 8),
              Text('$type Expected Milestones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: map.entries.map((e) => _buildMilestoneItem(e.key, e.value)).toList()),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Percentages based on your starting weight of ${_userProfile!.startingWeight?.toStringAsFixed(1)} lbs',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
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
        Text(target, style: TextStyle(color: AppTheme.accentOrange, fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(period, style: TextStyle(color: Colors.grey, fontSize: 12)),
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
    final lbs = double.tryParse(_weightController.text);
    if (lbs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final entry = WeightEntry(date: DateTime.now(), weight: lbs);
      await _dataService.addWeightEntry(entry);

      if (_userProfile != null) {
        _userProfile!.weight = lbs;
        await _dataService.saveUserProfile(_userProfile!);
      }
      final cnt = await _dataService.getAppSetting<int>('entriesCount') ?? 0;
      await _dataService.setAppSetting('entriesCount', cnt + 1);

      _weightController.clear();
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Weight logged successfully! Graph updated.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging weight: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
