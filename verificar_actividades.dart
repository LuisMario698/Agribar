import 'package:postgres/postgres.dart';

Future<void> main() async {
  try {
    // Crear conexión a la base de datos
    final connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: 'admin',
      useSSL: false,
      allowClearTextPassword: false,
    );
    
    await connection.open();
    print('✅ Conectado a la base de datos');
    
    // Verificar si existe la tabla actividades
    print('\n🔍 Verificando tabla actividades...');
    final existeTabla = await connection.query('''
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'actividades'
      )
    ''');
    
    print('¿Existe tabla actividades?: ${existeTabla.first[0]}');
    
    if (existeTabla.first[0] == true) {
      // Ver estructura de la tabla
      print('\n📋 Estructura de la tabla actividades:');
      final estructura = await connection.query('''
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_name = 'actividades' 
        ORDER BY ordinal_position
      ''');
      
      for (final col in estructura) {
        print('  - ${col[0]}: ${col[1]} (nullable: ${col[2]}, default: ${col[3]})');
      }
      
      // Ver datos de ejemplo
      print('\n📊 Datos en la tabla actividades:');
      final datos = await connection.query('SELECT * FROM actividades LIMIT 10');
      
      print('Total de registros: ${datos.length}');
      for (final row in datos) {
        print('  ID: ${row[0]}, Clave: ${row[1]}, Nombre: ${row[2]}');
      }
    } else {
      print('❌ La tabla actividades no existe');
      
      // Crear la tabla actividades
      print('\n🔧 Creando tabla actividades...');
      await connection.execute('''
        CREATE TABLE actividades (
          id_actividad SERIAL PRIMARY KEY,
          clave VARCHAR(10) NOT NULL UNIQUE,
          nombre VARCHAR(100) NOT NULL,
          descripcion TEXT,
          estado BOOLEAN DEFAULT TRUE,
          fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Insertar datos de ejemplo
      print('📝 Insertando datos de ejemplo...');
      await connection.execute('''
        INSERT INTO actividades (clave, nombre, descripcion) VALUES
        ('PODA', 'Poda de árboles', 'Actividad de poda general'),
        ('RIEGO', 'Riego de cultivos', 'Sistema de riego y mantenimiento'),
        ('FERT', 'Fertilización', 'Aplicación de fertilizantes'),
        ('LIMP', 'Limpieza de campo', 'Limpieza y mantenimiento general'),
        ('COSE', 'Cosecha', 'Recolección de productos'),
        ('PLANT', 'Plantación', 'Siembra y plantación de cultivos'),
        ('MANT', 'Mantenimiento', 'Mantenimiento de equipos e instalaciones'),
        ('TRANS', 'Transporte', 'Transporte de materiales y productos')
      ''');
      
      print('✅ Tabla actividades creada e inicializada');
    }
    
    await connection.close();
    print('\n✅ Verificación completada');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
