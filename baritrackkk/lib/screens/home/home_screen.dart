import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/user_profile.dart';
import '../../models/weight_entry.dart';
import '../../theme/app_theme.dart';
import '../../services/csv_data_service.dart';
import '../../widgets/drawer_menu.dart';
import '../../widgets/weight_progress_card.dart';
import '../../widgets/graph_preview_card.dart';
import '../../widgets/alert_banner.dart';
import '../profile/profile_screen.dart';
import '../weight/log_weight_screen.dart';
import '../graph/full_graph_screen.dart';
import '../timeline/timeline_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserProfile? _userProfile;
  List<WeightEntry> _weightEntries = [];
  bool _isOffTrack = false;
  bool _isLoading = true;
  final CSVDataService _dataService = CSVDataService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user profile and weight entries from CSV
      _userProfile = await _dataService.loadUserProfile();
      _weightEntries = await _dataService.loadWeightEntries();

      if (_userProfile != null) {
        _checkIfOffTrack();
      }
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data. Please restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkIfOffTrack() {
    if (_userProfile != null) {
      double expectedWeight = _userProfile!.getExpectedWeight(_userProfile!.weeksPostOp);
      double currentWeight = _userProfile!.weight ?? _userProfile!.startingWeight ?? 0;
      double expectedLoss = (_userProfile!.startingWeight ?? 0) - expectedWeight;
      double actualLoss = (_userProfile!.startingWeight ?? 0) - currentWeight;

      _isOffTrack = actualLoss < (expectedLoss * 0.85); // 15% behind
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: DrawerMenu(userProfile: _userProfile),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your data...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No profile found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Please complete the onboarding process',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate back to onboarding
                Navigator.pushReplacementNamed(context, '/');
              },
              child: Text('Setup Profile'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${_userProfile!.name ?? "Friend"}!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(
            '${_userProfile!.weeksPostOp} weeks post-op',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 24),
          WeightProgressCard(userProfile: _userProfile!),
          SizedBox(height: 24),
          // Use a key to force rebuild of GraphPreviewCard when data changes
          GraphPreviewCard(
            key: ValueKey(_weightEntries.length), // This forces rebuild when entries change
            userProfile: _userProfile!,
          ),
          SizedBox(height: 24),
          _buildLogWeightButton(),
          SizedBox(height: 16),
          _buildDataInfo(),
          if (_isOffTrack) ...[
            SizedBox(height: 24),
            AlertBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildLogWeightButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LogWeightScreen()),
          );
          if (result == true) {
            _loadData(); // Refresh data after logging weight
          }
        },
        icon: Icon(Icons.add),
        label: Text(
          "Log This Week's Weight",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDataInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.goldenYellow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data entries: ${_weightEntries.length} • Stored in CSV files',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          IconButton(
            icon: Icon(Icons.download, color: AppTheme.primaryBlue, size: 16),
            onPressed: _exportData,
            tooltip: 'Export Data',
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final exportPath = await _dataService.exportAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // You could implement file sharing here
              print('Export path: $exportPath');
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: AppTheme.primaryBlue,
      unselectedItemColor: Colors.grey,
      backgroundColor: AppTheme.cardBackground,
      type: BottomNavigationBarType.fixed,
      onTap: _onNavigationItemTapped,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Chart'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
      ],
    );
  }

  void _onNavigationItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FullGraphScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TimelineScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        ).then((_) => _loadData()); // Refresh when returning from profile
        break;
    }
  }
}