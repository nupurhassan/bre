import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../services/csv_data_service.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/graph/full_graph_screen.dart';
import '../screens/weight/log_weight_screen.dart';
import '../screens/timeline/timeline_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';

class DrawerMenu extends StatelessWidget {
  final UserProfile? userProfile;
  final CSVDataService _dataService = CSVDataService();

  DrawerMenu({this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppTheme.cardBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
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
                      style: TextStyle(color: AppTheme.primaryBlue, fontSize: 24),
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
              Icons.info,
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
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Exporting data...', style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        },
      );

      final exportPath = await _dataService.exportAllData();

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Show Path',
            onPressed: () {
              _showExportPath(context, exportPath);
            },
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showExportPath(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('Export Location', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your data has been exported to:', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 8),
              SelectableText(
                path,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: AppTheme.primaryBlue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDataInfo(BuildContext context) async {
    Navigator.pop(context); // Close drawer

    try {
      final weightEntries = await _dataService.loadWeightEntries();
      final settings = await _dataService.loadAppSettings();
      final entriesCount = settings['entriesCount'] ?? 0;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: Text('Data Information', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDataInfoRow('Weight Entries', '${weightEntries.length}'),
                _buildDataInfoRow('Total Logs', '$entriesCount'),
                _buildDataInfoRow('Storage Type', 'CSV Files'),
                _buildDataInfoRow('First Entry', weightEntries.isNotEmpty
                    ? '${weightEntries.first.date.day}/${weightEntries.first.date.month}/${weightEntries.first.date.year}'
                    : 'None'),
                _buildDataInfoRow('Latest Entry', weightEntries.isNotEmpty
                    ? '${weightEntries.last.date.day}/${weightEntries.last.date.month}/${weightEntries.last.date.year}'
                    : 'None'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: TextStyle(color: AppTheme.primaryBlue)),
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
          backgroundColor: AppTheme.cardBackground,
          title: Text('Reset App', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to reset the app? This will delete all your data including:',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 12),
              Text('• User profile', style: TextStyle(color: Colors.white)),
              Text('• All weight entries', style: TextStyle(color: Colors.white)),
              Text('• App settings', style: TextStyle(color: Colors.white)),
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
                try {
                  await _dataService.clearAllData();
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error resetting app: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}