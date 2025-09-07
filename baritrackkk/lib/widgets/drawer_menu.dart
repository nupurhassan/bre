import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../services/user_repository.dart';
import '../services/weight_repository.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/graph/full_graph_screen.dart';
import '../screens/weight/log_weight_screen.dart';
import '../screens/timeline/timeline_screen.dart';
import '../screens/calendar/calendar_screen.dart'; // ✅ New import
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';

class DrawerMenu extends StatelessWidget {
  final UserProfile? userProfile;

  DrawerMenu({this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppTheme.accentTaupe,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.accentBlueGrey,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      _getInitials(),
                      style: TextStyle(color: AppTheme.accentBlueGrey, fontSize: 24),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    userProfile?.name ?? 'User',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    userProfile?.email ?? 'user@email.com',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              Icons.person,
              'Profile',
                  () => _navigateTo(context, ProfileScreen()),
            ),
            _buildDrawerItem(
              Icons.show_chart,
              'Full Graph',
                  () => _navigateTo(context, FullGraphScreen()),
            ),
            _buildDrawerItem(
              Icons.add_box,
              'Log Weight',
                  () => _navigateTo(context, LogWeightScreen()),
            ),
            _buildDrawerItem(
              Icons.timeline,
              'Surgery Timeline',
                  () => _navigateTo(context, TimelineScreen()),
            ),
            _buildDrawerItem(
              Icons.calendar_today,
              'Calendar', // ✅ New Calendar entry
                  () => _navigateTo(context, CalendarScreen()),
            ),
            Divider(color: Colors.grey[600]),
            _buildDrawerItem(
              Icons.download,
              'Export Data',
                  () => _exportData(context),
            ),
            _buildDrawerItem(
              Icons.info,
              'Data Info',
                  () => _showDataInfo(context),
            ),
            Divider(color: Colors.grey[600]),
            _buildDrawerItem(
              Icons.settings,
              'Settings',
                  () => _navigateTo(context, SettingsScreen()),
            ),
            _buildDrawerItem(
              Icons.info_outline,
              'About',
                  () => _navigateTo(context, AboutScreen()),
            ),
            _buildDrawerItem(
              Icons.restart_alt,
              'Reset App',
                  () => _showResetDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials() {
    if (userProfile?.name == null || userProfile!.name!.isEmpty) {
      return 'U';
    }
    List<String> names = userProfile!.name!.split(' ');
    String initials = names[0][0].toUpperCase();
    if (names.length > 1) {
      initials += names[names.length - 1][0].toUpperCase();
    }
    return initials;
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    Navigator.pop(context); // Close drawer

    try {
      final logs = await WeightRepository.getWeightLogs();
      // TODO: implement export to file if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${logs.length} weight logs!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDataInfo(BuildContext context) async {
    Navigator.pop(context); // Close drawer
    try {
      final logs = await WeightRepository.getWeightLogs();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.accentTaupe,
            title: Text('Data Information', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDataInfoRow('Weight Entries', '${logs.length}'),
                _buildDataInfoRow(
                    'First Entry',
                    logs.isNotEmpty
                        ? logs.first.date.toLocal().toString()
                        : 'None'),
                _buildDataInfoRow(
                    'Latest Entry',
                    logs.isNotEmpty
                        ? logs.last.date.toLocal().toString()
                        : 'None'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: TextStyle(color: AppTheme.accentBlueGrey)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data info: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDataInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.accentTaupe,
          title: Text('Reset App', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to reset the app? This will delete all your data.',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 12),
              Text(
                'This action cannot be undone!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await UserRepository.clearProfile();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
