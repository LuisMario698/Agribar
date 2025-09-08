import 'package:postgres/postgres.dart';

void main() async {
  print('🔍 VERIFICANDO SEMANAS CERRADAS EN LA BASE DE DATOS\n');
  
  // Conectar a PostgreSQL
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'agribar_bd',
    username: 'postgres',
    password: '12345'
  );
  
  try {
    await connection.open();
    print('✅ Conexión establecida\n');
    
    // Verificar todas las semanas y su estado
    print('📋 CONSULTANDO TODAS LAS SEMANAS:');
    final todasSemanas = await connection.query('''
      SELECT 
        id_semana,
        fecha_inicio,
        fecha_fin,
        esta_cerrada,
        autorizado_por,
        fecha_autorizacion,
        creado_en
      FROM semanas_nomina
      ORDER BY id_semana DESC
      LIMIT 10;
    ''');
    
    print('\nRESULTADOS (últimas 10 semanas):');
    print('ID | Fechas | Cerrada | Autorizado | Fecha Autorización');
    print('---|--------|---------|------------|-------------------');
    
    for (var row in todasSemanas) {
      final id = row[0];
      final inicio = row[1].toString().substring(0, 10);
      final fin = row[2].toString().substring(0, 10);
      final cerrada = row[3];
      final autorizado = row[4] ?? '[null]';
      final fechaAuth = row[5]?.toString().substring(0, 19) ?? '[null]';
      
      print('$id | $inicio-$fin | $cerrada | $autorizado | $fechaAuth');
    }
    
    // Verificar específicamente las semanas 21, 22, 23
    print('\n🎯 VERIFICANDO SEMANAS 21, 22, 23 ESPECÍFICAMENTE:');
    final semanasEspecificas = await connection.query('''
      SELECT 
        id_semana,
        fecha_inicio,
        fecha_fin,
        esta_cerrada,
        autorizado_por,
        fecha_autorizacion
      FROM semanas_nomina
      WHERE id_semana IN (21, 22, 23)
      ORDER BY id_semana;
    ''');
    
    for (var row in semanasEspecificas) {
      final id = row[0];
      final inicio = row[1].toString().substring(0, 10);
      final fin = row[2].toString().substring(0, 10);
      final cerrada = row[3];
      final autorizado = row[4] ?? '[null]';
      final fechaAuth = row[5]?.toString().substring(0, 19) ?? '[null]';
      
      print('Semana $id: $inicio-$fin | Cerrada: $cerrada | Por: $autorizado | Cuando: $fechaAuth');
    }
    
    // Verificar función obtenerSemanasCerradas()
    print('\n🔍 SIMULANDO obtenerSemanasCerradas():');
    final semanasCerradas = await connection.query('''
      SELECT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.creado_en
      FROM semanas_nomina s
      WHERE s.esta_cerrada = true
      ORDER BY s.fecha_inicio DESC;
    ''');
    
    print('Semanas encontradas con esta_cerrada = true: ${semanasCerradas.length}');
    for (var row in semanasCerradas) {
      final id = row[0];
      final inicio = row[1].toString().substring(0, 10);
      final fin = row[2].toString().substring(0, 10);
      print('- Semana $id: $inicio-$fin');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await connection.close();
    print('\n🔄 Conexión cerrada');
  }
}
