import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  int _entriesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadEntriesCount();
  }

  Future<void> _loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userProfileJson = prefs.getString('userProfile');
    if (userProfileJson != null) {
      setState(() {
        _userProfile = UserProfile.fromJson(jsonDecode(userProfileJson));
      });
    }
  }

  Future<void> _loadEntriesCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _entriesCount = prefs.getInt('entriesCount') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                _getInitials(),
                style: TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
            SizedBox(height: 16),
            Text(
              _userProfile!.name ?? 'User',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              _userProfile!.email ?? 'user@email.com',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(userProfile: _userProfile!),
                  ),
                );
                if (result == true) {
                  _loadUserProfile();
                }
              },
              child: Text('Edit Profile'),
            ),
            SizedBox(height: 32),
            _buildProfileCard('BMI', _userProfile!.bmi.toStringAsFixed(1), Icons.monitor_weight),
            SizedBox(height: 16),
            _buildProfileCard('Entries', _entriesCount.toString(), Icons.list_alt),
            SizedBox(height: 32),
            TextButton(
              onPressed: () => _handleLogout(),
              child: Text('Log Out', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials() {
    if (_userProfile?.name == null || _userProfile!.name!.isEmpty) {
      return 'U';
    }
    List<String> names = _userProfile!.name!.split(' ');
    String initials = names[0][0].toUpperCase();
    if (names.length > 1) {
      initials += names[names.length - 1][0].toUpperCase();
    }
    return initials;
  }

  Widget _buildProfileCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldenYellow),
        color: AppTheme.cardBackground,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.goldenYellow),
              SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 16)),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}