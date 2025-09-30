// Archivo: Cuadrilla_Content.dart
// Pantalla para la gestión de cuadrillas en el sistema Agribar
// Documentación y estructura profesionalizada
import 'package:flutter/material.dart';
import '../services/registrarCuadrillaEnBD.dart';
import '../services/cargarCuadrillasDesdeBD.dart';
import '../services/auth_validation_service.dart';
import '../services/control_usuario_service.dart';
import '../services/database_service.dart';
import 'widgets_general/seleccionar_actividad_screen.dart';
// Widget principal de la pantalla de cuadrillas
class CuadrillaContent extends StatefulWidget {
  const CuadrillaContent({Key? key}) : super(key: key);

  @override
  State<CuadrillaContent> createState() => _CuadrillaContentState();
}

class _CuadrillaContentState extends State<CuadrillaContent> {
  // Controladores para los campos de texto
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController grupoController = TextEditingController();
  final TextEditingController claveController = TextEditingController();
  String? actividadSeleccionada;

  // Variables para el selector de clave
  List<String> _clavesDisponibles = [];
  String? _claveSeleccionada;
  bool _cargandoClaves = false;
  bool _modoClavePersonalizada = false;

  final TextEditingController searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();

  // Controladores para el diálogo de autenticación
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  // Servicio de autenticación con base de datos
  final AuthValidationService _authService = AuthValidationService();
  final ControlUsuarioService _controlUsuario = ControlUsuarioService();

  // Lista de cuadrillas (mock data) ahora con estado habilitado/deshabilitado
  

  // Lista filtrada para mostrar en la tabla
  List<Map<String, dynamic>> cuadrillasFiltradas = [];
  List<Map<String, dynamic>> cuadrillas = [];
  @override
  void initState() {
    super.initState();
    cargarCuadrillas();
    _cargarClavesDisponibles();
    cuadrillasFiltradas = List.from(cuadrillas);
  }

  /// Carga las claves disponibles desde la base de datos
  Future<void> _cargarClavesDisponibles() async {
    if (_cargandoClaves) return;
    
    setState(() {
      _cargandoClaves = true;
    });

    try {
      final db = DatabaseService();
      await db.connect();
      
      // Generar 100 claves disponibles que NO estén en uso
      final result = await db.connection.query("""
        WITH RECURSIVE numeros AS (
          SELECT 1 as num
          UNION ALL
          SELECT num + 1 
          FROM numeros 
          WHERE num < 100
        ),
        claves_usadas AS (
          SELECT clave::INTEGER as clave_num 
          FROM cuadrillas 
          WHERE clave ~ '^[0-9]+\$'
        )
        SELECT numeros.num::text as clave_disponible
        FROM numeros
        LEFT JOIN claves_usadas ON numeros.num = claves_usadas.clave_num
        WHERE claves_usadas.clave_num IS NULL
        ORDER BY numeros.num
        LIMIT 100;
      """);

      if (result.isNotEmpty) {
        _clavesDisponibles = result.map((row) => row[0] as String).toList();
        print('✅ Claves disponibles cargadas: ${_clavesDisponibles.length}');
        print('📋 Primeras 10 claves: ${_clavesDisponibles.take(10).join(", ")}');
      } else {
        // Si no hay claves disponibles (todos los números del 1-100 están usados)
        // Generar claves a partir del 101
        _clavesDisponibles = List.generate(100, (index) => (101 + index).toString());
        print('⚠️ Todas las claves 1-100 están usadas. Generando 101-200.');
      }
      
      setState(() {
        _cargandoClaves = false;
      });
      
      await db.close();
    } catch (e) {
      print('❌ Error al cargar claves disponibles: $e');
      setState(() {
        // Fallback: generar claves básicas disponibles
        _clavesDisponibles = List.generate(100, (index) => (index + 1).toString());
        _cargandoClaves = false;
      });
    }
  }

