import 'package:flutter/material.dart';

/// A generic metric card widget that displays an icon, title, and value.
/// Uses flex layout for responsive distribution of space between elements.
class GenericMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? valueColor;
  final double? iconSize;
  final double? titleSize;
  final double? valueSize;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final int? iconFlex;
  final int? titleFlex;
  final int? valueFlex;

  const GenericMetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = const Color(0xFF8AB531),
    this.backgroundColor = Colors.white,
    this.titleColor,
    this.valueColor = Colors.black,
    this.iconSize = 24,
    this.titleSize = 20,
    this.valueSize = 24,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
    this.borderRadius = const BorderRadius.all(Radius.circular(30)),
    this.boxShadow = const [
      BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
    ],
    this.iconFlex = 15,
    this.titleFlex = 50,
    this.valueFlex = 35,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            flex: iconFlex ?? 15,
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
          SizedBox(width: 18),
          Expanded(
            flex: titleFlex ?? 50,
            child: Text(
              title,
              style: TextStyle(
                fontSize: titleSize,
                color: titleColor ?? Colors.grey[700],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            flex: valueFlex ?? 35,
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
