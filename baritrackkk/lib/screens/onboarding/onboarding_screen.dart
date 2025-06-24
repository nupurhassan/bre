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
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final UserProfile _userProfile = UserProfile();
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
                    onNext: _nextPage,
                  ),
                  _PersonalInfoPage(
                    userProfile: _userProfile,
                    onNext: _nextPage,
                  ),
                  _ResultPage(
                    userProfile: _userProfile,
                    onComplete: _completeOnboarding,
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
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Container(
            width: index == _currentPage ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completeOnboarding() async {
    try {
      await _dataService.saveUserProfile(_userProfile);
      await _dataService.setAppSetting('isFirstTime', false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _CombinedSurgeryInfoPage extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback onNext;

  const _CombinedSurgeryInfoPage({required this.userProfile, required this.onNext});

  @override
  __CombinedSurgeryInfoPageState createState() => __CombinedSurgeryInfoPageState();
}

class __CombinedSurgeryInfoPageState extends State<_CombinedSurgeryInfoPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about your surgery',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          const Text(
            'Surgery Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
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
              padding: const EdgeInsets.all(16),
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
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Surgery Type',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
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
            items: ['Gastric Sleeve', 'Gastric Bypass', 'Duodenal Switch']
                .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => widget.userProfile.surgeryType = v),
          ),
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          if (!_canProceed()) ...[
            const SizedBox(height: 16),
            const Center(
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
    return widget.userProfile.surgeryDate != null && widget.userProfile.surgeryType != null;
  }
}

class _PersonalInfoPage extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback onNext;

  const _PersonalInfoPage({required this.userProfile, required this.onNext});

  @override
  __PersonalInfoPageState createState() => __PersonalInfoPageState();
}

class __PersonalInfoPageState extends State<_PersonalInfoPage> {
  int? _selectedFeet;
  int? _selectedInches;

  @override
  void initState() {
    super.initState();
    if (widget.userProfile.height != null) {
      _selectedFeet = (widget.userProfile.height! / 12).floor();
      _selectedInches = widget.userProfile.height!.toInt() % 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us about yourself', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            value: widget.userProfile.sex,
            decoration: const InputDecoration(labelText: 'Sex'),
            items: ['Male', 'Female', 'Other'].map((v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => widget.userProfile.sex = v),
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Age'),
            onChanged: (val) => widget.userProfile.age = int.tryParse(val),
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Weight (lbs)'),
            onChanged: (val) {
              final lbs = double.tryParse(val);
              widget.userProfile.weight = lbs;
              widget.userProfile.startingWeight = lbs;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Feet',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  value: _selectedFeet,
                  items: List.generate(7, (i) => i + 2)
                      .map((feet) => DropdownMenuItem<int>(value: feet, child: Text('$feet ft')))
                      .toList(),
                  onChanged: (feet) => setState(() {
                    _selectedFeet = feet;
                    if (_selectedInches != null) {
                      widget.userProfile.height = (feet! * 12 + _selectedInches!).toDouble();
                    }
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Inches',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  value: _selectedInches,
                  items: List.generate(12, (i) => i)
                      .map((inch) => DropdownMenuItem<int>(value: inch, child: Text('$inch in')))
                      .toList(),
                  onChanged: (inch) => setState(() {
                    _selectedInches = inch;
                    if (_selectedFeet != null) {
                      widget.userProfile.height = (_selectedFeet! * 12 + inch!).toDouble();
                    }
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: widget.userProfile.race,
            decoration: const InputDecoration(labelText: 'Race'),
            items: const ['Asian', 'Black', 'Hispanic', 'White', 'Other']
                .map((v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => widget.userProfile.race = v),
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: widget.onNext,
              child: const Text('Next', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPage extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback onComplete;

  const _ResultPage({required this.userProfile, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Journey Begins!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.goldenYellow),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your BMI: ${userProfile.bmi.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 16),
                Text(
                  'Expected Weight Loss Timeline:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Month 1: ${userProfile.getExpectedWeight(4).toStringAsFixed(1)} lbs',
                ),
                Text(
                  'Month 3: ${userProfile.getExpectedWeight(12).toStringAsFixed(1)} lbs',
                ),
                Text(
                  'Month 6: ${userProfile.getExpectedWeight(24).toStringAsFixed(1)} lbs',
                ),
              ],
            ),

          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
              child: const Text('Get Started', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
