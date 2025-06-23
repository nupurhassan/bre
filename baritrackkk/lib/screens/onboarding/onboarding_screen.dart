import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../services/csv_data_service.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  UserProfile _userProfile = UserProfile();
  final CSVDataService _dataService = CSVDataService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildPageIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _CombinedSurgeryInfoPage(
                    userProfile: _userProfile,
                    onNext: () => _nextPage(),
                  ),
                  _PersonalInfoPage(
                    userProfile: _userProfile,
                    onNext: () => _nextPage(),
                  ),
                  _ResultPage(
                    userProfile: _userProfile,
                    onComplete: () => _completeOnboarding(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) { // Changed from 4 to 3 pages
          return Container(
            width: index == _currentPage ? 24 : 8,
            height: 8,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == _currentPage ? AppTheme.primaryBlue : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completeOnboarding() async {
    try {
      // Save user profile to CSV
      await _dataService.saveUserProfile(_userProfile);

      // Save first-time flag to app settings
      await _dataService.setAppSetting('isFirstTime', false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      print('Error completing onboarding: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Combined Surgery Date and Type Page
class _CombinedSurgeryInfoPage extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback onNext;

  _CombinedSurgeryInfoPage({required this.userProfile, required this.onNext});

  @override
  __CombinedSurgeryInfoPageState createState() => __CombinedSurgeryInfoPageState();
}

class __CombinedSurgeryInfoPageState extends State<_CombinedSurgeryInfoPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about your surgery',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 32),

          // Surgery Date Section
          Text(
            'Surgery Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          InkWell(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  widget.userProfile.surgeryDate = picked;
                });
              }
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.goldenYellow),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.userProfile.surgeryDate != null
                        ? '${widget.userProfile.surgeryDate!.day}/${widget.userProfile.surgeryDate!.month}/${widget.userProfile.surgeryDate!.year}'
                        : 'Select Date',
                    style: TextStyle(fontSize: 16),
                  ),
                  Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),

          SizedBox(height: 32),

          // Surgery Type Section
          Text(
            'Surgery Type',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: widget.userProfile.surgeryType,
            decoration: InputDecoration(
              labelText: 'Select your surgery type',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.goldenYellow),
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.goldenYellow),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: ['Gastric Sleeve', 'Gastric Bypass', 'Duodenal Switch'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                widget.userProfile.surgeryType = value;
              });
            },
          ),

          SizedBox(height: 40),

          // Continue Button
          Center(
            child: ElevatedButton(
              onPressed: _canProceed() ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (!_canProceed()) ...[
            SizedBox(height: 16),
            Center(
              child: Text(
                'Please select both surgery date and type to continue',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canProceed() {
    return widget.userProfile.surgeryDate != null &&
        widget.userProfile.surgeryType != null;
  }
}

// Personal Info Page (unchanged)
class _PersonalInfoPage extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback onNext;

  _PersonalInfoPage({required this.userProfile, required this.onNext});

  @override
  __PersonalInfoPageState createState() => __PersonalInfoPageState();
}

class __PersonalInfoPageState extends State<_PersonalInfoPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 32),
          DropdownButtonFormField<String>(
            value: widget.userProfile.sex,
            decoration: InputDecoration(labelText: 'Sex'),
            items: ['Male', 'Female', 'Other'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                widget.userProfile.sex = value;
              });
            },
          ),
          SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Age'),
            onChanged: (value) {
              widget.userProfile.age = int.tryParse(value);
            },
          ),
          SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Weight (lbs)'),
            onChanged: (value) {
              widget.userProfile.weight = double.tryParse(value);
              widget.userProfile.startingWeight = widget.userProfile.weight;
            },
          ),
          SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Height (cm)'),
            onChanged: (value) {
              widget.userProfile.height = double.tryParse(value);
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: widget.userProfile.race,
            decoration: InputDecoration(labelText: 'Race'),
            items: ['Asian', 'Black', 'Hispanic', 'White', 'Other'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                widget.userProfile.race = value;
              });
            },
          ),
          SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: widget.onNext,
              child: Text('Next', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// Result Page (unchanged)
class _ResultPage extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback onComplete;

  _ResultPage({required this.userProfile, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Journey Begins!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 32),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.goldenYellow),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your BMI: ${userProfile.bmi.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 16),
                Text('Expected Weight Loss Timeline:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Month 1: ${userProfile.getExpectedWeight(4).toStringAsFixed(1)} lbs'),
                Text('Month 3: ${userProfile.getExpectedWeight(12).toStringAsFixed(1)} lbs'),
                Text('Month 6: ${userProfile.getExpectedWeight(24).toStringAsFixed(1)} lbs'),
              ],
            ),
          ),
          SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: Text('Get Started', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}