import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔍 Explorando datos de ranchos...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    print('📋 Registros de nómina...');
    final nomina = await db.connection.query('''
      SELECT 
        id_empleado,
        act_1, campo_1, dia_1,
        act_2, campo_2, dia_2
      FROM nomina_empleados_historial 
      WHERE id_semana = 17
      LIMIT 3
    ''');
    
    print('Encontrados: ${nomina.length} registros');
    
    for (final row in nomina) {
      print('Empleado ${row[0]}:');
      print('  Act1=${row[1]}, Campo1=${row[2]}, Dia1=${row[3]}');
      print('  Act2=${row[4]}, Campo2=${row[5]}, Dia2=${row[6]}');
    }
    
  } catch (e) {
    print('Error: $e');
  } finally {
    await db.close();
  }
}
