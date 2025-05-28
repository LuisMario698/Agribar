/// Widget para el registro de un nuevo empleado.
/// Implementa un wizard con 3 pasos: datos personales, laborales y de nómina.

import 'package:flutter/material.dart';
import 'widgets_registro/DatosPersonalesForm.dart';
import 'widgets_registro/DatosLaboralesForm.dart';
import 'widgets_registro/DatosNominaForm.dart';
import 'widgets_registro/StepProgressBar.dart';
import 'widgets_registro/WizardNavigationButtons.dart';
import '../../widgets_shared/index.dart';

class RegistroEmpleadoWizard extends StatefulWidget {
  final void Function(List<String>) onEmpleadoRegistrado;
  const RegistroEmpleadoWizard({Key? key, required this.onEmpleadoRegistrado})
    : super(key: key);

  @override
  State<RegistroEmpleadoWizard> createState() => _RegistroEmpleadoWizardState();
}

class _RegistroEmpleadoWizardState extends State<RegistroEmpleadoWizard> {
  int _currentStep = 0;
  final int totalSteps = 3;

  // Controladores para los campos de ejemplo
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoPaternoController =
      TextEditingController();
  final TextEditingController apellidoMaternoController =
      TextEditingController();
  final TextEditingController rfcController = TextEditingController();
  final TextEditingController curpController = TextEditingController();
  String estadoOrigen = '';
  final TextEditingController nssController = TextEditingController();

  final TextEditingController registroPatronalController =
      TextEditingController();
  final TextEditingController empresaController = TextEditingController();
  final TextEditingController puestoController = TextEditingController();
  String cuadrilla = '';
  String tipoEmpleado = '';
  DateTime? fechaIngreso;
  final TextEditingController fechaIngresoController = TextEditingController();
  bool inactivo = false;
  bool deshabilitado = false;

  final TextEditingController sueldoController = TextEditingController();
  bool domingoLaboral = false;
  final TextEditingController domingoLaboralMontoController =
      TextEditingController();
  bool descuentoComedor = false;
  final TextEditingController descuentoComedorController =
      TextEditingController();
  String tipoDescuentoInfonavit = '';
  final TextEditingController descuentoInfonavitController =
      TextEditingController();

  // Lista de estados de México
  final List<String> estadosMexico = [
    'Aguascalientes',
    'Baja California',
    'Baja California Sur',
    'Campeche',
    'Chiapas',
    'Chihuahua',
    'Ciudad de México',
    'Coahuila',
    'Colima',
    'Durango',
    'Estado de México',
    'Guanajuato',
    'Guerrero',
    'Hidalgo',
    'Jalisco',
    'Michoacán',
    'Morelos',
    'Nayarit',
    'Nuevo León',
    'Oaxaca',
    'Puebla',
    'Querétaro',
    'Quintana Roo',
    'San Luis Potosí',
    'Sinaloa',
    'Sonora',
    'Tabasco',
    'Tamaulipas',
    'Tlaxcala',
    'Veracruz',
    'Yucatán',
    'Zacatecas',
  ];

  // Tipos de descuento INFONAVIT
  final List<String> tiposDescuentoInfonavit = [
    'Porcentaje',
    'Cuota fija',
    'Veces salario mínimo (VSM)',
    'Descuento extraordinario',
  ];

