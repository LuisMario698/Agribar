/// Widget para botones de navegación estándar del wizard de registro.

import 'package:flutter/material.dart';

class WizardNavigationButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onCancel;

  const WizardNavigationButtons({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.onPrevious,
    required this.onNext,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color verde = Color(0xFF8AB531);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          currentStep == 0
              ? ElevatedButton.icon(
                onPressed: onCancel,
                icon: Icon(Icons.cancel, color: Color(0xFF0B7A2F)),
                label: Text(
                  'Cancelar',
                  style: TextStyle(color: Color(0xFF0B7A2F)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: verde,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: verde),
                  ),
                  elevation: 0,
                ),
              )
              : ElevatedButton.icon(
                onPressed: onPrevious,
                icon: Icon(Icons.arrow_back, color: Color(0xFF0B7A2F)),
                label: Text(
                  'Anterior',
                  style: TextStyle(color: Color(0xFF0B7A2F)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: verde,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: verde),
                  ),
                  elevation: 0,
                ),
              ),
          ElevatedButton.icon(
            onPressed: onNext,
            icon: Icon(
              currentStep == totalSteps - 1 ? Icons.check : Icons.arrow_forward,
              color: Colors.white,
            ),
            label: Text(
              currentStep == totalSteps - 1 ? 'Terminar' : 'Siguiente',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0B7A2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
