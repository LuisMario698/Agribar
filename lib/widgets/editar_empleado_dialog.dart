// lib/widgets/editar_empleado_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/edicion_empleado_service.dart';
import '../services/database_service.dart';

class EditarEmpleadoDialog extends StatefulWidget {
  final Map<String, dynamic> empleadoData;
  final VoidCallback? onEmpleadoActualizado;

  const EditarEmpleadoDialog({
    Key? key,
    required this.empleadoData,
    this.onEmpleadoActualizado,
  }) : super(key: key);

  @override
  State<EditarEmpleadoDialog> createState() => _EditarEmpleadoDialogState();
}

class _EditarEmpleadoDialogState extends State<EditarEmpleadoDialog> {
  bool _guardando = false;

  // Controladores para datos editables
  late TextEditingController _codigoController;
  late TextEditingController _nombreController;
  late TextEditingController _apellidoPaternoController;
  late TextEditingController _apellidoMaternoController;
  late TextEditingController _curpController;
  late TextEditingController _rfcController;
  late TextEditingController _nssController;
  String _estadoOrigen = '';

  // Controladores para datos de nómina editables
  late TextEditingController _sueldoController;
  late TextEditingController _descuentoInfonavitController;

  // Variables para manejo de códigos disponibles
  List<String> _codigosDisponibles = [];
  String? _codigoSeleccionado;
  bool _cargandoCodigos = false;
  bool _modoCodigoPersonalizado = false;

