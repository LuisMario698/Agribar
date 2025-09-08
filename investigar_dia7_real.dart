import 'package:agribar/services/database_service.dart';

/// Script para investigar el problema real con día 7 y actividades
void main() async {
  final db = DatabaseService();
  
  try {
    await db.connect();
    print('🔍 INVESTIGANDO PROBLEMA REAL: DÍA 7 Y ACTIVIDADES');
    print('=' * 60);
    
    // 1. Verificar estructura de tabla
    await verificarEstructura(db);
    
    // 2. Analizar datos actuales
    await analizarDatosActuales(db);
    
    // 3. Verificar el mapeo de la interfaz
    await verificarMapeoInterfaz();
    
    // 4. Verificar tablas de referencia
    await verificarReferencias(db);
    
  } catch (e) {
    print('❌ Error en análisis: $e');
  } finally {
    await db.close();
  }
}

Future<void> verificarEstructura(DatabaseService db) async {
  print('1️⃣ VERIFICANDO ESTRUCTURA DE TABLA');
  print('-' * 40);
  
  final columnas = await db.connection.query('''
    SELECT column_name, data_type, is_nullable 
    FROM information_schema.columns 
    WHERE table_name = 'nomina_empleados_semanal'
    AND (column_name LIKE 'dia_%' OR column_name LIKE 'act_%' OR column_name LIKE 'campo_%')
    ORDER BY column_name;
  ''');
  
  print('Columnas encontradas:');
  for (var col in columnas) {
    print('  ${col[0]} - ${col[1]} - Nullable: ${col[2]}');
  }
  print('');
}

Future<void> analizarDatosActuales(DatabaseService db) async {
  print('2️⃣ ANALIZANDO DATOS ACTUALES');
  print('-' * 40);
  
  // Buscar la semana más reciente
  final semanas = await db.connection.query('''
    SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada
    FROM semanas_nomina 
    ORDER BY id_semana DESC 
    LIMIT 3;
  ''');
  
  print('Semanas recientes:');
  for (var semana in semanas) {
    print('  ID: ${semana[0]} - ${semana[1]} a ${semana[2]} - Cerrada: ${semana[3]}');
  }
  
  if (semanas.isNotEmpty) {
    final semanaId = semanas.first[0];
    print('\n📊 Analizando semana $semanaId:');
    
    // Contar datos por día y actividad
    for (int dia = 1; dia <= 7; dia++) {
      final stats = await db.connection.query('''
        SELECT 
          COUNT(*) as total_registros,
          COUNT(CASE WHEN dia_$dia IS NOT NULL AND dia_$dia > 0 THEN 1 END) as con_pago,
          COUNT(CASE WHEN act_$dia IS NOT NULL AND act_$dia > 0 THEN 1 END) as con_actividad,
          COUNT(CASE WHEN campo_$dia IS NOT NULL AND campo_$dia <> '' THEN 1 END) as con_campo,
          AVG(CASE WHEN dia_$dia > 0 THEN dia_$dia END) as pago_promedio
        FROM nomina_empleados_semanal 
        WHERE id_semana = $semanaId;
      ''');
      
      if (stats.isNotEmpty) {
        final s = stats.first;
        print('  Día $dia: ${s[1]}/${s[0]} con pago, ${s[2]}/${s[0]} con actividad, ${s[3]}/${s[0]} con campo, promedio: \$${s[4] ?? 0}');
      }
    }
    
    // Buscar registros específicos problemáticos
    print('\n🔍 Registros con problemas en día 7:');
    final problemas = await db.connection.query('''
      SELECT id_empleado, dia_7, act_7, campo_7
      FROM nomina_empleados_semanal 
      WHERE id_semana = $semanaId
      AND (dia_7 IS NULL OR act_7 IS NULL OR act_7 = 0)
      LIMIT 5;
    ''');
    
    for (var p in problemas) {
      print('  Empleado ${p[0]}: dia_7=${p[1]}, act_7=${p[2]}, campo_7="${p[3]}"');
    }
  }
  print('');
}

Future<void> verificarMapeoInterfaz() async {
  print('3️⃣ VERIFICANDO MAPEO INTERFAZ → BD');
  print('-' * 40);
  
  print('El mapeo actual debería ser:');
  print('INTERFAZ (tabla) → BASE DE DATOS');
  print('dia_0_s         → dia_1');
  print('dia_0_id        → act_1');
  print('dia_0_campo     → campo_1');
  print('...');
  print('dia_6_s         → dia_7  ← ESTE ES EL DÍA 7');
  print('dia_6_id        → act_7  ← ACTIVIDAD DÍA 7');
  print('dia_6_campo     → campo_7 ← CAMPO DÍA 7');
  print('');
  
  print('⚠️  POSIBLES PROBLEMAS:');
  print('1. Los campos dia_6_s, dia_6_id, dia_6_campo pueden estar vacíos en la interfaz');
  print('2. El widget tabla puede no estar generando 7 días correctamente');
  print('3. Los dropdowns de actividad/campo pueden no funcionar en el día 7');
  print('4. Los datos pueden no persistirse correctamente al guardar');
  print('');
}

Future<void> verificarReferencias(DatabaseService db) async {
  print('4️⃣ VERIFICANDO TABLAS DE REFERENCIA');
  print('-' * 40);
  
  // Verificar actividades
  final actividades = await db.connection.query('''
    SELECT COUNT(*) as total, 
           MIN(id_actividad) as min_id, 
           MAX(id_actividad) as max_id
    FROM actividades;
  ''');
  
  if (actividades.isNotEmpty) {
    final a = actividades.first;
    print('📋 Actividades: ${a[0]} total, IDs desde ${a[1]} hasta ${a[2]}');
  }
  
  // Mostrar algunas actividades
  final actEjemplos = await db.connection.query('''
    SELECT id_actividad, nombre, clave 
    FROM actividades 
    ORDER BY id_actividad 
    LIMIT 5;
  ''');
  
  print('Ejemplos de actividades:');
  for (var act in actEjemplos) {
    print('  ID: ${act[0]} - "${act[1]}" (${act[2]})');
  }
  
  // Verificar ranchos/campos
  final ranchos = await db.connection.query('''
    SELECT COUNT(*) as total, 
           MIN(id_rancho) as min_id, 
           MAX(id_rancho) as max_id
    FROM ranchos;
  ''');
  
  if (ranchos.isNotEmpty) {
    final r = ranchos.first;
    print('\n🏗️  Ranchos: ${r[0]} total, IDs desde ${r[1]} hasta ${r[2]}');
  }
  
  // Mostrar algunos ranchos
  final rancEjemplos = await db.connection.query('''
    SELECT id_rancho, nombre, clave 
    FROM ranchos 
    ORDER BY id_rancho 
    LIMIT 5;
  ''');
  
  print('Ejemplos de ranchos:');
  for (var rancho in rancEjemplos) {
    print('  ID: ${rancho[0]} - "${rancho[1]}" (${rancho[2] ?? 'sin clave'})');
  }
  
  print('');
  print('🎯 RECOMENDACIONES:');
  print('1. Verificar que la interfaz genere correctamente 7 columnas de días');
  print('2. Verificar que los dropdowns de actividad y campo funcionen en todas las columnas');
  print('3. Agregar logs detallados al guardar datos para ver qué se está enviando');
  print('4. Verificar que los IDs de actividades y ranchos existan antes de guardar');
  print('5. Probar específicamente capturando datos en el día 7 de la interfaz');
}
