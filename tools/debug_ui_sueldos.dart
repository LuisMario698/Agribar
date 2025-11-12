import 'package:postgres/postgres.dart';

Future<void> main() async {
  print('=== DEBUG UI SUELDOS - ANÁLISIS DE VALORES EN WIDGETS ===\n');
  
  // Configuración de conexión a PostgreSQL
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'agribar_bd',
    username: 'postgres',
    password: 'Contrasena123',
  );

  try {
    await connection.open();
    print('✅ Conexión a PostgreSQL establecida\n');

    // 1. Obtener datos reales de una cuadrilla específica
    print('--- 1. DATOS REALES DE LA BD ---');
    final resultados = await connection.query('''
      SELECT 
        ne.id_empleado,
        e.nombre_empleado,
        ne.dia_1_s,
        ne.dia_2_s,
        ne.dia_3_s,
        ne.id_actividad_dia_1,
        ne.id_actividad_dia_2,
        ne.id_actividad_dia_3
      FROM nomina_empleados_semanal ne
      INNER JOIN empleados e ON ne.id_empleado = e.id
      WHERE ne.id_cuadrilla = 1 
        AND ne.anio = 2024 
        AND ne.numero_semana = 46
      ORDER BY e.nombre_empleado
      LIMIT 5
    ''');

    for (final row in resultados) {
      print('Empleado: ${row[1]}');
      print('  dia_1_s: "${row[2]}" (tipo: ${row[2].runtimeType})');
      print('  dia_2_s: "${row[3]}" (tipo: ${row[3].runtimeType})');
      print('  dia_3_s: "${row[4]}" (tipo: ${row[4].runtimeType})');
      print('  id_actividad_dia_1: "${row[5]}" (tipo: ${row[5].runtimeType})');
      print('  ---');
    }

    // 2. Simular el procesamiento que hace obtenerNominaEmpleadosDeCuadrilla
    print('\n--- 2. SIMULACIÓN DE PROCESAMIENTO DE DATOS ---');
    
    if (resultados.isNotEmpty) {
      final row = resultados.first;
      final empleado = <String, dynamic>{};
      
      // Simulamos el mapeo que hace obtenerNominaEmpleadosDeCuadrilla
      empleado['nombre'] = row[1];
      empleado['dia_1_s'] = row[2];
      empleado['dia_2_s'] = row[3];
      empleado['dia_3_s'] = row[4];
      
      print('Empleado mapeado:');
      print('  nombre: "${empleado['nombre']}"');
      print('  dia_1_s: "${empleado['dia_1_s']}" (tipo: ${empleado['dia_1_s'].runtimeType})');
      print('  dia_2_s: "${empleado['dia_2_s']}" (tipo: ${empleado['dia_2_s'].runtimeType})');
      print('  dia_3_s: "${empleado['dia_3_s']}" (tipo: ${empleado['dia_3_s'].runtimeType})');

      // 3. Simular el procesamiento de _construirWidgetEditable
      print('\n--- 3. SIMULACIÓN DE _construirWidgetEditable ---');
      
      for (int dia = 1; dia <= 3; dia++) {
        final campo = 'dia_${dia}_s';
        final valor = empleado[campo];
        final esCampoTexto = false; // Los sueldos no son campos de texto
        
        print('\nCampo: $campo');
        print('  valor original: "$valor" (tipo: ${valor.runtimeType})');
        
        // Esta es la línea problemática de _construirWidgetEditable:
        final valorMostrar = esCampoTexto 
          ? _formatearIdOCampo(valor) 
          : ((valor?.toString() ?? '') == '0' ? '' : valor?.toString() ?? '');
          
        print('  valor.toString(): "${valor?.toString()}"');
        print('  (valor?.toString() ?? \'\') == \'0\': ${(valor?.toString() ?? '') == '0'}');
        print('  valorMostrar final: "$valorMostrar"');
        
        // Verificar si está convirtiendo valores válidos a cadena vacía
        if (valorMostrar == '' && valor != null && valor.toString() != '0') {
          print('  ⚠️  PROBLEMA: Valor válido convertido a cadena vacía!');
        } else if (valorMostrar != '' && valor != null) {
          print('  ✅ Valor procesado correctamente');
        }
      }
    }

  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await connection.close();
    print('\n🔒 Conexión cerrada');
  }
}

// Función auxiliar para simular _formatearIdOCampo
String _formatearIdOCampo(dynamic valor) {
  if (valor == null) return '';
  final str = valor.toString();
  if (str == '0' || str == '0.0' || str == '0.00') return '';
  return str;
}