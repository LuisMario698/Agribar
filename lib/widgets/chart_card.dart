import 'package:flutter/material.dart';

/// A generic chart card that wraps any chart widget with a title and styling.
class ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isSmallScreen;

  const ChartCard({
    Key? key,
    required this.title,
    required this.child,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adjustedPadding = isSmallScreen ? 16.0 : 20.0;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(adjustedPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          child,
        ],
      ),
    );
  }
}
