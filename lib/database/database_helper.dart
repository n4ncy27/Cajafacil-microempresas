import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'caja_facil.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL,
        nombre TEXT NOT NULL,
        cantidad INTEGER NOT NULL DEFAULT 0,
        precio_compra REAL NOT NULL DEFAULT 0,
        precio_venta REAL NOT NULL DEFAULT 0,
        stock_minimo INTEGER NOT NULL DEFAULT 5,
        fecha_vencimiento TEXT,
        fecha_registro TEXT NOT NULL
      )
    ''');

    await _insertarProductosEjemplo(db);
  }

  Future<void> _insertarProductosEjemplo(Database db) async {
    final ahora = DateTime.now().toIso8601String();
    final productos = [
      // Cafés
      {'codigo': 'CAF001', 'nombre': 'Café Volcán en granos 250gr', 'cantidad': 100, 'precio_compra': 11460.0, 'precio_venta': 31460.0, 'stock_minimo': 10, 'fecha_vencimiento': '2026-12-31', 'fecha_registro': ahora},
      {'codigo': 'CAF002', 'nombre': 'Café Finca en grano 454gr', 'cantidad': 150, 'precio_compra': 45780.0, 'precio_venta': 65780.0, 'stock_minimo': 15, 'fecha_vencimiento': '2026-11-30', 'fecha_registro': ahora},
      {'codigo': 'CAF003', 'nombre': 'Café Mujeres Cafeteras 454gr', 'cantidad': 4, 'precio_compra': 45780.0, 'precio_venta': 65780.0, 'stock_minimo': 10, 'fecha_vencimiento': '2026-10-15', 'fecha_registro': ahora},
      {'codigo': 'CAF004', 'nombre': 'Café Origen Nariño en granos 454gr', 'cantidad': 250, 'precio_compra': 45780.0, 'precio_venta': 65780.0, 'stock_minimo': 20, 'fecha_vencimiento': '2027-01-20', 'fecha_registro': ahora},
      {'codigo': 'CAF005', 'nombre': 'Café Colina en grano 454gr', 'cantidad': 3, 'precio_compra': 36650.0, 'precio_venta': 56650.0, 'stock_minimo': 10, 'fecha_vencimiento': '2026-09-30', 'fecha_registro': ahora},
      {'codigo': 'CAF006', 'nombre': 'Café Molido Especial 250gr', 'cantidad': 80, 'precio_compra': 18000.0, 'precio_venta': 35000.0, 'stock_minimo': 10, 'fecha_vencimiento': '2026-08-15', 'fecha_registro': ahora},
      {'codigo': 'CAF007', 'nombre': 'Café Descafeinado 200gr', 'cantidad': 0, 'precio_compra': 22000.0, 'precio_venta': 42000.0, 'stock_minimo': 5, 'fecha_vencimiento': '2026-07-10', 'fecha_registro': ahora},
      // Productos de tienda
      {'codigo': 'TDA001', 'nombre': 'Azúcar blanca 1kg', 'cantidad': 200, 'precio_compra': 3200.0, 'precio_venta': 5500.0, 'stock_minimo': 20, 'fecha_vencimiento': null, 'fecha_registro': ahora},
      {'codigo': 'TDA002', 'nombre': 'Leche entera 1L', 'cantidad': 6, 'precio_compra': 2800.0, 'precio_venta': 4200.0, 'stock_minimo': 10, 'fecha_vencimiento': '2026-03-10', 'fecha_registro': ahora},
      {'codigo': 'TDA003', 'nombre': 'Agua purificada 600ml', 'cantidad': 48, 'precio_compra': 800.0, 'precio_venta': 2000.0, 'stock_minimo': 12, 'fecha_vencimiento': '2027-06-01', 'fecha_registro': ahora},
      {'codigo': 'TDA004', 'nombre': 'Chocolate en polvo 500gr', 'cantidad': 30, 'precio_compra': 12000.0, 'precio_venta': 22000.0, 'stock_minimo': 5, 'fecha_vencimiento': '2026-12-01', 'fecha_registro': ahora},
      {'codigo': 'TDA005', 'nombre': 'Vasos desechables x50', 'cantidad': 2, 'precio_compra': 4500.0, 'precio_venta': 8000.0, 'stock_minimo': 5, 'fecha_vencimiento': null, 'fecha_registro': ahora},
      {'codigo': 'TDA006', 'nombre': 'Servilletas x100', 'cantidad': 15, 'precio_compra': 3000.0, 'precio_venta': 5500.0, 'stock_minimo': 5, 'fecha_vencimiento': null, 'fecha_registro': ahora},
      {'codigo': 'TDA007', 'nombre': 'Endulzante Stevia x50 sobres', 'cantidad': 0, 'precio_compra': 5500.0, 'precio_venta': 9500.0, 'stock_minimo': 3, 'fecha_vencimiento': '2026-10-01', 'fecha_registro': ahora},
      {'codigo': 'TDA008', 'nombre': 'Canela en polvo 100gr', 'cantidad': 25, 'precio_compra': 4000.0, 'precio_venta': 7500.0, 'stock_minimo': 5, 'fecha_vencimiento': '2026-11-15', 'fecha_registro': ahora},
    ];

    for (final p in productos) {
      await db.insert('inventario', p);
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<int> insertarProducto(Map<String, dynamic> producto) async {
    final db = await database;
    producto['fecha_registro'] = DateTime.now().toIso8601String();
    return await db.insert('inventario', producto);
  }

  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    final db = await database;
    return await db.query('inventario', orderBy: 'nombre ASC');
  }

  Future<int> actualizarProducto(int id, Map<String, dynamic> producto) async {
    final db = await database;
    return await db.update('inventario', producto, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> eliminarProducto(int id) async {
    final db = await database;
    return await db.delete('inventario', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> aumentarStock(String codigo, int cantidad) async {
    final db = await database;
    await db.rawUpdate('UPDATE inventario SET cantidad = cantidad + ? WHERE codigo = ?', [cantidad, codigo]);
  }

  Future<void> disminuirStock(String codigo, int cantidad) async {
    final db = await database;
    await db.rawUpdate('UPDATE inventario SET cantidad = cantidad - ? WHERE codigo = ? AND cantidad >= ?', [cantidad, codigo, cantidad]);
  }

  Future<List<Map<String, dynamic>>> obtenerProductosBajoStock() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM inventario WHERE cantidad <= stock_minimo ORDER BY cantidad ASC');
  }

  Future<List<Map<String, dynamic>>> obtenerProductosProximosAVencer(int diasLimite) async {
    final db = await database;
    final fechaLimite = DateTime.now().add(Duration(days: diasLimite)).toIso8601String();
    return await db.rawQuery('''
      SELECT * FROM inventario
      WHERE fecha_vencimiento IS NOT NULL
        AND fecha_vencimiento <= ?
        AND fecha_vencimiento >= ?
      ORDER BY fecha_vencimiento ASC
    ''', [fechaLimite, DateTime.now().toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> buscarProductos(String query) async {
    final db = await database;
    return await db.query('inventario', where: 'nombre LIKE ? OR codigo LIKE ?', whereArgs: ['%$query%', '%$query%'], orderBy: 'nombre ASC');
  }
}