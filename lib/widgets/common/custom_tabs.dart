import 'package:flutter/material.dart';

/// Widget personalizado para pestañas (tabs)
/// Proporciona una interfaz de pestañas consistente y reutilizable
class CustomTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int) onTabSelected;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final EdgeInsetsGeometry? padding;

  const CustomTabBar({
    Key? key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? Color(0xFFF3F1EA);
    final effectiveSelectedColor = selectedColor ?? Color(0xFF5BA829);
    final effectiveUnselectedColor = unselectedColor ?? Colors.grey[600];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: padding ?? EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children:
            tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = index == selectedIndex;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTabSelected(index),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        tab,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected
                                  ? effectiveSelectedColor
                                  : effectiveUnselectedColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

/// Widget para indicador de pasos en un wizard/stepper
/// Proporciona una barra visual del progreso en formularios multi-paso
class StepIndicator extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? completedColor;

  const StepIndicator({
    Key? key,
    required this.steps,
    required this.currentStep,
    this.activeColor,
    this.inactiveColor,
    this.completedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? Color(0xFF5BA829);
    final effectiveInactiveColor = inactiveColor ?? Colors.grey[300]!;
    final effectiveCompletedColor = completedColor ?? Color(0xFF5BA829);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children:
            steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isActive = index == currentStep;
              final isCompleted = index < currentStep;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          // Circle indicator
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isCompleted
                                      ? effectiveCompletedColor
                                      : isActive
                                      ? effectiveActiveColor
                                      : effectiveInactiveColor,
                            ),
                            child: Center(
                              child:
                                  isCompleted
                                      ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                      : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                            ),
                          ),
                          SizedBox(height: 8),
                          // Step title
                          Text(
                            step,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isActive || isCompleted
                                      ? effectiveActiveColor
                                      : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Container(
                        height: 2,
                        width: 40,
                        margin: EdgeInsets.only(bottom: 24),
                        color:
                            isCompleted
                                ? effectiveCompletedColor
                                : effectiveInactiveColor,
                      ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
