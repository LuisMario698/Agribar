import 'package:flutter/material.dart';

// Archivo: Actividades_content.dart
// Pantalla para la gestión de actividades en el sistema Agribar
// Estructura profesionalizada y documentada en español
// No modificar la lógica ni la interfaz visual sin justificación técnica

/// Pantalla de gestión de actividades que mantiene el diseño original
class ActividadesContent extends StatefulWidget {
  @override
  State<ActividadesContent> createState() => _ActividadesContentState();
}

class _ActividadesContentState extends State<ActividadesContent> {
  // Controladores de texto
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController claveController = TextEditingController();
  final TextEditingController importeController = TextEditingController();
  DateTime? fecha;
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // Lista de actividades con datos de ejemplo
  final List<List<String>> actividades = [
    // [Clave, Fecha, Importe, Actividad]
    ['1', '25/04/2025', '\u024300', 'Destajo'],
    ['1315', '25/04/2025', '\u024300', 'Tapadora'],
    ['1305', '25/04/2025', '\u024200', 'Limpieza'],
    ['1400', '25/04/2025', '\u024500', 'Cosecha'],
    ['1500', '25/04/2025', '\u024100', 'Riego'],
    ['1600', '25/04/2025', '\u024350', 'Fertilización'],
    ['1700', '25/04/2025', '\u024250', 'Poda'],
    ['1800', '25/04/2025', '\u024400', 'Transplante'],
    ['1900', '25/04/2025', '\u024150', 'Siembra'],
    ['2000', '25/04/2025', '\u024300', 'Aplicación de Plaguicida'],
    ['2100', '25/04/2025', '\u024180', 'Deshierbe'],
    ['2200', '25/04/2025', '\u024320', 'Empaque'],
    ['2300', '25/04/2025', '\u024210', 'Carga'],
  ];

  /// Obtiene las actividades filtradas según el texto de búsqueda
  List<List<String>> get actividadesFiltradas {
    String query = searchController.text.toLowerCase();
    if (query.isEmpty) return actividades;
    return actividades
        .where((row) => row.any((cell) => cell.toLowerCase().contains(query)))
        .toList();
  }

  /// Agrega una nueva actividad a la lista
  void agregarActividad() {
    if (claveController.text.isEmpty ||
        importeController.text.isEmpty ||
        fechaController.text.isEmpty ||
        nombreController.text.isEmpty) {
      // Mostrar mensaje de error si hay campos vacíos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      actividades.add([
        claveController.text,
        fechaController.text,
        importeController.text,
        nombreController.text,
      ]);
      _limpiarCampos();
    });

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Actividad agregada correctamente'),
        backgroundColor: Color(0xFF23611C),
      ),
    );
  }

  /// Limpia todos los campos del formulario
  void _limpiarCampos() {
    claveController.clear();
    importeController.clear();
    fecha = null;
    fechaController.clear();
    nombreController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 800;
            final cardWidth = (isSmallScreen ? constraints.maxWidth * 0.9 : 1400).toDouble();

            return Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Container(
                constraints: BoxConstraints(maxWidth: cardWidth),
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
                child: Column(
                  children: [
                    // Título
                    Text(
                      'Gestión de Actividades',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 32),

                    // Contenido específico de actividades
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card principal
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Creación de actividad',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF23611C),
                                ),
                              ),
                              SizedBox(height: 24),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isSmall = constraints.maxWidth < 900;
                                  return Column(
                                    children: [
                                      Wrap(
                                        spacing: 24,
                                        runSpacing: 16,
                                        alignment: WrapAlignment.start,
                                        children: [
                                          _formInputField(claveController, 'Clave', width: isSmall ? double.infinity : 250),
                                          _fechaPickerField(width: isSmall ? double.infinity : 250),
                                          _formInputField(importeController, 'Importe', width: isSmall ? double.infinity : 250),
                                          _actividadDropdown(width: isSmall ? double.infinity : 250),
                                        ],
                                      ),
                                      SizedBox(height: 32),
                                      Center(
                                        child: SizedBox(
                                          width: 160,
                                          child: ElevatedButton(
                                            onPressed: agregarActividad,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF0B7A2F),
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Crear',
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 19),

                        // Tabla de actividades
                        Container(
                          width: double.infinity,
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
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tabla de actividades',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF23611C),
                                ),
                              ),
                              SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: searchController,
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Buscar',
                                        filled: true,
                                        fillColor: Color(0xFFF3F1EA),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomLeft: Radius.circular(12),
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF0B7A2F),
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Icon(
                                      Icons.search,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              Container(
                                height: 450,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: constraints.maxWidth,
                                        ),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: DataTable(
                                              columnSpacing: 24,
                                              border: TableBorder.all(
                                                color: Color(0xFFE5E5E5),
                                                width: 1.2,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              headingRowColor: MaterialStateProperty.all(
                                                Color(0xFFF3F3F3),
                                              ),
                                              columns: const [
                                                DataColumn(
                                                  label: Text(
                                                    'Clave',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Fecha',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Importe',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Actividad',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                              rows: actividadesFiltradas.map((actividad) {
                                                return DataRow(
                                                  cells: [
                                                    DataCell(Text(actividad[0])), // Clave
                                                    DataCell(Text(actividad[1])), // Fecha
                                                    DataCell(Text(actividad[2])), // Importe
                                                    DataCell(Text(actividad[3])), // Actividad
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget para input estilizado
  Widget _formInputField(TextEditingController controller, String label, {double width = 250}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Color(0xFFEDEDED),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // Widget para dropdown de actividad
  Widget _actividadDropdown({double width = 250}) {
    final List<String> actividades = [
      'Nombre', 'Destajo', 'Tapadora', 'Limpieza', 'Cosecha', 'Riego', 'Fertilización', 'Poda', 'Transplante', 'Siembra', 'Aplicación de Plaguicida', 'Deshierbe', 'Empaque', 'Carga'
    ];
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: nombreController.text.isEmpty ? 'Nombre' : nombreController.text,
        items: actividades.map((act) => DropdownMenuItem(value: act, child: Text(act))).toList(),
        onChanged: (value) {
          setState(() {
            nombreController.text = value ?? '';
          });
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Color(0xFFEDEDED),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelText: 'Actividad',
        ),
      ),
    );
  }

  // Widget para input de fecha
  Widget _fechaPickerField({double width = 250}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: fechaController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Fecha',
          filled: true,
          fillColor: Color(0xFFEDEDED),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: fecha ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              fecha = picked;
              fechaController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    // Limpieza de controladores
    nombreController.dispose();
    claveController.dispose();
    importeController.dispose();
    fechaController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
