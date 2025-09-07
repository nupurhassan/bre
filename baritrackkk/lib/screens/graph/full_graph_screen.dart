import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/weight_entry.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../services/weight_repository.dart';
import '../../services/user_repository.dart';
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
      _userProfile = await UserRepository.loadUserProfile();
      _weightEntries = await WeightRepository.getWeightLogs();
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

  Future<void> _logWeight() async {
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your weight'), backgroundColor: Colors.red),
      );
      return;
    }
    final lbs = double.tryParse(_weightController.text);
    if (lbs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid weight'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final entry = WeightEntry(date: DateTime.now(), weight: lbs);
      await WeightRepository.addWeightLog(entry);

      if (_userProfile != null) {
        _userProfile!.weight = lbs;
        await UserRepository.saveUserProfile(_userProfile!);
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weight Progress (lbs)'),
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLogWeightCard(),
            SizedBox(height: 24),
            _buildWeightChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogWeightCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentTaupe,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Enter weight (lbs)"),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isSaving ? null : _logWeight,
            child: _isSaving ? CircularProgressIndicator() : Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    return Container(
      height: 300,
      child: _userProfile != null
          ? LineChart(_buildLineChartData())
          : Center(child: Text("Complete your profile to see progress")),
    );
  }

  LineChartData _buildLineChartData() {
    return LineChartData(
      lineBarsData: [
        if (_expectedWeightSpots.isNotEmpty)
          LineChartBarData(spots: _expectedWeightSpots, isCurved: true, color: AppTheme.accentBeige),
        if (_actualWeightSpots.isNotEmpty)
          LineChartBarData(spots: _actualWeightSpots, isCurved: false, color: AppTheme.accentBlueGrey),
      ],
    );
  }
}
