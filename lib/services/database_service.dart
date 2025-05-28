// lib/services/database_service.dart
import 'package:postgres/postgres.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  late PostgreSQLConnection _connection;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<void> connect() async {
    _connection = PostgreSQLConnection(
      '192.168.1.100', // IP del servidor PostgreSQL
      5432,
      'agribar_db',    // Nombre de tu base de datos
      username: 'usuario',
      password: 'contraseña',
    );
    await _connection.open();
    print('✅ Conexión establecida con PostgreSQL');
  }

  PostgreSQLConnection get connection => _connection;

  Future<void> close() async {
    await _connection.close();
    print('❌ Conexión cerrada');
  }
}
