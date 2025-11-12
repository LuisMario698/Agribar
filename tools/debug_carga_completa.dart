import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  print('🔍 DEBUG: Simulando proceso completo de carga de nómina');
  print('=' * 60);

  try {
    // Conectar a PostgreSQL
    final connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: 'admin',
    );

    await connection.open();
    print('✅ Conexión establecida con PostgreSQL');

    // 1. Simular carga de mapas de actividades (como en _cargarMappingActividades)
    print('\n🔄 1. Cargando mapas de actividades...');
    final actividades = await connection.query(
      'SELECT id_actividad, clave, nombre FROM actividades ORDER BY clave'
    );
    
    Map<String, int> claveAIdMap = {};
    Map<int, String> idAClaveMap = {};
    Map<String, String> claveANombreMap = {};
    
    for (final actividad in actividades) {
      final id = actividad[0] as int;
      final clave = actividad[1]?.toString() ?? '';
      final nombre = actividad[2]?.toString() ?? '';
      
      if (clave.isNotEmpty) {
        claveAIdMap[clave] = id;
        idAClaveMap[id] = clave;
        claveANombreMap[clave] = nombre;
      }
    }
    
    print('   Mapas cargados: ${claveAIdMap.length} actividades');

    // 2. Simulear función _convertirIdAClave
    String convertirIdAClave(int id) {
      return idAClaveMap[id] ?? id.toString();
    }

    // 3. Simular función _norm
    String norm(dynamic v) {
      final s = v?.toString() ?? '0';
      if (s.contains('.')) return s;
      final soloDigitos = RegExp(r'^\d{5,}$');
      if (soloDigitos.hasMatch(s)) {
        final d = double.tryParse(s) ?? 0.0;
        if (d < 1000000) {
          final ajustado = d / 100.0;
          if (ajustado < 10000) {
            return ajustado.toStringAsFixed(2);
          }
        }
      }
      return s;
    }

    // 4. Obtener datos reales de un empleado
    print('\n📊 2. Cargando datos reales de empleado...');
    final nominaResult = await connection.query('''
      SELECT 
        n.dia_1, n.act_1, n.campo_1,
        n.dia_2, n.act_2, n.campo_2,
        n.dia_3, n.act_3, n.campo_3,
        n.dia_4, n.act_4, n.campo_4,
        n.dia_5, n.act_5, n.campo_5,
        n.dia_6, n.act_6, n.campo_6,
        n.dia_7, n.act_7, n.campo_7,
        n.total, n.debe, n.subtotal, n.comedor, n.total_neto
      FROM nomina_empleados_semanal n
      WHERE n.id_empleado = 10043 AND n.id_semana = 47 AND n.id_cuadrilla = 103
    ''');

    if (nominaResult.isEmpty) {
      print('   ❌ No se encontraron datos para el empleado 10043, semana 47, cuadrilla 103');
      await connection.close();
      return;
    }

    final nominaData = nominaResult.first;
    print('   ✅ Datos encontrados para empleado 10043');

    // 5. Procesar datos como en la aplicación real
    print('\n🔄 3. Procesando datos como en obtenerNominaEmpleadosDeCuadrilla:');
    
    final datosResultantes = {
      // Día 1 (Lunes) - BD: dia_1, act_1, campo_1 → Tabla: dia_0_s, dia_0_id, dia_0_campo
      'dia_0_s': norm(nominaData[0]),
      'dia_0_id': convertirIdAClave(int.tryParse(nominaData[1]?.toString() ?? '0') ?? 0),
      'dia_0_campo': nominaData[2]?.toString() ?? '0',
      
      // Día 2 (Martes) - BD: dia_2, act_2, campo_2 → Tabla: dia_1_s, dia_1_id, dia_1_campo
      'dia_1_s': norm(nominaData[3]),
      'dia_1_id': convertirIdAClave(int.tryParse(nominaData[4]?.toString() ?? '0') ?? 0),
      'dia_1_campo': nominaData[5]?.toString() ?? '0',
      
      // Día 3 (Miércoles) - BD: dia_3, act_3, campo_3 → Tabla: dia_2_s, dia_2_id, dia_2_campo
      'dia_2_s': norm(nominaData[6]),
      'dia_2_id': convertirIdAClave(int.tryParse(nominaData[7]?.toString() ?? '0') ?? 0),
      'dia_2_campo': nominaData[8]?.toString() ?? '0',
    };
    
    print('   📋 Datos originales de BD:');
    print('     dia_1: ${nominaData[0]}, act_1: ${nominaData[1]}, campo_1: ${nominaData[2]}');
    print('     dia_2: ${nominaData[3]}, act_2: ${nominaData[4]}, campo_2: ${nominaData[5]}');
    print('     dia_3: ${nominaData[6]}, act_3: ${nominaData[7]}, campo_3: ${nominaData[8]}');
    
    print('\n   📊 Datos después del procesamiento:');
    print('     dia_0_s: "${datosResultantes['dia_0_s']}", dia_0_id: "${datosResultantes['dia_0_id']}", dia_0_campo: "${datosResultantes['dia_0_campo']}"');
    print('     dia_1_s: "${datosResultantes['dia_1_s']}", dia_1_id: "${datosResultantes['dia_1_id']}", dia_1_campo: "${datosResultantes['dia_1_campo']}"');
    print('     dia_2_s: "${datosResultantes['dia_2_s']}", dia_2_id: "${datosResultantes['dia_2_id']}", dia_2_campo: "${datosResultantes['dia_2_campo']}"');

    // 6. Verificar específicamente el problema reportado
    print('\n🎯 4. Verificando problema específico:');
    
    // El usuario reporta que dia_2 BD (0.50) no aparece en dia_1_s tabla
    final dia2BD = nominaData[3]; // dia_2 de BD
    final dia1sTabla = datosResultantes['dia_1_s']; // dia_1_s de tabla
    
    print('   ❓ ¿El sueldo 0.50 del martes (dia_2 BD) aparece en dia_1_s tabla?');
    print('     BD dia_2: $dia2BD');
    print('     Tabla dia_1_s: "$dia1sTabla"');
    
    if (dia2BD.toString() == dia1sTabla) {
      print('   ✅ Los datos SÍ coinciden - el problema NO está en la carga');
      print('   🤔 El problema puede estar en la UI no mostrando los datos correctamente');
    } else {
      print('   ❌ Los datos NO coinciden - problema en la carga de datos');
    }

    // 7. Verificar conversión de actividades
    final act2BD = nominaData[4]; // act_2 de BD (ID)
    final dia1idTabla = datosResultantes['dia_1_id']; // dia_1_id de tabla (clave)
    
    print('\n   ❓ ¿La actividad ID ${act2BD} se convierte correctamente a clave?');
    if (act2BD != null && act2BD != 0) {
      final claveEsperada = idAClaveMap[act2BD];
      print('     BD act_2: $act2BD');
      print('     Clave esperada: $claveEsperada');
      print('     Tabla dia_1_id: "$dia1idTabla"');
      
      if (claveEsperada == dia1idTabla) {
        print('   ✅ La conversión de actividad funciona correctamente');
      } else {
        print('   ❌ Error en conversión de actividad');
      }
    } else {
      print('     BD act_2: $act2BD (sin actividad)');
      print('     Tabla dia_1_id: "$dia1idTabla"');
    }

    await connection.close();
    print('\n✅ Debug de carga completado');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}