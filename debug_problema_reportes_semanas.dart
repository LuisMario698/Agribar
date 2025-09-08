import 'lib/services/database_service.dart';

Future<void> main() async {
  print('🔍 ANÁLISIS: ¿Por qué no aparecen semanas en reportes?');
  print('=====================================================');
  
  try {
    final db = DatabaseService();
    await db.connect();

    // 1. Verificar todas las semanas y su estado
    print('\n1️⃣ ESTADO DE TODAS LAS SEMANAS...');
    
    final todasLasSemanas = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada, autorizado_por, cerrada
      FROM semanas_nomina 
      ORDER BY id_semana DESC;
    ''');
    
    print('📋 Todas las semanas en semanas_nomina:');
    for (var sem in todasLasSemanas) {
      print('  • Semana ${sem[0]}: ${sem[1]} a ${sem[2]}');
      print('    esta_cerrada: ${sem[3]} | cerrada: ${sem[5]} | autorizado_por: ${sem[4]}');
    }

    // 2. Verificar datos en historial para cada semana
    print('\n2️⃣ DATOS EN HISTORIAL POR SEMANA...');
    
    for (var sem in todasLasSemanas) {
      var idSemana = sem[0];
      final datosHistorial = await db.connection.query('''
        SELECT COUNT(*) as registros,
               COUNT(CASE WHEN act_1 IS NOT NULL AND act_1 <> 0 THEN 1 END) as con_actividades
        FROM nomina_empleados_historial 
        WHERE id_semana = @idSemana
      ''', substitutionValues: {'idSemana': idSemana});
      
      if (datosHistorial.isNotEmpty) {
        var reg = datosHistorial.first[0];
        var act = datosHistorial.first[1];
        print('  • Semana $idSemana: $reg registros en historial, $act con actividades');
      }
    }

    // 3. Probar la consulta exacta que usa obtenerSemanasDisponibles()
    print('\n3️⃣ SIMULANDO CONSULTA DE obtenerSemanasDisponibles()...');
    
    final semanasDisponibles = await db.connection.query('''
      SELECT DISTINCT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada,
        s.autorizado_por,
        s.fecha_autorizacion
      FROM semanas_nomina s
      INNER JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      WHERE s.esta_cerrada = true
      ORDER BY s.fecha_inicio DESC
    ''');
    
    print('🎯 Semanas que aparecerían en el dropdown de reportes:');
    if (semanasDisponibles.isEmpty) {
      print('  ❌ ¡NINGUNA SEMANA CUMPLE LOS CRITERIOS!');
      print('');
      print('🔍 CRITERIOS QUE DEBEN CUMPLIRSE:');
      print('  1. esta_cerrada = true');
      print('  2. Tener registros en nomina_empleados_historial');
      
      // Verificar qué semanas cumplen cada criterio por separado
      print('\n🔍 ANÁLISIS DETALLADO:');
      
      final semanasCerradas = await db.connection.query('''
        SELECT id_semana, esta_cerrada, cerrada FROM semanas_nomina WHERE esta_cerrada = true
      ''');
      print('  • Semanas con esta_cerrada = true: ${semanasCerradas.length}');
      for (var sc in semanasCerradas) {
        print('    - Semana ${sc[0]}: esta_cerrada=${sc[1]}, cerrada=${sc[2]}');
      }
      
      final semanasConHistorial = await db.connection.query('''
        SELECT DISTINCT id_semana FROM nomina_empleados_historial
      ''');
      print('  • Semanas con datos en historial: ${semanasConHistorial.length}');
      for (var sh in semanasConHistorial) {
        print('    - Semana ${sh[0]}');
      }
      
    } else {
      for (var sem in semanasDisponibles) {
        print('  ✅ Semana ${sem[0]}: ${sem[1]} a ${sem[2]} | Auth: ${sem[4]}');
      }
    }

    // 4. Sugerir corrección
    print('\n4️⃣ DIAGNÓSTICO Y SOLUCIÓN...');
    
    // Verificar si hay semanas que deberían estar cerradas
    final semanasParaCerrar = await db.connection.query('''
      SELECT s.id_semana, s.fecha_inicio, s.fecha_fin, s.esta_cerrada, s.cerrada,
             COUNT(n.id_empleado) as registros_historial
      FROM semanas_nomina s
      LEFT JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      GROUP BY s.id_semana, s.fecha_inicio, s.fecha_fin, s.esta_cerrada, s.cerrada
      HAVING COUNT(n.id_empleado) > 0
    ''');
    
    print('💡 SEMANAS CON DATOS EN HISTORIAL QUE DEBERÍAN APARECER EN REPORTES:');
    for (var sem in semanasParaCerrar) {
      var idSem = sem[0];
      var estaCerrada = sem[3];
      var cerrada = sem[4];
      var registros = sem[5];
      
      if (!estaCerrada) {
        print('  ⚠️  Semana $idSem: NO cerrada (esta_cerrada=$estaCerrada, cerrada=$cerrada) pero tiene $registros registros en historial');
        print('      🔧 SOLUCIÓN: Actualizar esta_cerrada = true para semana $idSem');
      } else {
        print('  ✅ Semana $idSem: Correctamente cerrada y con $registros registros');
      }
    }

    // 5. Generar script de corrección si es necesario
    final semanasIncorrectas = await db.connection.query('''
      SELECT s.id_semana
      FROM semanas_nomina s
      INNER JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      WHERE s.esta_cerrada = false
      GROUP BY s.id_semana
    ''');
    
    if (semanasIncorrectas.isNotEmpty) {
      print('\n🔧 SCRIPT DE CORRECCIÓN SUGERIDO:');
      print('UPDATE semanas_nomina SET esta_cerrada = true WHERE id_semana IN (');
      for (int i = 0; i < semanasIncorrectas.length; i++) {
        print('  ${semanasIncorrectas[i][0]}${i < semanasIncorrectas.length - 1 ? ',' : ''}');
      }
      print(');');
    }

    await db.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
