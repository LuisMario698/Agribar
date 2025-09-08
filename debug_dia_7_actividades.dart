import 'package:agribar/services/database_service.dart';

/// Script para analizar por qué se están enviando datos null para actividades y día 7
/// 
/// PROBLEMA IDENTIFICADO:
/// 1. En la interfaz (tabla) se manejan campos dia_0_s hasta dia_6_s (7 días en total)
/// 2. En la BD se guardan como dia_1 hasta dia_7 (también 7 días)
/// 3. El mapeo es: dia_6_s (último día en interfaz) → dia_7 (último día en BD)
/// 4. Pero hay un problema en el manejo de valores null/vacíos

void main() async {
  final db = DatabaseService();
  
  try {
    await db.connect();
    print('🔍🔍🔍 ANÁLISIS COMPLETO: DÍA 7 Y ACTIVIDADES NULL 🔍🔍🔍\n');
    
    // 1. ANALIZAR ESTRUCTURA DE LA TABLA
    await analizarEstructuraTabla(db);
    
    // 2. ANALIZAR DATOS REALES EN BD
    await analizarDatosReales(db);
    
    // 3. ANALIZAR MAPEO DE DATOS
    await analizarMapeoInterface(db);
    
    // 4. PROBAR CONVERSIONES DE DATOS
    await probarConversiones(db);
    
    // 5. VERIFICAR TABLAS DE ACTIVIDADES Y CAMPOS
    await verificarTablasReferencia(db);
    
    print('\n' + '='*80);
    print('🎯 RESUMEN DE PROBLEMAS ENCONTRADOS');
    print('='*80);
    
    await generarRecomendaciones(db);
    
  } catch (e) {
    print('❌ Error en análisis: $e');
  } finally {
    await db.close();
  }
}

/// Analiza la estructura de la tabla nomina_empleados_semanal
Future<void> analizarEstructuraTabla(DatabaseService db) async {
  print('1️⃣ ANÁLISIS DE ESTRUCTURA DE TABLA');
  print('-' * 50);
  
  try {
    // Obtener columnas relacionadas con días y actividades
    final columnas = await db.connection.query('''
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal'
      AND (column_name LIKE 'dia_%' OR column_name LIKE 'act_%' OR column_name LIKE 'campo_%')
      ORDER BY column_name;
    ''');
    
    print('📋 Columnas relacionadas con días/actividades/campos:');
    for (var col in columnas) {
      print('  • ${col[0]} - Tipo: ${col[1]} - Nullable: ${col[2]} - Default: ${col[3]}');
    }
    
    // Verificar si existen las 7 columnas de cada tipo
    final diasColumns = columnas.where((c) => (c[0] as String).startsWith('dia_')).length;
    final actColumns = columnas.where((c) => (c[0] as String).startsWith('act_')).length;
    final campoColumns = columnas.where((c) => (c[0] as String).startsWith('campo_')).length;
    
    print('\n📊 Conteo de columnas:');
    print('  • Días: $diasColumns (esperadas: 7)');
    print('  • Actividades: $actColumns (esperadas: 7)');
    print('  • Campos: $campoColumns (esperadas: 7)');
    
  } catch (e) {
    print('❌ Error analizando estructura: $e');
  }
  print('');
}

