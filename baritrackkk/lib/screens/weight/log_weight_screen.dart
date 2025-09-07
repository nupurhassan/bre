import 'package:flutter/material.dart';
import '../../models/weight_entry.dart';
import '../../services/weight_repository.dart';
import '../../theme/app_theme.dart';


class LogWeightScreen extends StatefulWidget {
  @override
  _LogWeightScreenState createState() => _LogWeightScreenState();
}

class _LogWeightScreenState extends State<LogWeightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveWeight() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final weight = double.parse(_weightController.text.trim());
      final entry = WeightEntry(date: DateTime.now(), weight: weight);

      await WeightRepository.addWeightLog(entry);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Weight logged successfully!")),
      );

      Navigator.pop(context, true); // return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving weight: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Log Weight"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Enter your weight (lbs)"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a weight";
                  }
                  if (double.tryParse(value) == null) {
                    return "Please enter a valid number";
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveWeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBeige,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text("Save Weight"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
