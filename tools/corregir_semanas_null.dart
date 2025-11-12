import 'package:postgres/postgres.dart';

void main() async {
  print('🔧 CORRIGIENDO SEMANAS 21 y 22 CON AUTORIZADO_POR NULL\n');
  
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
    
    // Verificar estado actual de las semanas 21 y 22
    print('📋 ESTADO ACTUAL DE SEMANAS 21 y 22:');
    final estadoAntes = await connection.query('''
      SELECT 
        id_semana,
        esta_cerrada,
        autorizado_por,
        fecha_autorizacion
      FROM semanas_nomina
      WHERE id_semana IN (21, 22)
      ORDER BY id_semana;
    ''');
    
    for (var row in estadoAntes) {
      print('Semana ${row[0]}: Cerrada=${row[1]}, Autorizado=${row[2] ?? 'NULL'}, Fecha=${row[3]?.toString().substring(0, 19) ?? 'NULL'}');
    }
    
    // Corregir semanas 21 y 22
    print('\n🔧 CORRIGIENDO SEMANAS...');
    
    final resultados = await connection.execute('''
      UPDATE semanas_nomina 
      SET autorizado_por = 'jose Geronimo',
          fecha_autorizacion = CURRENT_TIMESTAMP
      WHERE id_semana IN (21, 22) 
        AND esta_cerrada = true 
        AND autorizado_por IS NULL;
    ''');
    
    print('✅ Filas actualizadas: $resultados');
    
    // Verificar estado después de la corrección
    print('\n📋 ESTADO DESPUÉS DE LA CORRECCIÓN:');
    final estadoDespues = await connection.query('''
      SELECT 
        id_semana,
        esta_cerrada,
        autorizado_por,
        fecha_autorizacion
      FROM semanas_nomina
      WHERE id_semana IN (21, 22)
      ORDER BY id_semana;
    ''');
    
    for (var row in estadoDespues) {
      print('Semana ${row[0]}: Cerrada=${row[1]}, Autorizado=${row[2] ?? 'NULL'}, Fecha=${row[3]?.toString().substring(0, 19) ?? 'NULL'}');
    }
    
    print('\n✅ Corrección completada');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await connection.close();
    print('🔄 Conexión cerrada');
  }
}