/// Analiza datos reales en la base de datos
Future<void> analizarDatosReales(DatabaseService db) async {
  print('2️⃣ ANÁLISIS DE DATOS REALES');
  print('-' * 50);
  
  try {
    // Obtener la semana más reciente
    final semanaReciente = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin 
      FROM semanas_nomina 
      ORDER BY id_semana DESC 
      LIMIT 1;
    ''');
    
    if (semanaReciente.isEmpty) {
      print('❌ No hay semanas registradas');
      return;
    }
    
    final semanaId = semanaReciente.first[0];
    print('🗓️ Analizando semana ID: $semanaId');
    print('   Fechas: ${semanaReciente.first[1]} - ${semanaReciente.first[2]}');
    
    // Obtener algunos registros de ejemplo
    final ejemplos = await db.connection.query('''
      SELECT 
        id_empleado,
        dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7,
        act_1, act_2, act_3, act_4, act_5, act_6, act_7,
        campo_1, campo_2, campo_3, campo_4, campo_5, campo_6, campo_7
      FROM nomina_empleados_semanal 
      WHERE id_semana = $semanaId
      LIMIT 5;
    ''');
    
    print('\n📈 Ejemplos de datos (primeros 5 empleados):');
    
    for (int i = 0; i < ejemplos.length; i++) {
      final row = ejemplos[i];
      print('  👤 Empleado ${row[0]}:');
      
      // Analizar días
      print('    📅 Días:');
      for (int d = 1; d <= 7; d++) {
        final valor = row[d];
        final status = valor == null ? '❌ NULL' : (valor == 0 ? '⚠️  CERO' : '✅ ${valor}');
        print('      dia_$d: $status');
      }
      
      // Analizar actividades
      print('    🎯 Actividades:');
      for (int a = 1; a <= 7; a++) {
        final valor = row[a + 7]; // act_1 está en posición 8 (índice 7)
        final status = valor == null ? '❌ NULL' : (valor == 0 ? '⚠️  CERO' : '✅ ${valor}');
        print('      act_$a: $status');
      }
      
      // Analizar campos
      print('    🏗️  Campos:');
      for (int c = 1; c <= 7; c++) {
        final valor = row[c + 14]; // campo_1 está en posición 15 (índice 14)
        final status = valor == null ? '❌ NULL' : (valor.toString().isEmpty ? '⚠️  VACÍO' : '✅ ${valor}');
        print('      campo_$c: $status');
      }
      print('');
    }
    
    // Estadísticas generales
    print('📊 ESTADÍSTICAS GENERALES:');
    for (int d = 1; d <= 7; d++) {
      final stats = await db.connection.query('''
        SELECT 
          COUNT(*) as total,
          COUNT(dia_$d) as no_null,
          COUNT(CASE WHEN dia_$d > 0 THEN 1 END) as con_valor,
          COUNT(act_$d) as act_no_null,
          COUNT(CASE WHEN act_$d > 0 THEN 1 END) as act_con_valor,
          COUNT(campo_$d) as campo_no_null,
          COUNT(CASE WHEN campo_$d IS NOT NULL AND campo_$d <> '' THEN 1 END) as campo_con_valor
        FROM nomina_empleados_semanal 
        WHERE id_semana = $semanaId;
      ''');
      
      if (stats.isNotEmpty) {
        final s = stats.first;
        print('  día_$d: Total=${s[0]}, Días_no_null=${s[1]}, Días_con_valor=${s[2]}, ' +
              'Act_no_null=${s[3]}, Act_con_valor=${s[4]}, Campo_no_null=${s[5]}, Campo_con_valor=${s[6]}');
      }
    }
    
  } catch (e) {
    print('❌ Error analizando datos reales: $e');
  }
  print('');
}

/// Analiza el mapeo entre interfaz y base de datos
Future<void> analizarMapeoInterface(DatabaseService db) async {
  print('3️⃣ ANÁLISIS DEL MAPEO INTERFAZ ↔ BASE DE DATOS');
  print('-' * 50);
  
  print('📋 MAPEO ACTUAL (según código):');
  print('   INTERFAZ → BASE DE DATOS');
  print('   dia_0_s  → dia_1   (día 1)');
  print('   dia_1_s  → dia_2   (día 2)');
  print('   dia_2_s  → dia_3   (día 3)');
  print('   dia_3_s  → dia_4   (día 4)');
  print('   dia_4_s  → dia_5   (día 5)');
  print('   dia_5_s  → dia_6   (día 6)');
  print('   dia_6_s  → dia_7   (día 7) ← ESTE ES EL PROBLEMA');
  print('');
  
  print('🎯 MAPEO DE ACTIVIDADES:');
  print('   INTERFAZ → BASE DE DATOS');
  print('   dia_0_id → act_1   (actividad día 1)');
  print('   dia_1_id → act_2   (actividad día 2)');
  print('   dia_2_id → act_3   (actividad día 3)');
  print('   dia_3_id → act_4   (actividad día 4)');
  print('   dia_4_id → act_5   (actividad día 5)');
  print('   dia_5_id → act_6   (actividad día 6)');
  print('   dia_6_id → act_7   (actividad día 7) ← ESTE ES EL PROBLEMA');
  print('');
  
  print('🏗️  MAPEO DE CAMPOS/RANCHOS:');
  print('   INTERFAZ    → BASE DE DATOS');
  print('   dia_0_campo → campo_1   (campo día 1)');
  print('   dia_1_campo → campo_2   (campo día 2)');
  print('   dia_2_campo → campo_3   (campo día 3)');
  print('   dia_3_campo → campo_4   (campo día 4)');
  print('   dia_4_campo → campo_5   (campo día 5)');
  print('   dia_5_campo → campo_6   (campo día 6)');
  print('   dia_6_campo → campo_7   (campo día 7) ← ESTE ES EL PROBLEMA');
  print('');
}

/// Prueba las conversiones de datos
Future<void> probarConversiones(DatabaseService db) async {
  print('4️⃣ PRUEBAS DE CONVERSIÓN DE DATOS');
  print('-' * 50);
  
  // Simular datos como vienen de la interfaz
  final datosInterfaz = {
    'dia_6_s': null,      // Día 7 sin valor
    'dia_6_id': '',       // Actividad día 7 vacía
    'dia_6_campo': null,  // Campo día 7 null
  };
  
  print('🧪 SIMULANDO DATOS DE LA INTERFAZ:');
  print('   dia_6_s: ${datosInterfaz['dia_6_s']} (${datosInterfaz['dia_6_s'].runtimeType})');
  print('   dia_6_id: "${datosInterfaz['dia_6_id']}" (${datosInterfaz['dia_6_id'].runtimeType})');
  print('   dia_6_campo: ${datosInterfaz['dia_6_campo']} (${datosInterfaz['dia_6_campo'].runtimeType})');
  print('');
  
  print('🔄 APLICANDO FUNCIONES DE CONVERSIÓN:');
  
  // Simular las funciones _getSafeIntValue y _getSafeStringValue
  print('   _getSafeIntValue(dia_6_s):');
  final dia7_valor = _getSafeIntValue(datosInterfaz['dia_6_s']);
  print('     Resultado: $dia7_valor (${dia7_valor.runtimeType})');
  
  print('   _getSafeIntValue(dia_6_id):');
  final act7_valor = _getSafeIntValue(datosInterfaz['dia_6_id']);
  print('     Resultado: $act7_valor (${act7_valor.runtimeType})');
  
  print('   _getSafeStringValue(dia_6_campo):');
  final campo7_valor = _getSafeStringValue(datosInterfaz['dia_6_campo']);
  print('     Resultado: "$campo7_valor" (${campo7_valor.runtimeType})');
  print('');
  
  print('💾 DATOS QUE SE ENVIARÍAN A LA BD:');
  print('   dia_7: $dia7_valor');
  print('   act_7: $act7_valor');
  print('   campo_7: "$campo7_valor"');
  print('');
  
  print('⚠️  PROBLEMAS IDENTIFICADOS:');
  if (act7_valor == 0) {
    print('   ❌ act_7 se está enviando como 0 en lugar de NULL');
  }
  if (campo7_valor == '') {
    print('   ❌ campo_7 se está enviando como string vacío en lugar de NULL');
  }
}

/// Verifica las tablas de referencia (actividades y ranchos)
Future<void> verificarTablasReferencia(DatabaseService db) async {
  print('5️⃣ VERIFICACIÓN DE TABLAS DE REFERENCIA');
  print('-' * 50);
  
  try {
    // Verificar tabla actividades
    final actividades = await db.connection.query('''
      SELECT COUNT(*) as total, 
             COUNT(CASE WHEN nombre IS NOT NULL AND nombre <> '' THEN 1 END) as con_nombre
      FROM actividades;
    ''');
    
    print('🎯 TABLA ACTIVIDADES:');
    if (actividades.isNotEmpty) {
      print('   Total: ${actividades.first[0]}');
      print('   Con nombre: ${actividades.first[1]}');
    }
    
    // Mostrar algunas actividades de ejemplo
    final actEjemplos = await db.connection.query('''
      SELECT id_actividad, nombre, clave 
      FROM actividades 
      WHERE nombre IS NOT NULL AND nombre <> ''
      ORDER BY id_actividad 
      LIMIT 5;
    ''');
    
    print('   Ejemplos:');
    for (var act in actEjemplos) {
      print('     • ID: ${act[0]}, Nombre: "${act[1]}", Clave: "${act[2]}"');
    }
    
    // Verificar tabla ranchos
    final ranchos = await db.connection.query('''
      SELECT COUNT(*) as total
      FROM ranchos;
    ''');
    
    print('\n🏗️  TABLA RANCHOS:');
    if (ranchos.isNotEmpty) {
      print('   Total: ${ranchos.first[0]}');
    }
    
    // Mostrar algunos ranchos de ejemplo
    final rancEjemplos = await db.connection.query('''
      SELECT id_rancho, nombre, clave 
      FROM ranchos 
      ORDER BY id_rancho 
      LIMIT 5;
    ''');
    
    print('   Ejemplos:');
    for (var rancho in rancEjemplos) {
      print('     • ID: ${rancho[0]}, Nombre: "${rancho[1]}", Clave: "${rancho[2] ?? 'Sin clave'}"');
    }
    
  } catch (e) {
    print('❌ Error verificando tablas de referencia: $e');
  }
  print('');
}

/// Genera recomendaciones para solucionar los problemas
Future<void> generarRecomendaciones(DatabaseService db) async {
  print('💡 RECOMENDACIONES PARA SOLUCIONAR LOS PROBLEMAS:');
  print('');
  
  print('1. 🔧 PROBLEMA EN FUNCIONES DE CONVERSIÓN:');
  print('   • _getSafeIntValue() debería retornar NULL para strings vacíos');
  print('   • _getSafeStringValue() debería retornar NULL para valores null');
  print('   • Actualmente se envían 0 y "" que se interpretan como datos válidos');
  print('');
  
  print('2. 🎯 PROBLEMA EN MANEJO DE ACTIVIDADES:');
  print('   • Cuando no se selecciona actividad, se envía "0" o ""');
  print('   • La BD debería recibir NULL para indicar "sin actividad"');
  print('   • Verificar que los IDs de actividad en la interfaz coincidan con la BD');
  print('');
  
  print('3. 🏗️  PROBLEMA EN MANEJO DE CAMPOS/RANCHOS:');
  print('   • Los campos vacíos se envían como string vacío ""');
  print('   • Deberían enviarse como NULL en la BD');
  print('   • Verificar que los IDs de rancho en la interfaz coincidan con la BD');
  print('');
  
  print('4. 📅 PROBLEMA ESPECÍFICO DEL DÍA 7:');
  print('   • El día 7 (día_6_s → dia_7) puede tener problemas de mapeo');
  print('   • Verificar que los datos del día 7 se estén guardando correctamente');
  print('   • El día 7 es el más afectado por ser el último en el mapeo');
  print('');
  
  print('5. 🔍 SOLUCIONES PROPUESTAS:');
  print('   a) Modificar _getSafeIntValue() para manejar mejor los nulos:');
  print('      - Si el valor es null, "", "0" → retornar null');
  print('      - Solo retornar entero si hay un valor real > 0');
  print('');
  print('   b) Modificar _getSafeStringValue() para manejar mejor los nulos:');
  print('      - Si el valor es null o "" → retornar null');
  print('      - Solo retornar string si hay contenido real');
  print('');
  print('   c) Agregar validación en la interfaz:');
  print('      - Verificar que los IDs de actividad existen en la BD');
  print('      - Verificar que los IDs de rancho existen en la BD');
  print('      - Mostrar mensajes de error si hay problemas de referencia');
  print('');
  print('   d) Mejorar el debug en tiempo real:');
  print('      - Agregar logs más detallados al guardar datos');
  print('      - Mostrar qué valores se están enviando exactamente');
  print('      - Validar datos antes de enviar a la BD');
}

/// Función simulada _getSafeIntValue (copiada del código original)
int? _getSafeIntValue(dynamic value) {
  if (value == null) return null;
  if (value is int) return value == 0 ? null : value;
  if (value is double) return value == 0.0 ? null : value.toInt();
  if (value is String) {
    if (value.trim().isEmpty || value == '0') return null;
    final parsed = int.tryParse(value);
    return parsed == 0 ? null : parsed;
  }
  if (value is bool) return value ? 1 : null;
  return null;
}

/// Función simulada _getSafeStringValue (copiada del código original)
String? _getSafeStringValue(dynamic value) {
  if (value == null) return null;
  final stringValue = value.toString().trim();
  return stringValue.isEmpty ? null : stringValue;
}
