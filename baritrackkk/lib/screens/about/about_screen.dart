import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital,
              size: 80,
              color: AppTheme.primaryBlue,
            ),
            SizedBox(height: 24),
            Text(
              'BariTrack',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 32),
            Text(
              'Track your bariatric surgery weight loss journey with confidence.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 48),
            Text(
              '© 2024 BariTrack',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}