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
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── Inventario ──────────────────────────────────────────────────────────
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

    // ── Clientes ────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        identificacion TEXT,
        deuda_total REAL NOT NULL DEFAULT 0,
        fecha_registro TEXT NOT NULL
      )
    ''');

    // ── Ventas ──────────────────────────────────────────────────────────────
    // Mantiene campo "cliente" (texto) para compatibilidad con voz
    // Agrega "cliente_id" para ventas registradas desde el carrito
    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        forma_pago TEXT NOT NULL,
        total REAL NOT NULL DEFAULT 0,
        tipo TEXT NOT NULL DEFAULT 'contado',
        cliente TEXT,
        cliente_id INTEGER,
        observacion TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
      )
    ''');

    // ── Detalle de ventas ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE detalle_ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        producto_id INTEGER,
        codigo TEXT NOT NULL,
        nombre TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (venta_id) REFERENCES ventas (id) ON DELETE CASCADE
      )
    ''');

    // ── Abonos ──────────────────────────────────────────────────────────────
    // venta_id se mantiene para compatibilidad; cliente_id para el nuevo flujo
    await db.execute('''
      CREATE TABLE abonos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER,
        cliente_id INTEGER,
        cliente TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        observacion TEXT,
        FOREIGN KEY (venta_id) REFERENCES ventas (id) ON DELETE SET NULL,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
      )
    ''');

    // ── Compras ─────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE compras (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        proveedor        TEXT    NOT NULL,
        producto_id      INTEGER,
        codigo_producto  TEXT    NOT NULL,
        nombre_producto  TEXT    NOT NULL,
        cantidad         INTEGER NOT NULL,
        precio_unitario  REAL    NOT NULL,
        total            REAL    NOT NULL,
        forma_pago       TEXT    NOT NULL,
        fecha            TEXT    NOT NULL,
        pagada           INTEGER NOT NULL DEFAULT 0,
        fecha_pago       TEXT,
        forma_pago_pago  TEXT,
        FOREIGN KEY (producto_id) REFERENCES inventario (id)
      )
    ''');

    // ── Pagos a proveedor ────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE pagos_proveedor (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        compra_id  INTEGER NOT NULL,
        monto      REAL    NOT NULL,
        fecha      TEXT    NOT NULL,
        forma_pago TEXT    NOT NULL,
        FOREIGN KEY (compra_id) REFERENCES compras (id) ON DELETE CASCADE
      )
    ''');

    await _insertarProductosEjemplo(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migración incremental: no borra datos existentes
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ventas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha TEXT NOT NULL,
          forma_pago TEXT NOT NULL,
          total REAL NOT NULL DEFAULT 0,
          tipo TEXT NOT NULL DEFAULT 'contado',
          cliente TEXT,
          observacion TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS detalle_ventas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          venta_id INTEGER NOT NULL,
          producto_id INTEGER,
          codigo TEXT NOT NULL,
          nombre TEXT NOT NULL,
          cantidad INTEGER NOT NULL,
          precio_unitario REAL NOT NULL,
          subtotal REAL NOT NULL,
          FOREIGN KEY (venta_id) REFERENCES ventas (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS abonos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          venta_id INTEGER NOT NULL,
          cliente TEXT NOT NULL,
          monto REAL NOT NULL,
          fecha TEXT NOT NULL,
          observacion TEXT,
          FOREIGN KEY (venta_id) REFERENCES ventas (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      // Nueva tabla clientes
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clientes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          telefono TEXT,
          identificacion TEXT,
          deuda_total REAL NOT NULL DEFAULT 0,
          fecha_registro TEXT NOT NULL
        )
      ''');

      // Agregar cliente_id a ventas (ALTER TABLE en SQLite solo permite ADD COLUMN)
      try {
        await db.execute('ALTER TABLE ventas ADD COLUMN cliente_id INTEGER');
      } catch (_) {
        // Ya existe, ignorar
      }

      // Recrear abonos con las columnas nuevas (cliente_id opcional, venta_id nullable)
      await db.execute('ALTER TABLE abonos RENAME TO abonos_old');
      await db.execute('''
        CREATE TABLE abonos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          venta_id INTEGER,
          cliente_id INTEGER,
          cliente TEXT NOT NULL,
          monto REAL NOT NULL,
          fecha TEXT NOT NULL,
          observacion TEXT,
          FOREIGN KEY (venta_id) REFERENCES ventas (id) ON DELETE SET NULL,
          FOREIGN KEY (cliente_id) REFERENCES clientes (id)
        )
      ''');
      // Migrar abonos existentes
      await db.execute('''
        INSERT INTO abonos (venta_id, cliente, monto, fecha, observacion)
        SELECT venta_id, cliente, monto, fecha, observacion FROM abonos_old
      ''');
      await db.execute('DROP TABLE abonos_old');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS compras (
          id               INTEGER PRIMARY KEY AUTOINCREMENT,
          proveedor        TEXT    NOT NULL,
          producto_id      INTEGER,
          codigo_producto  TEXT    NOT NULL,
          nombre_producto  TEXT    NOT NULL,
          cantidad         INTEGER NOT NULL,
          precio_unitario  REAL    NOT NULL,
          total            REAL    NOT NULL,
          forma_pago       TEXT    NOT NULL,
          fecha            TEXT    NOT NULL,
          pagada           INTEGER NOT NULL DEFAULT 0,
          fecha_pago       TEXT,
          forma_pago_pago  TEXT,
          FOREIGN KEY (producto_id) REFERENCES inventario (id)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pagos_proveedor (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          compra_id  INTEGER NOT NULL,
          monto      REAL    NOT NULL,
          fecha      TEXT    NOT NULL,
          forma_pago TEXT    NOT NULL,
          FOREIGN KEY (compra_id) REFERENCES compras (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _insertarProductosEjemplo(Database db) async {
    final ahora = DateTime.now().toIso8601String();
    final productos = [
      {'codigo': 'CAF001', 'nombre': 'Café Volcán en granos 250gr', 'cantidad': 100, 'precio_compra': 11460.0, 'precio_venta': 31460.0, 'stock_minimo': 10, 'fecha_vencimiento': '2026-12-31', 'fecha_registro': ahora},
      {'codigo': 'CAF002', 'nombre': 'Café Finca en grano 454gr', 'cantidad': 150, 'precio_compra': 45780.0, 'precio_venta': 65780.0, 'stock_minimo': 15, 'fecha_vencimiento': '2026-11-30', 'fecha_registro': ahora},
      {'codigo': 'CAF003', 'nombre': 'Café Mujeres Cafeteras 454gr', 'cantidad': 4, 'precio_compra': 45780.0, 'precio_venta': 65780.0, 'stock_minimo': 10, 'fecha_vencimiento': '2026-10-15', 'fecha_registro': ahora},
      {'codigo': 'CAF004', 'nombre': 'Café Origen Nariño en granos 454gr', 'cantidad': 250, 'precio_compra': 45780.0, 'precio_venta': 65780.0, 'stock_minimo': 20, 'fecha_vencimiento': '2027-01-20', 'fecha_registro': ahora},
      {'codigo': 'CAF005', 'nombre': 'Café Colina en grano 454gr', 'cantidad': 3, 'precio_compra': 36650.0, 'precio_venta': 56650.0, 'stock_minimo': 10, 'fecha_vencimiento': '2026-09-30', 'fecha_registro': ahora},
      {'codigo': 'CAF006', 'nombre': 'Café Molido Especial 250gr', 'cantidad': 80, 'precio_compra': 18000.0, 'precio_venta': 35000.0, 'stock_minimo': 10, 'fecha_vencimiento': '2026-08-15', 'fecha_registro': ahora},
      {'codigo': 'CAF007', 'nombre': 'Café Descafeinado 200gr', 'cantidad': 0, 'precio_compra': 22000.0, 'precio_venta': 42000.0, 'stock_minimo': 5, 'fecha_vencimiento': '2026-07-10', 'fecha_registro': ahora},
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

  // ── INVENTARIO CRUD ────────────────────────────────────────────────────────

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
    await db.rawUpdate(
        'UPDATE inventario SET cantidad = cantidad + ? WHERE codigo = ?',
        [cantidad, codigo]);
  }

  Future<void> disminuirStock(String codigo, int cantidad) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE inventario SET cantidad = cantidad - ? WHERE codigo = ? AND cantidad >= ?',
        [cantidad, codigo, cantidad]);
  }

  Future<List<Map<String, dynamic>>> obtenerProductosBajoStock() async {
    final db = await database;
    return await db.rawQuery(
        'SELECT * FROM inventario WHERE cantidad <= stock_minimo ORDER BY cantidad ASC');
  }

  Future<List<Map<String, dynamic>>> obtenerProductosProximosAVencer(
      int diasLimite) async {
    final db = await database;
    final fechaLimite =
        DateTime.now().add(Duration(days: diasLimite)).toIso8601String();
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
    return await db.query('inventario',
        where: 'nombre LIKE ? OR codigo LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'nombre ASC');
  }

  // ── CLIENTES ───────────────────────────────────────────────────────────────

  Future<int> insertarCliente(Map<String, dynamic> cliente) async {
    final db = await database;
    cliente['fecha_registro'] = DateTime.now().toIso8601String();
    cliente['deuda_total'] = 0.0;
    return await db.insert('clientes', cliente);
  }

  Future<List<Map<String, dynamic>>> buscarClientes(String query) async {
    final db = await database;
    return await db.query('clientes',
        where: 'nombre LIKE ? OR identificacion LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'deuda_total DESC, nombre ASC');
  }

  /// Clientes que tienen ventas a crédito, ordenados: pendientes primero (mayor deuda), cancelados al final
  Future<List<Map<String, dynamic>>> obtenerClientesCredito() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.*,
             COUNT(v.id) as total_ventas,
             MAX(v.fecha) as ultima_compra
      FROM clientes c
      LEFT JOIN ventas v ON c.id = v.cliente_id AND v.tipo = 'crédito'
      GROUP BY c.id
      ORDER BY
        CASE WHEN c.deuda_total > 0 THEN 0 ELSE 1 END,
        c.deuda_total DESC,
        c.nombre ASC
    ''');
  }

  // ── VENTAS ─────────────────────────────────────────────────────────────────

  /// Registrar venta — compatible con voz (cliente como texto) y carrito (cliente_id)
  Future<int> registrarVenta({
    required String formaPago,
    required String tipo,
    required List<Map<String, dynamic>> items,
    String? cliente,       // usado por la voz
    int? clienteId,        // usado por el carrito con cliente registrado
    String? observacion,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      final double total =
          items.fold(0, (sum, i) => sum + (i['subtotal'] as double));

      // Si viene clienteId, rellenar también el campo texto para que la lista lo muestre
      String? nombreCliente = cliente;
      if (clienteId != null && nombreCliente == null) {
        final rows = await txn
            .query('clientes', where: 'id = ?', whereArgs: [clienteId]);
        if (rows.isNotEmpty) nombreCliente = rows.first['nombre'] as String;
      }

      final ventaId = await txn.insert('ventas', {
        'fecha': DateTime.now().toIso8601String(),
        'forma_pago': formaPago,
        'total': total,
        'tipo': tipo,
        'cliente': nombreCliente,
        'cliente_id': clienteId,
        'observacion': observacion,
      });

      for (final item in items) {
        await txn.insert('detalle_ventas', {
          'venta_id': ventaId,
          'producto_id': item['producto_id'],
          'codigo': item['codigo'],
          'nombre': item['nombre'],
          'cantidad': item['cantidad'],
          'precio_unitario': item['precio_unitario'],
          'subtotal': item['subtotal'],
        });

        if (item['producto_id'] != null) {
          await txn.rawUpdate(
            'UPDATE inventario SET cantidad = cantidad - ? WHERE id = ? AND cantidad >= ?',
            [item['cantidad'], item['producto_id'], item['cantidad']],
          );
        }
      }

      // Sumar deuda solo si tiene cliente registrado
      if (tipo == 'crédito' && clienteId != null) {
        await txn.rawUpdate(
          'UPDATE clientes SET deuda_total = deuda_total + ? WHERE id = ?',
          [total, clienteId],
        );
      }

      return ventaId;
    });
  }

  Future<List<Map<String, dynamic>>> obtenerVentas() async {
    final db = await database;
    return await db.query('ventas', orderBy: 'fecha DESC');
  }

  Future<List<Map<String, dynamic>>> obtenerDetalleVenta(int ventaId) async {
    final db = await database;
    return await db.query('detalle_ventas',
        where: 'venta_id = ?', whereArgs: [ventaId]);
  }

  Future<void> eliminarVenta(int ventaId) async {
    final db = await database;
    await db.transaction((txn) async {
      final venta =
          await txn.query('ventas', where: 'id = ?', whereArgs: [ventaId]);
      if (venta.isEmpty) return;
      final v = venta.first;

      // Restaurar stock
      final detalles = await txn.query('detalle_ventas',
          where: 'venta_id = ?', whereArgs: [ventaId]);
      for (final d in detalles) {
        if (d['producto_id'] != null) {
          await txn.rawUpdate(
            'UPDATE inventario SET cantidad = cantidad + ? WHERE id = ?',
            [d['cantidad'], d['producto_id']],
          );
        }
      }

      // Restaurar deuda si era crédito con cliente registrado
      if (v['tipo'] == 'crédito' && v['cliente_id'] != null) {
        await txn.rawUpdate(
          'UPDATE clientes SET deuda_total = MAX(0, deuda_total - ?) WHERE id = ?',
          [v['total'], v['cliente_id']],
        );
      }

      await txn.delete('ventas', where: 'id = ?', whereArgs: [ventaId]);
    });
  }

  Future<List<Map<String, dynamic>>> obtenerVentasPorPeriodo(
      String desde, String hasta) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT v.*, GROUP_CONCAT(d.nombre, ', ') as productos
      FROM ventas v
      LEFT JOIN detalle_ventas d ON v.id = d.venta_id
      WHERE v.fecha BETWEEN ? AND ?
      GROUP BY v.id
      ORDER BY v.fecha DESC
    ''', [desde, hasta]);
  }

  // ── ABONOS ─────────────────────────────────────────────────────────────────

  /// Registrar abono por cliente registrado — reduce deuda_total
  Future<int> registrarAbonoCliente({
    required int clienteId,
    required String nombreCliente,
    required double monto,
    String? observacion,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      final abonoId = await txn.insert('abonos', {
        'cliente_id': clienteId,
        'cliente': nombreCliente,
        'monto': monto,
        'fecha': DateTime.now().toIso8601String(),
        'observacion': observacion,
      });
      await txn.rawUpdate(
        'UPDATE clientes SET deuda_total = MAX(0, deuda_total - ?) WHERE id = ?',
        [monto, clienteId],
      );
      return abonoId;
    });
  }

  /// Mantener compatibilidad con código existente (voz u otros usos)
  Future<int> registrarAbono(Map<String, dynamic> abono) async {
    final db = await database;
    abono['fecha'] = DateTime.now().toIso8601String();
    return await db.insert('abonos', abono);
  }

  Future<List<Map<String, dynamic>>> obtenerAbonosPorVenta(int ventaId) async {
    final db = await database;
    return await db.query('abonos',
        where: 'venta_id = ?',
        whereArgs: [ventaId],
        orderBy: 'fecha DESC');
  }

  Future<List<Map<String, dynamic>>> obtenerAbonosPorCliente(
      int clienteId) async {
    final db = await database;
    return await db.query('abonos',
        where: 'cliente_id = ?',
        whereArgs: [clienteId],
        orderBy: 'fecha DESC');
  }

  /// Registra una compra e incrementa el stock del producto en inventario.
  /// Todo en una sola transacción para garantizar consistencia.
  Future<int> registrarCompra({
    required String proveedor,
    required int productoId,
    required String codigoProducto,
    required String nombreProducto,
    required int cantidad,
    required double precioUnitario,
    required double total,
    required String formaPago,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      // 1. Insertar la compra
      final compraId = await txn.insert('compras', {
        'proveedor':       proveedor,
        'producto_id':     productoId,
        'codigo_producto': codigoProducto,
        'nombre_producto': nombreProducto,
        'cantidad':        cantidad,
        'precio_unitario': precioUnitario,
        'total':           total,
        'forma_pago':      formaPago,
        'fecha':           DateTime.now().toIso8601String(),
        'pagada':          formaPago.toLowerCase() == 'crédito' ? 0 : 1,
      });

      // 2. Aumentar stock en inventario
      await txn.rawUpdate(
        'UPDATE inventario SET cantidad = cantidad + ? WHERE id = ?',
        [cantidad, productoId],
      );

      return compraId;
    });
  }

  /// Obtiene compras filtradas por período (hoy / semana / mes).
  Future<List<Map<String, dynamic>>> obtenerComprasFiltradas(
      String filtro) async {
    final db = await database;
    final ahora = DateTime.now();

    DateTime inicio;
    if (filtro == 'Hoy') {
      inicio = DateTime(ahora.year, ahora.month, ahora.day);
    } else if (filtro == 'Semana') {
      inicio = ahora.subtract(Duration(days: ahora.weekday - 1));
      inicio = DateTime(inicio.year, inicio.month, inicio.day);
    } else {
      // Mes
      inicio = DateTime(ahora.year, ahora.month, 1);
    }

    return await db.query(
      'compras',
      where: 'fecha >= ?',
      whereArgs: [inicio.toIso8601String()],
      orderBy: 'fecha DESC',
    );
  }

  /// Devuelve las compras a crédito que aún no han sido pagadas.
  Future<List<Map<String, dynamic>>> obtenerComprasPendientes() async {
    final db = await database;
    return await db.query(
      'compras',
      where: "forma_pago = 'Crédito' AND pagada = 0",
      orderBy: 'fecha DESC',
    );
  }

  /// Marca una compra como pagada y registra el pago en `pagos_proveedor`.
  Future<void> registrarPagoProveedor({
    required int compraId,
    required DateTime fechaPago,
    required String formaPago,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Obtener monto de la compra
      final rows = await txn.query('compras',
          columns: ['total'], where: 'id = ?', whereArgs: [compraId]);
      if (rows.isEmpty) return;
      final monto = (rows.first['total'] as num).toDouble();

      // 2. Registrar en historial de pagos
      await txn.insert('pagos_proveedor', {
        'compra_id':  compraId,
        'monto':      monto,
        'fecha':      fechaPago.toIso8601String(),
        'forma_pago': formaPago,
      });

      // 3. Marcar compra como pagada
      await txn.update(
        'compras',
        {
          'pagada':          1,
          'fecha_pago':      fechaPago.toIso8601String(),
          'forma_pago_pago': formaPago,
        },
        where: 'id = ?',
        whereArgs: [compraId],
      );
    });
  }

  /// Devuelve el total de compras en un período dado (para reportes).
  /// [desde] y [hasta] son ISO strings.
  Future<Map<String, double>> resumenComprasPorPeriodo(
      String desde, String hasta) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        SUM(total)                                        AS total_general,
        SUM(CASE WHEN forma_pago = 'Efectivo'   THEN total ELSE 0 END) AS total_efectivo,
        SUM(CASE WHEN forma_pago IN ('Nequi','Transferencia')
                                                THEN total ELSE 0 END) AS total_nequi,
        SUM(CASE WHEN forma_pago = 'Crédito'    THEN total ELSE 0 END) AS total_credito
      FROM compras
      WHERE fecha BETWEEN ? AND ?
    ''', [desde, hasta]);

    if (rows.isEmpty) {
      return {
        'total_general': 0,
        'total_efectivo': 0,
        'total_nequi': 0,
        'total_credito': 0,
      };
    }
    final r = rows.first;
    return {
      'total_general':  (r['total_general']  as num?)?.toDouble() ?? 0,
      'total_efectivo': (r['total_efectivo'] as num?)?.toDouble() ?? 0,
      'total_nequi':    (r['total_nequi']    as num?)?.toDouble() ?? 0,
      'total_credito':  (r['total_credito']  as num?)?.toDouble() ?? 0,
    };
  }

  // ── REPORTES ───────────────────────────────────────────────────────────────

  /// Flujo de Caja: ingresos en efectivo, compras en efectivo, gastos en efectivo
  Future<Map<String, double>> obtenerFlujoCaja(String filtro) async {
    final db = await database;
    final ahora = DateTime.now();

    DateTime inicio;
    if (filtro == 'Hoy') {
      inicio = DateTime(ahora.year, ahora.month, ahora.day);
    } else if (filtro == 'Semana') {
      inicio = ahora.subtract(Duration(days: ahora.weekday - 1));
      inicio = DateTime(inicio.year, inicio.month, inicio.day);
    } else {
      inicio = DateTime(ahora.year, ahora.month, 1);
    }
    final desde = inicio.toIso8601String();

    // Ingresos en efectivo (ventas con forma_pago Efectivo)
    final ingRows = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS total
      FROM ventas
      WHERE fecha >= ? AND LOWER(forma_pago) = 'efectivo'
    ''', [desde]);
    final ingresosEfectivo = (ingRows.first['total'] as num?)?.toDouble() ?? 0;

    // Compras pagadas en efectivo
    final compRows = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS total
      FROM compras
      WHERE fecha >= ? AND LOWER(forma_pago) = 'efectivo'
    ''', [desde]);
    final comprasEfectivo = (compRows.first['total'] as num?)?.toDouble() ?? 0;

    // Pagos a proveedor en efectivo (de compras a crédito pagadas en efectivo)
    final pagoProvRows = await db.rawQuery('''
      SELECT COALESCE(SUM(monto), 0) AS total
      FROM pagos_proveedor
      WHERE fecha >= ? AND LOWER(forma_pago) = 'efectivo'
    ''', [desde]);
    final pagosProvEfectivo = (pagoProvRows.first['total'] as num?)?.toDouble() ?? 0;

    final totalComprasEfectivo = comprasEfectivo + pagosProvEfectivo;

    return {
      'ingresos_efectivo': ingresosEfectivo,
      'compras_efectivo': totalComprasEfectivo,
      'gastos_efectivo': 0, // Módulo gastos pendiente
      'total_caja': ingresosEfectivo - totalComprasEfectivo,
    };
  }

  /// Cuentas por Cobrar: ventas a crédito no pagadas totalmente
  Future<List<Map<String, dynamic>>> obtenerCuentasPorCobrar() async {
    final db = await database;
    // Ventas a crédito con la suma de abonos
    final rows = await db.rawQuery('''
      SELECT
        v.id,
        v.cliente,
        v.total,
        v.fecha,
        COALESCE(SUM(a.monto), 0) AS total_abonado
      FROM ventas v
      LEFT JOIN abonos a ON a.venta_id = v.id
      WHERE LOWER(v.tipo) = 'crédito'
      GROUP BY v.id
      HAVING v.total - COALESCE(SUM(a.monto), 0) > 0
      ORDER BY v.fecha DESC
    ''');

    return rows.map((r) {
      final total = (r['total'] as num).toDouble();
      final abonado = (r['total_abonado'] as num).toDouble();
      return {
        ...r,
        'saldo_pendiente': total - abonado,
      };
    }).toList();
  }

  /// Cuentas por Pagar: compras a crédito no pagadas
  Future<List<Map<String, dynamic>>> obtenerCuentasPorPagar() async {
    final db = await database;
    return await db.query(
      'compras',
      where: "LOWER(forma_pago) = 'crédito' AND pagada = 0",
      orderBy: 'fecha DESC',
    );
  }

  /// Estado de Resultado: ingresos, costos, gastos en un período
  Future<Map<String, double>> obtenerEstadoResultado(String filtro) async {
    final db = await database;
    final ahora = DateTime.now();

    DateTime inicio;
    if (filtro == 'Hoy') {
      inicio = DateTime(ahora.year, ahora.month, ahora.day);
    } else if (filtro == 'Mes') {
      inicio = DateTime(ahora.year, ahora.month, 1);
    } else {
      // Año
      inicio = DateTime(ahora.year, 1, 1);
    }
    final desde = inicio.toIso8601String();

    // Total ingresos (todas las ventas: contado + crédito)
    final ingRows = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS total FROM ventas WHERE fecha >= ?
    ''', [desde]);
    final totalIngresos = (ingRows.first['total'] as num?)?.toDouble() ?? 0;

    // Total costos (compras)
    final costoRows = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS total FROM compras WHERE fecha >= ?
    ''', [desde]);
    final totalCostos = (costoRows.first['total'] as num?)?.toDouble() ?? 0;

    // Gastos operativos (módulo pendiente, por ahora 0)
    final totalGastos = 0.0;

    return {
      'total_ingresos': totalIngresos,
      'total_costos': totalCostos,
      'total_gastos': totalGastos,
      'utilidad': totalIngresos - totalCostos - totalGastos,
    };
  }

  /// Total general de compras (para dashboard)
  Future<double> obtenerTotalComprasHoy() async {
    final db = await database;
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS total
      FROM compras WHERE fecha >= ?
    ''', [inicio]);
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Total acumulado de compras
  Future<double> obtenerTotalComprasAcumulado() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(total), 0) AS total FROM compras',
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }
}