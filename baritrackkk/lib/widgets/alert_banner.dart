import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AlertBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.withOpacity(0.2),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "You're slightly off track. Want to check in?",
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}