import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class WeightProgressCard extends StatelessWidget {
  final UserProfile userProfile;

  WeightProgressCard({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    double currentWeight = userProfile.weight ?? userProfile.startingWeight ?? 0;
    double expectedWeight = userProfile.getExpectedWeight(userProfile.weeksPostOp);
    double percentLost = _calculatePercentLost();
    String status = _getStatus();
    Color statusColor = _getStatusColor(status);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight Progress',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeightStat('Current', '${currentWeight.toStringAsFixed(1)} lbs'),
              _buildWeightStat('Expected', '${expectedWeight.toStringAsFixed(1)} lbs'),
              _buildWeightStat('% Lost', '${percentLost.toStringAsFixed(1)}%'),
            ],
          ),
          SizedBox(height: 16),
          Chip(
            label: Text(status),
            backgroundColor: statusColor,
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  double _calculatePercentLost() {
    if (userProfile.startingWeight == null || userProfile.weight == null) return 0;
    double lost = userProfile.startingWeight! - userProfile.weight!;
    return (lost / userProfile.startingWeight!) * 100;
  }

  String _getStatus() {
    double currentWeight = userProfile.weight ?? userProfile.startingWeight ?? 0;
    double expectedWeight = userProfile.getExpectedWeight(userProfile.weeksPostOp);
    double expectedLoss = (userProfile.startingWeight ?? 0) - expectedWeight;
    double actualLoss = (userProfile.startingWeight ?? 0) - currentWeight;

    if (actualLoss >= expectedLoss * 0.95) {
      return 'On Track';
    } else if (actualLoss >= expectedLoss * 0.85) {
      return 'Slightly Behind';
    } else {
      return 'Off Track';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'On Track':
        return Colors.green;
      case 'Slightly Behind':
        return Colors.orange;
      case 'Off Track':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}