  void _nextStep() {
    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Validar campos obligatorios antes de finalizar
      if (_validarCamposObligatorios()) {
        // Al terminar, agrega el empleado
        widget.onEmpleadoRegistrado([
          codigoController.text,
          nombreController.text,
          apellidoPaternoController.text,
          apellidoMaternoController.text,
          cuadrilla,
          sueldoController.text,
          tipoEmpleado,
        ]);
        setState(() => _currentStep = 0);
        GenericSnackBar.showSuccess(
          context,
          'Empleado creado correctamente',
          duration: const Duration(seconds: 3),
        );
        _limpiarCampos();
      } else {
        GenericSnackBar.showError(
          context,
          'Por favor completa todos los campos obligatorios',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  bool _validarCamposObligatorios() {
    // Validar campos básicos obligatorios
    return codigoController.text.isNotEmpty &&
        nombreController.text.isNotEmpty &&
        apellidoPaternoController.text.isNotEmpty &&
        cuadrilla.isNotEmpty &&
        tipoEmpleado.isNotEmpty &&
        sueldoController.text.isNotEmpty;
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _limpiarCampos() {
    codigoController.clear();
    nombreController.clear();
    apellidoPaternoController.clear();
    apellidoMaternoController.clear();
    rfcController.clear();
    curpController.clear();
    estadoOrigen = '';
    nssController.clear();
    registroPatronalController.clear();
    empresaController.clear();
    puestoController.clear();
    cuadrilla = '';
    tipoEmpleado = '';
    fechaIngreso = null;
    fechaIngresoController.clear();
    inactivo = false;
    deshabilitado = false;
    sueldoController.clear();
    domingoLaboral = false;
    domingoLaboralMontoController.clear();
    descuentoComedor = false;
    descuentoComedorController.clear();
    tipoDescuentoInfonavit = '';
    descuentoInfonavitController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Color verde = Color(0xFF8AB531);
    final Color grisFondo = Color(0xFFE5E5E5);
    final Color grisInput = Color(0xFFF3F1EA);

    return Container(
      color: grisFondo,
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(height: 24),
          // Barra de pasos custom
          StepProgressBar(
            currentStep: _currentStep,
            titles: ['Datos Personales', 'Datos Laborales', 'Datos de Nómina'],
            activeColor: Color(0xFF0B7A2F),
            inactiveColor: Color(0xFFBFC3C7),
          ),
          SizedBox(height: 32),
          // Card del formulario
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 1200),
                margin: const EdgeInsets.symmetric(horizontal: 24),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: _buildStepContent(_currentStep, grisInput, verde),
                ),
              ),
            ),
          ),
          // Botones de navegación
          WizardNavigationButtons(
            currentStep: _currentStep,
            totalSteps: totalSteps,
            onPrevious: _prevStep,
            onNext: _nextStep,
            onCancel: () {
              // Cancelar acción
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(int step, Color grisInput, Color verde) {
    switch (step) {
      case 0:
        return DatosPersonalesForm(
          codigoController: codigoController,
          nombreController: nombreController,
          apellidoPaternoController: apellidoPaternoController,
          apellidoMaternoController: apellidoMaternoController,
          rfcController: rfcController,
          curpController: curpController,
          nssController: nssController,
          estadoOrigen: estadoOrigen,
          onEstadoOrigenChanged: (v) => setState(() => estadoOrigen = v ?? ''),
          estadosMexico: estadosMexico,
          grisInput: grisInput,
        );
      case 1:
        return DatosLaboralesForm(
          empresaController: empresaController,
          puestoController: puestoController,
          registroPatronalController: registroPatronalController,
          fechaIngresoController: fechaIngresoController,
          tipoEmpleado: tipoEmpleado,
          cuadrilla: cuadrilla,
          inactivo: inactivo,
          deshabilitado: deshabilitado,
          fechaIngreso: fechaIngreso,
          onTipoEmpleadoChanged: (v) => setState(() => tipoEmpleado = v ?? ''),
          onCuadrillaChanged: (v) => setState(() => cuadrilla = v ?? ''),
          onInactivoChanged: (v) => setState(() => inactivo = v),
          onDeshabilitadoChanged: (v) => setState(() => deshabilitado = v),
          onFechaIngresoChanged: (picked) {
            setState(() {
              fechaIngreso = picked;
              fechaIngresoController.text =
                  "${picked!.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
            });
          },
          grisInput: grisInput,
        );
      case 2:
        return DatosNominaForm(
          sueldoController: sueldoController,
          domingoLaboralMontoController: domingoLaboralMontoController,
          descuentoComedorController: descuentoComedorController,
          descuentoInfonavitController: descuentoInfonavitController,
          domingoLaboral: domingoLaboral,
          descuentoComedor: descuentoComedor,
          tipoDescuentoInfonavit: tipoDescuentoInfonavit,
          tiposDescuentoInfonavit: tiposDescuentoInfonavit,
          onDomingoLaboralChanged: (v) => setState(() => domingoLaboral = v),
          onDescuentoComedorChanged:
              (v) => setState(() => descuentoComedor = v),
          onTipoDescuentoInfonavitChanged:
              (v) => setState(() => tipoDescuentoInfonavit = v ?? ''),
          grisInput: grisInput,
          verde: verde,
        );
      default:
        return Container();
    }
  }
}
