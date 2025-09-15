import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  print('🔍 EXPLORAR: Todas las actividades disponibles');
  print('=' * 50);

  try {
    final connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: 'admin',
    );

    await connection.open();
    print('✅ Conexión establecida');

    // Mostrar TODAS las actividades
    final actividades = await connection.query('''
      SELECT id_actividad, clave, nombre, importe
      FROM actividades 
      ORDER BY CAST(clave AS INTEGER)
    ''');
    
    print('\n📋 TODAS las actividades en la BD:');
    print('ID\tCLAVE\tNOMBRE\t\t\t\tIMPORTE');
    print('-' * 70);
    
    for (final act in actividades) {
      final id = act[0];
      final clave = act[1] ?? '';
      final nombre = act[2] ?? '';
      final importe = act[3] ?? 0;
      
      print('$id\t$clave\t${nombre.toString().padRight(30)}\t$importe');
    }
    
    print('\n📊 Total actividades: ${actividades.length}');
    
    // Buscar específicamente las claves que se usan en la UI
    final clavesUI = ['1301', '1302', '1304', '1306'];
    print('\n🔍 Buscando claves usadas en UI:');
    for (final clave in clavesUI) {
      final encontrada = actividades.where((act) => act[1].toString() == clave);
      if (encontrada.isNotEmpty) {
        final act = encontrada.first;
        print('   ✅ Clave "$clave" → ID ${act[0]} (${act[2]})');
      } else {
        print('   ❌ Clave "$clave" NO ENCONTRADA en tabla actividades');
      }
    }

    await connection.close();
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}