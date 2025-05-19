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
  final TextEditingController grupoController = TextEditingController();
  final TextEditingController importeController = TextEditingController();
  DateTime? fecha;
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // Lista de actividades con datos de ejemplo
  final List<List<String>> actividades = [
    ['Destajo', '1', 'Grupo Baranzini', '\u024300', '25/04/2025'],
    ['Tapadora', '1315', 'Grupo Baranzini', '\u024300', '25/04/2025'],
    ['Limpieza', '1305', 'Grupo Baranzini', '\u024200', '25/04/2025'],
    ['Cosecha', '1400', 'Grupo Baranzini', '\u024500', '25/04/2025'],
    ['Riego', '1500', 'Grupo Baranzini', '\u024100', '25/04/2025'],
    ['Fertilización', '1600', 'Grupo Baranzini', '\u024350', '25/04/2025'],
    ['Poda', '1700', 'Grupo Baranzini', '\u024250', '25/04/2025'],
    ['Transplante', '1800', 'Grupo Baranzini', '\u024400', '25/04/2025'],
    ['Siembra', '1900', 'Grupo Baranzini', '\u024150', '25/04/2025'],
    [
      'Aplicación de Plaguicida',
      '2000',
      'Grupo Baranzini',
      '\u024300',
      '25/04/2025',
    ],
    ['Deshierbe', '2100', 'Grupo Baranzini', '\u024180', '25/04/2025'],
    ['Empaque', '2200', 'Grupo Baranzini', '\u024320', '25/04/2025'],
    ['Carga', '2300', 'Grupo Baranzini', '\u024210', '25/04/2025'],
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
    if (nombreController.text.isEmpty ||
        claveController.text.isEmpty ||
        grupoController.text.isEmpty ||
        importeController.text.isEmpty ||
        fechaController.text.isEmpty) {
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
        nombreController.text,
        claveController.text,
        grupoController.text,
        ' 243${importeController.text}',
        fechaController.text,
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
    nombreController.clear();
    claveController.clear();
    grupoController.clear();
    importeController.clear();
    fecha = null;
    fechaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = isMobile ? double.infinity : (isTablet ? 800 : 1400);
          double minHeight = isMobile ? 400 : 700;
          EdgeInsets containerMargin = isMobile ? const EdgeInsets.all(4) : const EdgeInsets.all(8);
          EdgeInsets containerPadding = isMobile ? const EdgeInsets.fromLTRB(8, 8, 8, 12) : const EdgeInsets.fromLTRB(24, 12, 24, 24);
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, minHeight: minHeight),
            child: Container(
              width: double.infinity,
              margin: containerMargin,
              decoration: BoxDecoration(
                color: Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(isMobile ? 12 : 24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: isMobile ? 8 : 24,
                    offset: Offset(0, isMobile ? 2 : 8),
                  ),
                ],
              ),
              child: Padding(
                padding: containerPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card principal
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(isMobile ? 10 : 20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: isMobile ? 6 : 12,
                            offset: Offset(0, isMobile ? 2 : 4),
                          ),
                        ],
                      ),
                      padding: isMobile ? EdgeInsets.all(10) : EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Creación de actividad',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF23611C),
                            ),
                          ),
                          SizedBox(height: isMobile ? 12 : 24),
                          // Formulario
                          Column(
                            children: [
                              isMobile
                                  ? Column(
                                      children: [
                                        _customInput(claveController, 'Clave'),
                                        SizedBox(height: 8),
                                        _customInput(nombreController, 'Nombre'),
                                        SizedBox(height: 8),
                                        _customInput(grupoController, 'Grupo'),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: _customInput(claveController, 'Clave'),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: _customInput(nombreController, 'Nombre'),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: _customInput(grupoController, 'Grupo'),
                                        ),
                                      ],
                                    ),
                              SizedBox(height: isMobile ? 8 : 16),
                              isMobile
                                  ? Column(
                                      children: [
                                        _customInput(
                                          importeController,
                                          'Importe',
                                          prefix: Text('243'),
                                        ),
                                        SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () async {
                                            DateTime? picked = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                fecha = picked;
                                                fechaController.text =
                                                    "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                                              });
                                            }
                                          },
                                          child: AbsorbPointer(
                                            child: TextField(
                                              controller: fechaController,
                                              decoration: InputDecoration(
                                                labelText: 'Fecha',
                                                hintText: 'MM/DD/YYYY',
                                                filled: true,
                                                fillColor: Color(0xFFF3F1EA),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                suffixIcon: Icon(Icons.calendar_today),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: agregarActividad,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF8AB531),
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            'Crear',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: _customInput(
                                            importeController,
                                            'Importe',
                                            prefix: Text('243'),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () async {
                                              DateTime? picked = await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime(2000),
                                                lastDate: DateTime(2100),
                                              );
                                              if (picked != null) {
                                                setState(() {
                                                  fecha = picked;
                                                  fechaController.text =
                                                      "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                                                });
                                              }
                                            },
                                            child: AbsorbPointer(
                                              child: TextField(
                                                controller: fechaController,
                                                decoration: InputDecoration(
                                                  labelText: 'Fecha',
                                                  hintText: 'MM/DD/YYYY',
                                                  filled: true,
                                                  fillColor: Color(0xFFF3F1EA),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  suffixIcon: Icon(Icons.calendar_today),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        ElevatedButton(
                                          onPressed: agregarActividad,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF0B7A2F),
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 20,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            'Crear',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 10 : 19),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(isMobile ? 10 : 20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: isMobile ? 6 : 12,
                                    offset: Offset(0, isMobile ? 2 : 4),
                                  ),
                                ],
                              ),
                              padding: isMobile ? EdgeInsets.all(10) : EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tabla de actividades',
                                    style: TextStyle(
                                      fontSize: isMobile ? 18 : 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF23611C),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 12 : 24),
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
                                        height: isMobile ? 40 : 48,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF0B7A2F),
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.search,
                                          color: Colors.white,
                                          size: isMobile ? 22 : 28,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 8 : 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isMobile ? 12 : 24),
                                  Container(
                                    height: isMobile ? 250 : 450,
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
                                                  columnSpacing: isMobile ? 8 : 24,
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
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        'Nombre',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        'Grupo',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        'Importe',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        'Fecha',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                  rows: actividadesFiltradas.map((actividad) {
                                                    return DataRow(
                                                      cells: actividad.map((cell) => DataCell(Text(cell))).toList(),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Widget personalizado para campos de entrada
  Widget _customInput(
    TextEditingController controller,
    String label, {
    Widget? prefix,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Color(0xFFF3F1EA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefix: prefix,
      ),
    );
  }

  @override
  void dispose() {
    // Limpieza de controladores
    nombreController.dispose();
    claveController.dispose();
    grupoController.dispose();
    importeController.dispose();
    fechaController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
