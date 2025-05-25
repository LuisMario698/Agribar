import 'package:flutter/material.dart';

/// A generic metric card that displays a title, value and optional icon.
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final double? fontSize;
  final bool isSmallScreen;

  const MetricCard({
    Key? key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.fontSize,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adjustedFontSize = fontSize ?? (isSmallScreen ? 24.0 : 32.0);
    final adjustedPadding = isSmallScreen ? 16.0 : 24.0;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      padding: EdgeInsets.symmetric(
        horizontal: adjustedPadding,
        vertical: adjustedPadding * 0.8,
      ),
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
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: adjustedFontSize,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black,
                ),
              ),
              if (icon != null) ...[
                SizedBox(width: 8),
                Icon(
                  icon,
                  color: iconColor ?? Colors.black,
                  size: isSmallScreen ? 24 : 32,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
