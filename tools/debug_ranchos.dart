import 'package:agribar/services/database_service.dart';

void main() async {
  print('🔍 Explorando datos de ranchos en nómina...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // Ver algunos registros de nómina para entender la estructura
    print('📋 Explorando registros de nómina...');
    final nomina = await db.connection.query('''
      SELECT 
        id_empleado,
        cuadrilla,
        act_1, campo_1, dia_1,
        act_2, campo_2, dia_2,
        act_3, campo_3, dia_3,
        act_4, campo_4, dia_4,
        act_5, campo_5, dia_5,
        act_6, campo_6, dia_6,
        act_7, campo_7, dia_7
      FROM nomina_empleados_historial 
      WHERE id_semana = 17
      LIMIT 5
    ''');
    
    print('✅ Registros encontrados: ${nomina.length}');
    
    for (int i = 0; i < nomina.length; i++) {
      final row = nomina[i];
      print('\n--- Empleado ${row[0]} ---');
      print('Cuadrilla: ${row[1]}');
      for (int dia = 1; dia <= 7; dia++) {
        final actIndex = 1 + (dia - 1) * 3 + 1;
        final campoIndex = actIndex + 1;
        final pagoIndex = campoIndex + 1;
        
        final actividad = row[actIndex];
        final campo = row[campoIndex];
        final pago = row[pagoIndex];
        
        if (actividad != null && actividad != 0) {
          print('  Día $dia: Act=$actividad, Campo=$campo, Pago=$pago');
        }
      }
    }
    
    // Ver qué valores únicos hay en los campos
    print('\n🔍 Valores únicos en campos...');
    final campos = await db.connection.query('''
      SELECT DISTINCT 
        campo_1, campo_2, campo_3, campo_4, campo_5, campo_6, campo_7
      FROM nomina_empleados_historial 
      WHERE id_semana = 17
      LIMIT 10
    ''');
    
    print('Valores de campo encontrados:');
    final camposUnicos = <int>{};
    for (final row in campos) {
      for (int i = 0; i < 7; i++) {
        final valor = row[i];
        if (valor != null && valor != 0) {
          camposUnicos.add(valor as int);
        }
      }
    }
    print('Campos únicos: $camposUnicos');
    
    // Ver si estos campos corresponden a IDs de ranchos
    if (camposUnicos.isNotEmpty) {
      print('\n🔍 Verificando si son IDs de ranchos...');
      for (final campoId in camposUnicos) {
        final rancho = await db.connection.query('''
          SELECT id_rancho, nombre 
          FROM ranchos 
          WHERE id_rancho = @id
        ''', substitutionValues: {'id': campoId});
        
        if (rancho.isNotEmpty) {
          print('  Campo $campoId = Rancho: ${rancho.first[1]}');
        } else {
          print('  Campo $campoId = NO es un rancho');
        }
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