  // Lista de estados de México
  final List<String> _estadosMexico = [
    'Aguascalientes', 'Baja California', 'Baja California Sur', 'Campeche',
    'Chiapas', 'Chihuahua', 'Ciudad de México', 'Coahuila', 'Colima',
    'Durango', 'Estado de México', 'Guanajuato', 'Guerrero', 'Hidalgo',
    'Jalisco', 'Michoacán', 'Morelos', 'Nayarit', 'Nuevo León', 'Oaxaca',
    'Puebla', 'Querétaro', 'Quintana Roo', 'San Luis Potosí', 'Sinaloa',
    'Sonora', 'Tabasco', 'Tamaulipas', 'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas',
  ];

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
    _cargarCodigosDisponibles();
  }

  /// Carga los códigos disponibles desde la base de datos
  Future<void> _cargarCodigosDisponibles() async {
    setState(() {
      _cargandoCodigos = true;
    });

    try {
      final db = DatabaseService();
      await db.connect();

      // Obtener códigos ya asignados
      final resultadoExistentes = await db.connection.query(
        'SELECT codigo FROM empleados ORDER BY CAST(codigo AS INTEGER)'
      );

      final codigosExistentes = resultadoExistentes.map((row) => row[0].toString()).toSet();

      // Generar lista de códigos disponibles (del 1 al 9999)
      final codigosDisponibles = <String>[];
      for (int i = 1; i <= 9999; i++) {
        final codigo = i.toString();
        if (!codigosExistentes.contains(codigo)) {
          codigosDisponibles.add(codigo);
        }
      }

      await db.close();

      if (mounted) {
        setState(() {
          _codigosDisponibles = codigosDisponibles;
          _cargandoCodigos = false;
          
          // Si el código actual del empleado existe en disponibles, seleccionarlo
          final codigoActual = _codigoController.text.trim();
          if (codigoActual.isNotEmpty && _codigosDisponibles.contains(codigoActual)) {
            _codigoSeleccionado = codigoActual;
          }
        });
      }
    } catch (e) {
      print('❌ Error al cargar códigos disponibles: $e');
      if (mounted) {
        setState(() {
          _cargandoCodigos = false;
        });
      }
    }
  }

  void _inicializarControladores() {
    final data = widget.empleadoData;
    
    // Debug: Imprimir los datos recibidos
    print('🔍 Datos del empleado recibidos:');
    data.forEach((key, value) {
      print('   $key: $value (${value.runtimeType})');
    });

    // Datos básicos editables
    _codigoController = TextEditingController(text: data['codigo'] ?? '');
    _nombreController = TextEditingController(text: data['nombre'] ?? '');
    _apellidoPaternoController = TextEditingController(text: data['apellido_paterno'] ?? '');
    _apellidoMaternoController = TextEditingController(text: data['apellido_materno'] ?? '');
    _curpController = TextEditingController(text: data['curp'] ?? '');
    _rfcController = TextEditingController(text: data['rfc'] ?? '');
    _nssController = TextEditingController(text: data['nss'] ?? '');
    
    // Manejar estado_origen de manera segura
    final estadoOrigenValue = data['estado_origen'];
    print('🔍 Estado origen recibido: $estadoOrigenValue (${estadoOrigenValue.runtimeType})');
    
    if (estadoOrigenValue != null && estadoOrigenValue is String && estadoOrigenValue.isNotEmpty) {
      // Verificar que el valor esté en la lista de estados válidos
      if (_estadosMexico.contains(estadoOrigenValue)) {
        _estadoOrigen = estadoOrigenValue;
        print('✅ Estado origen válido: $_estadoOrigen');
      } else {
        _estadoOrigen = '';
        print('⚠️ Estado origen no válido, estableciendo vacío');
      }
    } else {
      _estadoOrigen = '';
      print('⚠️ Estado origen nulo/vacío, estableciendo vacío');
    }

    // Datos de nómina editables - manejar valores nulos/NaN correctamente
    final sueldo = data['sueldo'];
    final descuentoInfonavit = data['descuento_infonavit'];
    
    print('🔍 Sueldo recibido: $sueldo (${sueldo.runtimeType})');
    print('🔍 Descuento Infonavit recibido: $descuentoInfonavit (${descuentoInfonavit.runtimeType})');
    
    _sueldoController = TextEditingController(
      text: (sueldo != null && sueldo is num && !sueldo.isNaN) ? sueldo.toString() : '0.0'
    );
    _descuentoInfonavitController = TextEditingController(
      text: (descuentoInfonavit != null && descuentoInfonavit is num && !descuentoInfonavit.isNaN) ? descuentoInfonavit.toString() : '0.0'
    );
    
    print('✅ Inicialización de controladores completada');
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _curpController.dispose();
    _rfcController.dispose();
    _nssController.dispose();
    _sueldoController.dispose();
    _descuentoInfonavitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header con gradiente
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7BAE2F), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar Empleado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Modificar información personal y nómina',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white, size: 24),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),

            // Content con scroll mejorado
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección de Información Personal
                    _buildSectionCard(
                      title: 'Información Personal',
                      icon: Icons.person,
                      children: [
                        // Selector de código de empleado
                        _buildCodigoSelector(),
                        SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _nombreController,
                                label: 'Nombre',
                                icon: Icons.person_outline,
                                textCapitalization: TextCapitalization.words,
                                formatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZñÑáéíóúÁÉÍÓÚüÜ\s]')),
                                  LengthLimitingTextInputFormatter(50),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _apellidoPaternoController,
                                label: 'Apellido Paterno',
                                icon: Icons.family_restroom,
                                textCapitalization: TextCapitalization.words,
                                formatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZñÑáéíóúÁÉÍÓÚüÜ\s]')),
                                  LengthLimitingTextInputFormatter(50),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _apellidoMaternoController,
                                label: 'Apellido Materno',
                                icon: Icons.family_restroom_outlined,
                                textCapitalization: TextCapitalization.words,
                                formatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZñÑáéíóúÁÉÍÓÚüÜ\s]')),
                                  LengthLimitingTextInputFormatter(50),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdownField(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Sección de Documentos Oficiales
                    _buildSectionCard(
                      title: 'Documentos Oficiales',
                      icon: Icons.description,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _curpController,
                                label: 'CURP',
                                hint: '18 caracteres alfanuméricos',
                                icon: Icons.credit_card,
                                textCapitalization: TextCapitalization.characters,
                                formatters: [
                                  LengthLimitingTextInputFormatter(18),
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _rfcController,
                                label: 'RFC',
                                hint: '12-13 caracteres alfanuméricos',
                                icon: Icons.account_balance_wallet,
                                textCapitalization: TextCapitalization.characters,
                                formatters: [
                                  LengthLimitingTextInputFormatter(13),
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _nssController,
                                label: 'NSS',
                                hint: '11 dígitos',
                                icon: Icons.medical_services,
                                keyboardType: TextInputType.number,
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdownField(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Sección de Información de Nómina
                    _buildSectionCard(
                      title: 'Información de Nómina',
                      icon: Icons.attach_money,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _sueldoController,
                                label: 'Sueldo Diario',
                                hint: 'Máximo \$999.99',
                                icon: Icons.monetization_on,
                                prefix: '\$ ',
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                formatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,2}')),
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _descuentoInfonavitController,
                                label: 'Descuento INFONAVIT',
                                hint: 'Máximo \$999.99',
                                icon: Icons.home,
                                prefix: '\$ ',
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                formatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,2}')),
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer con botones mejorados
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFF3E9D2).withOpacity(0.3),
                border: Border(
                  top: BorderSide(color: Color(0xFF7BAE2F).withOpacity(0.2), width: 1),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7BAE2F),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      shadowColor: Color(0xFF7BAE2F).withOpacity(0.3),
                    ),
                    child: _guardando 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Guardando...'),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Guardar Cambios',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Valida los datos del formulario antes de guardar
  String? _validarFormulario() {
    // Validar código (obligatorio, solo números)
    final codigoText = _codigoController.text.trim();
    if (codigoText.isEmpty) {
      return 'Debe seleccionar o ingresar un código de empleado';
    }
    if (!RegExp(r'^\d+$').hasMatch(codigoText)) {
      return 'El código debe contener solo números';
    }

    // Validar que el código no esté duplicado (excepto el actual del empleado)
    final codigoActualEmpleado = widget.empleadoData['codigo']?.toString() ?? '';
    if (codigoText != codigoActualEmpleado && !_modoCodigoPersonalizado) {
      // En modo selector, verificar que el código esté disponible
      if (!_codigosDisponibles.contains(codigoText)) {
        return 'El código seleccionado ya no está disponible. Recargue la lista o use modo personalizado.';
      }
    }

    // Validar nombre (obligatorio)
    if (_nombreController.text.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }

    // Validar apellido paterno (obligatorio)
    if (_apellidoPaternoController.text.trim().isEmpty) {
      return 'El apellido paterno es obligatorio';
    }

    // Validar CURP (18 caracteres alfanuméricos)
    final curp = _curpController.text.trim();
    if (curp.isNotEmpty && (curp.length != 18 || !RegExp(r'^[A-Z0-9]{18}$').hasMatch(curp))) {
      return 'La CURP debe tener 18 caracteres alfanuméricos en mayúsculas';
    }

    // Validar RFC (12 o 13 caracteres alfanuméricos)
    final rfc = _rfcController.text.trim();
    if (rfc.isNotEmpty && (rfc.length < 12 || rfc.length > 13 || !RegExp(r'^[A-Z0-9]+$').hasMatch(rfc))) {
      return 'El RFC debe tener entre 12 y 13 caracteres alfanuméricos en mayúsculas';
    }

    // Validar NSS (11 dígitos)
    final nss = _nssController.text.trim();
    if (nss.isNotEmpty && (nss.length != 11 || !RegExp(r'^\d{11}$').hasMatch(nss))) {
      return 'El NSS debe tener exactamente 11 dígitos';
    }

    // Validar sueldo (debe ser un número válido y mayor a 0)
    final sueldoText = _sueldoController.text.trim();
    if (sueldoText.isNotEmpty) {
      final sueldo = double.tryParse(sueldoText);
      if (sueldo == null || sueldo < 0) {
        return 'El sueldo debe ser un número válido mayor o igual a 0';
      }
      if (sueldo > 999.99) {
        return 'El sueldo no puede ser mayor a \$999.99 (límite de la base de datos)';
      }
    }

    // Validar descuento INFONAVIT (debe ser un número válido y mayor o igual a 0)
    final descuentoText = _descuentoInfonavitController.text.trim();
    if (descuentoText.isNotEmpty) {
      final descuento = double.tryParse(descuentoText);
      if (descuento == null || descuento < 0) {
        return 'El descuento INFONAVIT debe ser un número válido mayor o igual a 0';
      }
      if (descuento > 999.99) {
        return 'El descuento INFONAVIT no puede ser mayor a \$999.99 (límite de la base de datos)';
      }
    }

    return null; // Todo válido
  }

  Future<void> _guardarCambios() async {
    // Validar formulario antes de proceder
    final mensajeValidacion = _validarFormulario();
    if (mensajeValidacion != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeValidacion),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() => _guardando = true);

    try {
      // Helper para parsear valores double de manera segura
      double parseDouble(String value) {
        final parsed = double.tryParse(value);
        return (parsed == null || parsed.isNaN) ? 0.0 : parsed;
      }

      final datosCompletos = {
        // Datos básicos editables
        'codigo': _codigoController.text.trim(),
        'nombre': _nombreController.text.trim(),
        'apellido_paterno': _apellidoPaternoController.text.trim(),
        'apellido_materno': _apellidoMaternoController.text.trim(),
        'curp': _curpController.text.trim().toUpperCase(),
        'rfc': _rfcController.text.trim().toUpperCase(),
        'nss': _nssController.text.trim(),
        'estado_origen': _estadoOrigen,

        // Datos de nómina editables - parsear de manera segura
        'sueldo': parseDouble(_sueldoController.text.trim()),
        'descuento_infonavit': parseDouble(_descuentoInfonavitController.text.trim()),
      };

      final idEmpleado = widget.empleadoData['id_empleado'] as int;
      final resultado = await EdicionEmpleadoService.actualizarEmpleadoCompleto(idEmpleado, datosCompletos);

      if (resultado && mounted) {
        widget.onEmpleadoActualizado?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Empleado actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error al guardar cambios: $e');
      if (mounted) {
        String mensajeError = 'Error al guardar los cambios';
        
        // Mensajes específicos para errores comunes
        if (e.toString().contains('ya existe')) {
          mensajeError = e.toString().replaceAll('Exception: ', '');
        } else if (e.toString().contains('duplicate key')) {
          mensajeError = 'El código de empleado ya existe. Por favor, use un código diferente.';
        } else if (e.toString().contains('constraint')) {
          mensajeError = 'Los datos ingresados no son válidos. Verifique la información.';
        } else if (e.toString().contains('numeric field overflow') || e.toString().contains('999.99')) {
          mensajeError = 'Los valores monetarios no pueden exceder \$999.99. Ajuste el sueldo o descuento INFONAVIT.';
        } else if (e.toString().contains('precision')) {
          mensajeError = 'Error en formato numérico. Verifique que los valores monetarios no excedan \$999.99.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  // Helper methods para crear componentes UI modernos
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF7BAE2F).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7BAE2F).withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF7BAE2F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Color(0xFF7BAE2F),
                  size: 22,
                ),
              ),
              SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7BAE2F),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    String? prefix,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixText: prefix,
            prefixIcon: Icon(icon, color: Color(0xFF7BAE2F)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF7BAE2F), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            labelStyle: TextStyle(color: Colors.grey[700]),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: keyboardType,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          inputFormatters: formatters,
          style: TextStyle(fontSize: 16),
        ),
        if (hint != null) ...[
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text(
              hint,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ] else ...[
          SizedBox(height: 4), // Espacio más pequeño cuando no hay hint
        ],
      ],
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _estadoOrigen.isNotEmpty ? _estadoOrigen : null,
      decoration: InputDecoration(
        labelText: 'Estado de Origen',
        prefixIcon: Icon(Icons.location_on, color: Color(0xFF7BAE2F)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF7BAE2F), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        labelStyle: TextStyle(color: Colors.grey[700]),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _estadosMexico.map((estado) {
        return DropdownMenuItem(
          value: estado,
          child: Text(
            estado,
            style: TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _estadoOrigen = value ?? '');
      },
      dropdownColor: Colors.white,
      icon: Icon(Icons.arrow_drop_down, color: Color(0xFF7BAE2F)),
    );
  }

  /// Widget para seleccionar el código de empleado
  Widget _buildCodigoSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF3E9D2).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF7BAE2F).withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge, color: Color(0xFF7BAE2F), size: 20),
              SizedBox(width: 8),
              Text(
                'Código de Empleado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7BAE2F),
                ),
              ),
              Spacer(),
              // Toggle entre selector y personalizado
              Switch.adaptive(
                value: _modoCodigoPersonalizado,
                onChanged: (value) {
                  setState(() {
                    _modoCodigoPersonalizado = value;
                    if (!value && _codigoSeleccionado != null) {
                      _codigoController.text = _codigoSeleccionado!;
                    }
                  });
                },
                activeColor: Color(0xFF7BAE2F),
              ),
              SizedBox(width: 8),
              Text(
                'Personalizado',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          if (_modoCodigoPersonalizado) ...[
            // Modo personalizado - campo de texto
            _buildTextField(
              controller: _codigoController,
              label: 'Código Personalizado',
              hint: 'Ingrese un código único (solo números)',
              icon: Icons.edit,
              keyboardType: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
          ] else ...[
            // Modo selector - dropdown con códigos disponibles
            if (_cargandoCodigos)
              Container(
                height: 60,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7BAE2F)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Cargando códigos disponibles...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else if (_codigosDisponibles.isEmpty)
              Container(
                height: 60,
                alignment: Alignment.center,
                child: Text(
                  'No hay códigos disponibles',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _codigoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Seleccionar Código',
                  prefixIcon: Icon(Icons.list, color: Color(0xFF7BAE2F)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF7BAE2F), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _codigosDisponibles.take(100).map((codigo) {
                  return DropdownMenuItem(
                    value: codigo,
                    child: Text(
                      'Código $codigo',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _codigoSeleccionado = value;
                    if (value != null) {
                      _codigoController.text = value;
                    }
                  });
                },
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: Color(0xFF7BAE2F)),
                hint: Text(
                  'Seleccione un código disponible',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                menuMaxHeight: 300,
              ),
          ],
          
          if (!_modoCodigoPersonalizado && _codigosDisponibles.length > 100) ...[
            SizedBox(height: 8),
            Text(
              'Mostrando los primeros 100 códigos disponibles. Use modo personalizado para códigos específicos.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
