import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding/onboarding_screen.dart';
import 'home/home_screen.dart';
import '../theme/app_theme.dart';
import '../services/csv_data_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final CSVDataService _dataService = CSVDataService();

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  _navigateToNext() async {
    await Future.delayed(Duration(milliseconds: 2500));

    try {
      // Check if user profile exists (indicates app has been set up)
      final userProfile = await _dataService.loadUserProfile();
      bool isFirstTime = userProfile == null;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isFirstTime ? OnboardingScreen() : HomeScreen(),
        ),
      );
    } catch (e) {
      print('Error during splash navigation: $e');
      // Default to onboarding if there's an error
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.accentOrange,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'BariTrack',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}