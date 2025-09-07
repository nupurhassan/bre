import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/weight_entry.dart';
import '../../theme/app_theme.dart';
import '../../services/user_repository.dart';
import '../../services/weight_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _userProfile = await UserRepository.loadUserProfile();
      _weightEntries = await WeightRepository.getWeightLogs();

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
      setState(() => _isLoading = false);
    }
  }

  void _checkIfOffTrack() {
    if (_userProfile != null) {
      double expectedWeight =
      _userProfile!.getExpectedWeight(_userProfile!.weeksPostOp);

      double currentWeight =
      (_userProfile?.weight ?? 0) > 0 ? _userProfile!.weight! : 0;

      double expectedLoss =
          (_userProfile?.startingWeight ?? 0) - expectedWeight;

      double actualLoss =
          (_userProfile?.startingWeight ?? 0) - currentWeight;

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
            Text('No profile found',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Please complete the onboarding process',
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
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
          GraphPreviewCard(
            key: ValueKey(_weightEntries.length),
            userProfile: _userProfile!,
          ),
          SizedBox(height: 24),
          _buildLogWeightButton(),
          SizedBox(height: 16),
          if (_isOffTrack) ...[
            AlertBanner(),
            SizedBox(height: 16),
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
            _loadData();
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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: AppTheme.accentBlueGrey,
      unselectedItemColor: Colors.grey,
      backgroundColor: AppTheme.accentTaupe,
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
    setState(() => _selectedIndex = index);

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
        ).then((_) => _loadData());
        break;
    }
  }
}
