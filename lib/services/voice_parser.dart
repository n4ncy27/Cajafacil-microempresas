import '../database/database_helper.dart';

/// Resultado parseado de un comando de voz para ventas
class VoiceParseResult {
  final List<VoiceItem> items;
  final String? formaPago;
  final String? cliente;
  final String? rawText;

  VoiceParseResult({
    this.items = const [],
    this.formaPago,
    this.cliente,
    this.rawText,
  });

  bool get hasItems => items.isNotEmpty;
  bool get hasFormaPago => formaPago != null;
}

class VoiceItem {
  final int? productoId;
  final String codigo;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  double get subtotal => cantidad * precioUnitario;

  VoiceItem({
    this.productoId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  Map<String, dynamic> toMap() => {
    'producto_id': productoId,
    'codigo': codigo,
    'nombre': nombre,
    'cantidad': cantidad,
    'precio_unitario': precioUnitario,
    'subtotal': subtotal,
  };
}

/// Resultado parseado para gastos
class VoiceExpenseResult {
  final String? descripcion;
  final String? categoria;
  final double? monto;
  final String? formaPago;
  final String? rawText;

  VoiceExpenseResult({this.descripcion, this.categoria, this.monto, this.formaPago, this.rawText});
  bool get isValid => categoria != null && monto != null;
}

/// Parser para interpretar texto hablado
class VoiceParser {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Detecta la acción principal del texto: 'venta', 'compra', 'gasto' o null
  static String? detectarAccion(String texto) {
    final t = texto.toLowerCase();
    if (t.contains('vendí') || t.contains('vendi') || t.contains('vender') ||
        t.contains('venta') || t.contains('cobré') || t.contains('cobre')) {
      return 'venta';
    }
    if (t.contains('compré') || t.contains('compre') || t.contains('comprar') ||
        t.contains('compra')) {
      return 'compra';
    }
    if (t.contains('gasté') || t.contains('gaste') || t.contains('pagué') ||
        t.contains('pague') || t.contains('gasto')) {
      return 'gasto';
    }
    return null;
  }

  /// Convierte palabras numéricas a dígitos
  static int? _parsearNumero(String texto) {
    final numerosTexto = {
      'un': 1, 'uno': 1, 'una': 1,
      'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5,
      'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10,
      'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15,
      'veinte': 20, 'veinticinco': 25, 'treinta': 30,
      'cuarenta': 40, 'cincuenta': 50, 'cien': 100, 'ciento': 100,
      'doscientos': 200, 'trescientos': 300, 'quinientos': 500, 'mil': 1000,
    };
    final limpio = texto.trim().toLowerCase();
    if (numerosTexto.containsKey(limpio)) return numerosTexto[limpio];
    return int.tryParse(limpio);
  }

  /// Detecta la forma de pago en el texto
  static String? _detectarFormaPago(String texto) {
    final t = texto.toLowerCase();
    if (t.contains('efectivo') || t.contains('cash')) return 'Efectivo';
    if (t.contains('crédito') || t.contains('credito') || t.contains('fiado') || t.contains('fiar')) return 'Crédito';
    if (t.contains('transferencia') || t.contains('nequi') || t.contains('daviplata')) return 'Transferencia';
    if (t.contains('tarjeta') || t.contains('datafono') || t.contains('datáfono')) return 'Tarjeta';
    return null;
  }

  /// Parsea un comando de voz para registrar una venta.
  /// Ejemplo: "vender 2 café volcán en efectivo"
  /// Ejemplo: "vendí 50 café volcán en efectivo"
  Future<VoiceParseResult> parsearVenta(String texto) async {
    final t = texto.toLowerCase().trim();
    final formaPago = _detectarFormaPago(t);

    // Detectar cliente (después de "a nombre de" o "cliente")
    String? cliente;
    final regCliente = RegExp(r'(?:a nombre de|cliente)\s+(.+?)(?:\s+en\s+|$)', caseSensitive: false);
    final matchCliente = regCliente.firstMatch(t);
    if (matchCliente != null) {
      cliente = matchCliente.group(1)?.trim();
    }

    // Buscar patrón: [cantidad] [producto]
    final productos = await _db.obtenerProductos();
    final items = <VoiceItem>[];

    // Intentar matchear productos del inventario
    for (final prod in productos) {
      final nombre = (prod['nombre'] as String).toLowerCase();
      // Generar variantes del nombre para buscar
      final palabrasNombre = nombre.split(' ');
      // Intentar con las primeras 2-3 palabras significativas
      for (int len = palabrasNombre.length; len >= 2; len--) {
        final fragmento = palabrasNombre.take(len).join(' ');
        if (t.contains(fragmento)) {
          // Buscar cantidad antes del nombre del producto
          final idx = t.indexOf(fragmento);
          final antes = t.substring(0, idx).trim();
          final palabrasAntes = antes.split(RegExp(r'\s+'));
          int cantidad = 1;
          // Buscar el último número antes del nombre del producto
          for (int i = palabrasAntes.length - 1; i >= 0; i--) {
            final num = _parsearNumero(palabrasAntes[i]);
            if (num != null) {
              cantidad = num;
              break;
            }
          }
          items.add(VoiceItem(
            productoId: prod['id'] as int,
            codigo: prod['codigo'] as String,
            nombre: prod['nombre'] as String,
            cantidad: cantidad,
            precioUnitario: (prod['precio_venta'] as num).toDouble(),
          ));
          break; // Ya encontramos este producto, no buscar fragmentos más cortos
        }
      }
    }

    return VoiceParseResult(
      items: items,
      formaPago: formaPago,
      cliente: cliente,
      rawText: texto,
    );
  }

  /// Parsea un comando de voz para gastos.
  /// Ejemplo: "gasté 150000 en arriendo"
  /// Ejemplo: "pagué 80000 de nómina en efectivo"
  VoiceExpenseResult parsearGastoCompra(String texto) {
    final t = texto.toLowerCase().trim();
    final formaPago = _detectarFormaPago(t);
    double? monto;
    String? categoria;

    // Lista de categorías de gastos para matchear
    const categorias = {
      'arriendo': 'Arriendo',
      'alquiler': 'Arriendo',
      'renta': 'Arriendo',
      'nómina': 'Nómina',
      'nomina': 'Nómina',
      'salario': 'Nómina',
      'sueldo': 'Nómina',
      'empleado': 'Nómina',
      'seguridad social': 'Seguridad Social',
      'salud': 'Seguridad Social',
      'pensión': 'Seguridad Social',
      'pension': 'Seguridad Social',
      'eps': 'Seguridad Social',
      'internet': 'Internet',
      'wifi': 'Internet',
      'agua': 'Agua',
      'acueducto': 'Agua',
      'luz': 'Luz',
      'energía': 'Luz',
      'energia': 'Luz',
      'electricidad': 'Luz',
      'vigilancia': 'Vigilancia',
      'seguridad': 'Vigilancia',
      'aseo': 'Útiles de Aseo',
      'útiles de aseo': 'Útiles de Aseo',
      'limpieza': 'Útiles de Aseo',
    };

    // Buscar categoría en el texto
    for (final entry in categorias.entries) {
      if (t.contains(entry.key)) {
        categoria = entry.value;
        break;
      }
    }
    categoria ??= 'Otros';

    // Buscar monto numérico
    final regMonto = RegExp(r'(\d[\d.]*)\s*(?:pesos|mil|$|\s)');
    final matchMonto = regMonto.firstMatch(t);
    if (matchMonto != null) {
      final valorStr = matchMonto.group(1)!.replaceAll('.', '');
      monto = double.tryParse(valorStr);
      final despues = t.substring(matchMonto.end).trim();
      if (despues.startsWith('mil') && monto != null) {
        monto *= 1000;
      }
    }

    return VoiceExpenseResult(
      descripcion: categoria,
      categoria: categoria,
      monto: monto,
      formaPago: formaPago,
      rawText: texto,
    );
  }
}