  /// Widget para el dropdown de claves disponibles
  Widget _buildClaveDropdown(Color fillColor) {
    return DropdownButtonFormField<String>(
      value: _claveSeleccionada,
      items: _clavesDisponibles.map((clave) => DropdownMenuItem(
        value: clave,
        child: Text('Clave $clave', style: TextStyle(fontSize: 16)),
      )).toList(),
      onChanged: (valor) {
        setState(() {
          _claveSeleccionada = valor;
          if (valor != null) {
            claveController.text = valor;
          }
        });
      },
      decoration: InputDecoration(
        hintText: _cargandoClaves ? "Cargando..." : null, // Sin placeholder cuando no está cargando
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        suffixIcon: _cargandoClaves 
          ? SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B7A2F)),
                ),
              ),
            )
          : null, // Sin icono extra cuando no está cargando
      ),
    );
  }

Future<void> cargarCuadrillas() async {
  final datos = await obtenerCuadrillasDesdeBD();
  setState(() {
    cuadrillas = datos;
    cuadrillasFiltradas = List.from(datos);
  });
}
  // Filtra las cuadrillas según el texto de búsqueda
  void _buscarCuadrilla() {
    String query = searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        cuadrillasFiltradas = List.from(cuadrillas);
      } else {
        cuadrillasFiltradas = cuadrillas.where((c) {
          // Buscar por nombre
          bool coincideNombre = c['nombre']!.toLowerCase().contains(query);
          
          // Buscar por clave
          bool coincideClave = c['clave']?.toString().toLowerCase().contains(query) ?? false;
          
          // Devolver true si coincide con nombre O clave
          return coincideNombre || coincideClave;
        }).toList();
      }
    });
  }
