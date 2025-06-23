import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/weight_entry.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../services/csv_data_service.dart';

class LogWeightScreen extends StatefulWidget {
  @override
  _LogWeightScreenState createState() => _LogWeightScreenState();
}

class _LogWeightScreenState extends State<LogWeightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  final CSVDataService _dataService = CSVDataService();

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log Weight'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Your Weight',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 32),
              InkWell(
                onTap: _selectDate,
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
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (lbs)',
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  final weight = double.parse(value);
                  if (weight <= 0 || weight > 1000) {
                    return 'Please enter a realistic weight';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveWeight,
                      icon: _isSaving
                          ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Weight'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveWeight() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final weight = double.parse(_weightController.text);
        final entry = WeightEntry(
          date: _selectedDate,
          weight: weight,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        // Save weight entry to CSV
        await _dataService.addWeightEntry(entry);

        // Update user profile with new weight if this is the most recent entry
        final userProfile = await _dataService.loadUserProfile();
        if (userProfile != null) {
          // Check if this is the most recent entry
          final allEntries = await _dataService.loadWeightEntries();
          if (allEntries.isNotEmpty) {
            allEntries.sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
            if (allEntries.first.date.isAtSameMomentAs(_selectedDate)) {
              // This is the most recent entry, update profile
              userProfile.weight = weight;
              await _dataService.saveUserProfile(userProfile);
            }
          }
        }

        // Update entries count in app settings
        final currentCount = await _dataService.getAppSetting<int>('entriesCount') ?? 0;
        await _dataService.setAppSetting('entriesCount', currentCount + 1);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weight saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true); // Return true to indicate success
      } catch (e) {
        print('Error saving weight: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving weight: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}