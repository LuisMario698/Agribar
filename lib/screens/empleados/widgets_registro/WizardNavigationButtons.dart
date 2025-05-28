/// Widget para botones de navegación estándar del wizard de registro.

import 'package:flutter/material.dart';
import '../../../widgets_shared/generic_icon_button.dart';

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
              ? generic_icon_button(
                onPressed: onCancel,
                icon: Icons.cancel,
                label: 'Cancelar',
                backgroundColor: verde,
                foregroundColor: Color(0xFF0B7A2F),
                outlined: true,
              )
              : generic_icon_button(
                onPressed: onPrevious,
                icon: Icons.arrow_back,
                label: 'Anterior',
                backgroundColor: verde,
                foregroundColor: Color(0xFF0B7A2F),
                outlined: true,
              ),
          generic_icon_button(
            onPressed: onNext,
            icon:
                currentStep == totalSteps - 1
                    ? Icons.check
                    : Icons.arrow_forward,
            label: currentStep == totalSteps - 1 ? 'Terminar' : 'Siguiente',
            backgroundColor: Color(0xFF0B7A2F),
            foregroundColor: Colors.white,
            outlined: false,
          ),
        ],
      ),
    );
  }
}
