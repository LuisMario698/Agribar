import 'package:flutter/material.dart';

class EmpleadosMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  const EmpleadosMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = const Color(0xFF8AB531),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(flex: 15, child: Icon(icon, size: 24, color: iconColor)),
          SizedBox(width: 18),
          Expanded(
            flex: 50,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            flex: 35,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
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
