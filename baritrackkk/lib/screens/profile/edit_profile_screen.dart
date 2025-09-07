import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../services/user_repository.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  EditProfileScreen({required this.userProfile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late UserProfile _editedProfile;

  @override
  void initState() {
    super.initState();
    _editedProfile = UserProfile.fromJson(widget.userProfile.toJson());
    _nameController = TextEditingController(text: _editedProfile.name);
    _emailController = TextEditingController(text: _editedProfile.email);
    _ageController =
        TextEditingController(text: _editedProfile.age.toString());
    _weightController =
        TextEditingController(text: _editedProfile.weight.toString());
    _heightController =
        TextEditingController(text: _editedProfile.height.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (value) => _editedProfile.name = value,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => _editedProfile.email = value,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _editedProfile.sex,
                decoration: InputDecoration(labelText: 'Sex'),
                items: ['Male', 'Female', 'Other']
                    .map((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _editedProfile.sex = value ?? "Other";
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                _editedProfile.age = int.tryParse(value) ?? 0,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(labelText: 'Current Weight (lbs)'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                _editedProfile.weight = double.tryParse(value) ?? 0,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                decoration: InputDecoration(labelText: 'Height (inches)'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                _editedProfile.height = double.tryParse(value) ?? 0,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _editedProfile.race,
                decoration: InputDecoration(labelText: 'Race'),
                items: ['Asian', 'Black', 'Hispanic', 'White', 'Other']
                    .map((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _editedProfile.race = value ?? "Other";
                  });
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    try {
      await UserRepository.saveUserProfile(_editedProfile);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
