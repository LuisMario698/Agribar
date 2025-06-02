import 'package:flutter/material.dart';

/// A generic indicator card that displays an icon, title, and value.
class IndicatorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const IndicatorCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = Colors.white,
    this.onTap,
  }) : super(key: key);

  String _formatValue(String value) {
    // Function to format numeric values
    String formatNumber(String numStr) {
      try {
        double number = double.parse(numStr);
        if (number == number.toInt()) {
          // If it's a whole number, return without decimals
          return number.toInt().toString();
        }
        // Otherwise return with 2 decimal places
        return number.toStringAsFixed(2);
      } catch (_) {
        return numStr;
      }
    }

    // Handle currency values
    if (value.startsWith('\$')) {
      String numStr = value.substring(1); // Remove $ prefix
      return '\$${formatNumber(numStr)}';
    }

    // Handle normal numeric values
    return formatNumber(value);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20.0, color: const Color(0xFF0B7A2F)),
                  const SizedBox(width: 12.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        _formatValue(value),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