// Crear cuadrilla *****----------------------******
  void _crearCuadrilla() async {
  if (nombreController.text.isEmpty ||
      grupoController.text.isEmpty ||
      actividadSeleccionada == null ||
      claveController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor llena todos los campos.')),
    );
    return;
  }

  // Verificar si la clave ya existe
  final claveElegida = claveController.text.trim();
  final claveExistente = cuadrillas.any((c) => c['clave'] == claveElegida);
  
  if (claveExistente) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('La clave "$claveElegida" ya está en uso. Por favor elige otra.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final nuevaCuadrilla = {
    'nombre': nombreController.text,
    'grupo': grupoController.text,
    'actividad': actividadSeleccionada!,
    'clave': claveElegida, // Usar la clave seleccionada o personalizada
    'estado': true,
  };

  await registrarCuadrillaEnBD(nuevaCuadrilla);

  // Recargar cuadrillas desde la base de datos para obtener el ID generado
  await cargarCuadrillas();
  await _cargarClavesDisponibles(); // Recargar claves disponibles

  setState(() {
    nombreController.clear();
    grupoController.clear();
    claveController.clear();
    actividadSeleccionada = null;
    _claveSeleccionada = null;
    _modoClavePersonalizada = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Cuadrilla creada correctamente'),
      backgroundColor: Colors.green,
    ),
  );
}
  // Función para cambiar el estado de habilitado/deshabilitado
  Future<void> _toggleHabilitado(int index) async {
    // Mostrar diálogo de autenticación con validación por base de datos
    Map<String, dynamic>? userData = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.security, color: Color(0xFF0B7A2F)),
              SizedBox(width: 12),
              Text('Autenticación Requerida'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Solo administradores y supervisores pueden cambiar el estado de las cuadrillas.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              TextField(
                controller: userController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0B7A2F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Validar'),
              onPressed: () async {
                // Primero intentar con el nuevo sistema de base de datos
                var userData = await _authService.validarCredencialesConPermisos(
                  userController.text,
                  passController.text,
                );

                // Si falla, intentar con el sistema anterior como respaldo
                if (userData == null) {
                  try {
                    final resultado = await _controlUsuario.validarCredencialesConTipo(
                      userController.text,
                      passController.text,
                    );
                    
                    // Verificar si es Supervisor (1) o Administrador (2)
                    if (resultado != null && (resultado['rol_id'] == 1 || resultado['rol_id'] == 2)) {
                      userData = {
                        'nombre_usuario': userController.text,
                        'rol_descripcion': resultado['tipo'],
                        'puede_gestionar': true,
                      };
                    }
                  } catch (e) {
                    // Error silencioso
                  }
                }

                if (userData != null) {
                  Navigator.of(context).pop(userData);
                } else {
                  // Mostrar error sin cerrar el diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Credenciales inválidas o sin permisos suficientes\nRevisa la consola para más detalles'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    // Si la autenticación fue exitosa, cambiar el estado
    if (userData != null) {
      final cuadrilla = cuadrillasFiltradas[index];
      final clave = cuadrilla['clave']; // Usar la clave en lugar del ID
      final estadoActual = cuadrilla['habilitado'] ?? true;
      final nuevoEstado = !estadoActual;

      // Actualizar en la base de datos
      final actualizado = await _authService.actualizarEstadoCuadrilla(clave, nuevoEstado);

      if (actualizado) {
        // Recargar datos desde la base de datos para asegurar consistencia
        await cargarCuadrillas();
        
        // Mostrar mensaje de confirmación con información del usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cuadrilla ${nuevoEstado ? "habilitada" : "deshabilitada"} por ${userData['nombre_usuario']} (${userData['rol_descripcion']})',
            ),
            backgroundColor: nuevoEstado ? Colors.green : Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el estado en la base de datos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Limpiar los controladores
    userController.clear();
    passController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 800;
            final cardWidth =
                (isSmallScreen ? constraints.maxWidth * 0.9 : 1400).toDouble();

            return Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Container(
                constraints: BoxConstraints(maxWidth: cardWidth),
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      'Gestión de Cuadrillas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 32),
                    // Formulario para crear cuadrillas
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fila única con todos los campos: Clave, Nombre, Grupo, Actividad
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end, // Alinear en la base
                            children: [
                              // Campo Clave
                              Expanded(
                                flex: 2, // Hacer más ancho el campo de clave
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Clave'),
                                        SizedBox(width: 8),
                                        Text('Personalizada', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                        SizedBox(width: 4),
                                        Transform.scale(
                                          scale: 0.7,
                                          child: Switch.adaptive(
                                            value: _modoClavePersonalizada,
                                            onChanged: (value) {
                                              setState(() {
                                                _modoClavePersonalizada = value;
                                                if (!value && _claveSeleccionada != null) {
                                                  claveController.text = _claveSeleccionada!;
                                                }
                                              });
                                            },
                                            activeColor: Color(0xFF0B7A2F),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 56, // Altura fija para todos los campos
                                      child: _modoClavePersonalizada 
                                        ? TextField(
                                            controller: claveController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Colors.grey[200],
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                            ),
                                          )
                                        : _buildClaveDropdown(Colors.grey[200]!),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Campo Nombre
                              Expanded(
                                flex: 3, // Más espacio para el nombre
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Nombre'),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 56, // Altura fija
                                      child: TextField(
                                        controller: nombreController,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Campo Grupo
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Grupo'),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 56, // Altura fija
                                      child: TextField(
                                        controller: grupoController,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Campo Actividad
                              Expanded(
                                flex: 3, // Más espacio para actividad
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Actividad'),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 56, // Altura fija
                                      child: GestureDetector(
                                        onTap: () async {
                                          final resultado = await showDialog<String>(
                                            context: context,
                                            builder: (context) => SeleccionarActividadModal(
                                              actividadSeleccionada: actividadSeleccionada,
                                            ),
                                          );
                                          
                                          if (resultado != null) {
                                            setState(() {
                                              actividadSeleccionada = resultado;
                                            });
                                          }
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          height: 56, // Altura fija para mantener consistencia
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  actividadSeleccionada ?? 'Seleccionar actividad',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: actividadSeleccionada != null
                                                        ? Colors.black87
                                                        : Colors.grey[600],
                                                  ),
                                                  overflow: TextOverflow.ellipsis, // Evitar desbordamiento
                                                ),
                                              ),
                                              Icon(
                                                Icons.search,
                                                color: Colors.grey[600],
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0B7A2F),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _crearCuadrilla,
                              child: const Text(
                                'Crear',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Catalogo de Cuadrillas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B7A2F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Barra de búsqueda mejorada
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: (value) => _buscarCuadrilla(), // Búsqueda en tiempo real
                              decoration: InputDecoration(
                                hintText: 'Buscar por nombre o clave de cuadrilla...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFF0B7A2F),
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(color: Color(0xFF0B7A2F), width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            child: IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white, size: 20),
                              onPressed: () {
                                searchController.clear();
                                _buscarCuadrilla();
                              },
                              tooltip: 'Limpiar búsqueda',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Indicador de resultados de búsqueda
                    if (searchController.text.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF0B7A2F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF0B7A2F).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF0B7A2F),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              cuadrillasFiltradas.isEmpty 
                                ? 'No se encontraron cuadrillas que coincidan con "${searchController.text}"'
                                : 'Mostrando ${cuadrillasFiltradas.length} de ${cuadrillas.length} cuadrillas',
                              style: TextStyle(
                                color: Color(0xFF0B7A2F),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            if (searchController.text.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  searchController.clear();
                                  _buscarCuadrilla();
                                },
                                icon: Icon(Icons.clear, size: 16, color: Color(0xFF0B7A2F)),
                                label: Text(
                                  'Mostrar todas',
                                  style: TextStyle(color: Color(0xFF0B7A2F), fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size(0, 0),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Tabla de cuadrillas
                    Card(
                      color: Colors.white,
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 350, // Altura máxima visible de la tabla
                          child: Scrollbar(
                            controller: _tableScrollController,
                            thumbVisibility: true,
                            child: ListView(
                              controller: _tableScrollController,
                              children: [
                                DataTable(
  headingRowColor: MaterialStateProperty.all(
    Color(0xFFE0E0E0),
  ),
  dataRowColor: MaterialStateProperty.resolveWith<Color?>(
    (Set<MaterialState> states) {
      final rowIndex = states.contains(MaterialState.selected)
          ? states.toList().indexOf(MaterialState.selected)
          : -1;
      if (rowIndex != -1 && rowIndex < cuadrillasFiltradas.length) {
        final habilitado = cuadrillasFiltradas[rowIndex]['habilitado'] ?? true;
        return !habilitado ? Colors.grey[100] : null;
      }
      return null;
    },
  ),
  border: TableBorder.all(
    color: Colors.grey.shade400,
    width: 1,
    style: BorderStyle.solid,
  ),
  columns: const [
    DataColumn(label: Text('Clave', style: TextStyle(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Grupo', style: TextStyle(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Actividad', style: TextStyle(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
  ],
  rows: cuadrillasFiltradas.asMap().entries.map((entry) {
    final index = entry.key;
    final cuadrilla = entry.value;
    final habilitado = cuadrilla['habilitado'] ?? true;

    return DataRow(
      cells: [
        DataCell(
          Text(
            cuadrilla['clave'], // Mostramos la clave auto-generada
            style: TextStyle(color: !habilitado ? Colors.grey[600] : null),
          ),
        ),
        DataCell(
          Text(
            cuadrilla['nombre'],
            style: TextStyle(color: !habilitado ? Colors.grey[600] : null),
          ),
        ),
        DataCell(
          Text(
            cuadrilla['grupo'],
            style: TextStyle(color: !habilitado ? Colors.grey[600] : null),
          ),
        ),
        DataCell(
          Text(
            cuadrilla['actividad'],
            style: TextStyle(color: !habilitado ? Colors.grey[600] : null),
          ),
        ),
        DataCell(
          Container(
            width: 120,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: habilitado
                    ? Color(0xFF0B7A2F) // verde para habilitado
                    : Color(0xFFE53935), // rojo para deshabilitado
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _toggleHabilitado(index),
              child: Text(
                habilitado ? 'Sí' : 'No',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }).toList(),
),
                              ],
                            ),
                          ),
                        ),
                      ),
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
}

