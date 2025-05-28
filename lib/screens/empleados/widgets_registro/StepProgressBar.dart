/// Widget para la barra de pasos del wizard de registro de empleados.

import 'package:flutter/material.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final List<String> titles;
  final Color activeColor;
  final Color inactiveColor;

  const StepProgressBar({
    Key? key,
    required this.currentStep,
    required this.titles,
    this.activeColor = const Color(0xFF0B7A2F),
    this.inactiveColor = const Color(0xFFBFC3C7),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(titles.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Línea entre círculos
          return Container(
            width: 60,
            height: 4,
            color: i ~/ 2 < currentStep ? activeColor : inactiveColor,
          );
        } else {
          int idx = i ~/ 2;
          return Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: idx <= currentStep ? activeColor : inactiveColor,
                child: Text(
                  '${idx + 1}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 8),
              Text(
                titles[idx],
                style: TextStyle(
                  color: idx <= currentStep ? activeColor : inactiveColor,
                  fontWeight: idx == currentStep ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
