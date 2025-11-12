import 'lib/services/database_service.dart';

void main() async {
  print('🔍 VERIFICANDO TABLAS DEL HISTORIAL\n');

  final db = DatabaseService();
  
  try {
    await db.connect();
    
    // 1. Verificar semanas cerradas
    print('1. 📅 SEMANAS CERRADAS EN BD:');
    print('=' * 50);
    final semanasCerradas = await db.connection.query('''
      SELECT 
        id_semana,
        fecha_inicio,
        fecha_fin,
        esta_cerrada,
        creado_en
      FROM semanas_nomina
      WHERE esta_cerrada = true
      ORDER BY fecha_inicio DESC;
    ''');
    
    if (semanasCerradas.isEmpty) {
      print('❌ NO hay semanas marcadas como cerradas (esta_cerrada = true)');
    } else {
      print('✅ Encontradas ${semanasCerradas.length} semanas cerradas:');
      for (var semana in semanasCerradas) {
        print('   • ID: ${semana[0]}, Inicio: ${semana[1]}, Fin: ${semana[2]}, Creada: ${semana[4]}');
      }
    }
    
    print('\n2. 💰 DATOS DE NÓMINA PARA SEMANAS CERRADAS:');
    print('=' * 50);
    
    for (var semana in semanasCerradas) {
      final semanaId = semana[0];
      print('\n🔍 Verificando semana ID: $semanaId');
      
      // Contar registros en nomina_empleados_semanal
      final conteoNomina = await db.connection.query('''
        SELECT 
          COUNT(*) as total_empleados,
          COUNT(DISTINCT id_cuadrilla) as total_cuadrillas,
          SUM(total_neto) as total_dinero
        FROM nomina_empleados_semanal
        WHERE id_semana = @semanaId;
      ''', substitutionValues: {'semanaId': semanaId});
      
      if (conteoNomina.isNotEmpty) {
        final totalEmpleados = conteoNomina.first[0] ?? 0;
        final totalCuadrillas = conteoNomina.first[1] ?? 0;  
        final totalDinero = conteoNomina.first[2] ?? 0.0;
        
        print('   📊 Empleados: $totalEmpleados');
        print('   📊 Cuadrillas: $totalCuadrillas');
        print('   📊 Total dinero: \$${totalDinero}');
        
        if (totalEmpleados == 0) {
          print('   ❌ PROBLEMA: No hay datos de nómina para esta semana cerrada');
        }
      }
    }
    
    print('\n3. 🏗️ ESTRUCTURA DE TABLAS:');
    print('=' * 50);
    
    // Verificar estructura de semanas_nomina
    print('\n📋 Estructura de semanas_nomina:');
    final columnasSemanas = await db.connection.query('''
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'semanas_nomina'
      ORDER BY ordinal_position;
    ''');
    
    for (var col in columnasSemanas) {
      print('   • ${col[0]} (${col[1]}) ${col[2] == 'YES' ? 'NULL' : 'NOT NULL'}');
    }
    
    // Verificar estructura de nomina_empleados_semanal  
    print('\n📋 Estructura de nomina_empleados_semanal:');
    final columnasNomina = await db.connection.query('''
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal'
      ORDER BY ordinal_position;
    ''');
    
    for (var col in columnasNomina) {
      print('   • ${col[0]} (${col[1]}) ${col[2] == 'YES' ? 'NULL' : 'NOT NULL'}');
    }
    
    print('\n4. 🔗 RELACIONES ENTRE TABLAS:');
    print('=' * 50);
    
    // Verificar foreign keys
    final relaciones = await db.connection.query('''
      SELECT
        tc.table_name as tabla_origen,
        kcu.column_name as columna_origen,
        ccu.table_name as tabla_referencia,
        ccu.column_name as columna_referencia
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND (tc.table_name = 'nomina_empleados_semanal' OR tc.table_name = 'semanas_nomina')
      ORDER BY tc.table_name, kcu.column_name;
    ''');
    
    if (relaciones.isNotEmpty) {
      for (var rel in relaciones) {
        print('   🔗 ${rel[0]}.${rel[1]} → ${rel[2]}.${rel[3]}');
      }
    } else {
      print('   ❌ No se encontraron foreign keys definidas');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
