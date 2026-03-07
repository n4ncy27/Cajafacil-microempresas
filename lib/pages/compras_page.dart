import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../widgets/voice_listening_modal.dart';
import '../services/voice_parser.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  COMPRAS PAGE  —  Módulo completo de adquisiciones y proveedores
//  Funcionalidades:
//    • Lista con filtro Hoy / Semana / Mes y tarjetas de resumen
//    • Registrar nueva compra (manual o por voz)
//    • Registrar pago a proveedor (saldar créditos pendientes)
//    • Integración automática con inventario (aumenta stock al comprar)
// ══════════════════════════════════════════════════════════════════════════════

class ComprasPage extends StatefulWidget {
  const ComprasPage({super.key});

  @override
  State<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Filtro activo: 0=Hoy, 1=Semana, 2=Mes
  int _filtroIndex = 0;
  static const _filtros = ['Hoy', 'Semana', 'Mes'];

  List<Map<String, dynamic>> _compras = [];
  bool _cargando = true;

  // ── Resúmenes ──────────────────────────────────────────────────────────────
  double _totalGeneral = 0;
  double _totalEfectivo = 0;
  double _totalNequi = 0;
  double _totalTarjeta = 0;
  double _totalCredito = 0;

  @override
  void initState() {
    super.initState();
    _cargarCompras();
  }

  // ── Helpers de formato ─────────────────────────────────────────────────────

  static String formatearPesos(double valor) {
    final str = valor.toStringAsFixed(0);
    final buffer = StringBuffer();
    int c = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      c++;
    }
    return '\$${buffer.toString().split('').reversed.join()}';
  }

  static String formatearFechaCorta(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')} '
          '${_mesAbreviado(dt.month)} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  static String _mesAbreviado(int m) {
    const meses = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return meses[m];
  }

  // ── Carga de datos ─────────────────────────────────────────────────────────

  Future<void> _cargarCompras() async {
    setState(() => _cargando = true);
    try {
      final compras = await _db.obtenerComprasFiltradas(_filtros[_filtroIndex]);

      double total = 0, efectivo = 0, nequi = 0, tarjeta = 0, credito = 0;
      for (final c in compras) {
        final t = (c['total'] as num).toDouble();
        total += t;
        final fp = (c['forma_pago'] as String).toLowerCase();
        if (fp == 'efectivo') {
          efectivo += t;
        } else if (fp == 'nequi') {
          nequi += t;
        } else if (fp == 'tarjeta') {
          tarjeta += t;
        } else if (fp == 'crédito') {
          credito += t;
        }
      }

      setState(() {
        _compras = compras;
        _totalGeneral = total;
        _totalEfectivo = efectivo;
        _totalNequi = nequi;
        _totalTarjeta = tarjeta;
        _totalCredito = credito;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  // ── Colores por forma de pago ──────────────────────────────────────────────

  static Color bgFormaPago(String f) {
    switch (f.toLowerCase()) {
      case 'efectivo': return Colors.green.shade100;
      case 'nequi':   return Colors.blue.shade100;
      case 'tarjeta': return Colors.purple.shade100;
      case 'crédito': return Colors.orange.shade100;
      default:        return Colors.grey.shade100;
    }
  }

  static Color fgFormaPago(String f) {
    switch (f.toLowerCase()) {
      case 'efectivo': return Colors.green.shade800;
      case 'nequi':   return Colors.blue.shade800;
      case 'tarjeta': return Colors.purple.shade800;
      case 'crédito': return Colors.orange.shade800;
      default:        return Colors.grey.shade800;
    }
  }

  // ── Abrir sheet nueva compra ───────────────────────────────────────────────

  void _abrirNuevaCompra({Map<String, dynamic>? prerellenado}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NuevaCompraSheet(
        db: _db,
        prerellenado: prerellenado,
        onGuardado: _cargarCompras,
      ),
    );
  }

  // ── Input por voz ─────────────────────────────────────────────────────────

  Future<void> _registrarPorVoz() async {
    final texto = await VoiceListeningModal.show(
      context,
      titulo: 'Dicta tu compra',
      ejemplo: '"Compré 100 Café Volcán a 11460 en efectivo"',
      color: const Color(0xFF3366FF),
    );
    if (texto == null || texto.isEmpty) return;

    final parser = VoiceParser();
    final resultado = parser.parsearGastoCompra(texto);

    if (!mounted) return;

    // Si el parser detectó datos suficientes, pre-rellenar el formulario
    if (resultado.isValid) {
      _abrirNuevaCompra(prerellenado: {
        'descripcion': resultado.descripcion,
        'monto': resultado.monto,
        'rawText': resultado.rawText,
      });
    } else {
      // Abrir igual para que el usuario complete manualmente
      _abrirNuevaCompra(prerellenado: {'rawText': texto});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voz recibida: "$texto" — completa los datos restantes',
            style: GoogleFonts.montserrat(fontSize: 13),
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Abrir pago a proveedor ─────────────────────────────────────────────────

  void _abrirPagoProveedor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PagoProveedorSheet(
        db: _db,
        onGuardado: _cargarCompras,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      // ── AppBar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF3366FF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compras',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700, fontSize: 20)),
            Text('Adquisiciones y proveedores',
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          // Botón pago proveedor en AppBar
          TextButton.icon(
            onPressed: _abrirPagoProveedor,
            icon: const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white, size: 18),
            label: Text('Pagar',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 13)),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _cargarCompras,
        color: const Color(0xFF3366FF),
        child: CustomScrollView(
          slivers: [
            // ── Filtros Hoy / Semana / Mes ──────────────────────────────────
            SliverToBoxAdapter(child: _buildFiltros()),

            // ── Tarjetas de resumen ─────────────────────────────────────────
            SliverToBoxAdapter(child: _buildResumen()),

            // ── Lista de compras ────────────────────────────────────────────
            if (_cargando)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_compras.isEmpty)
              SliverFillRemaining(child: _buildVacia())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildItemCompra(_compras[i]),
                  childCount: _compras.length,
                ),
              ),

            // Espacio inferior para el FAB
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botón voz secundario
          FloatingActionButton.small(
            heroTag: 'voice_compras',
            onPressed: _registrarPorVoz,
            backgroundColor: const Color(0xFF1A2A5E),
            child: const Icon(Icons.mic, color: Colors.amberAccent, size: 20),
          ),
          const SizedBox(height: 10),
          // Botón nueva compra principal
          FloatingActionButton(
            heroTag: 'nueva_compra',
            onPressed: _abrirNuevaCompra,
            backgroundColor: const Color(0xFF3366FF),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Widget filtros ─────────────────────────────────────────────────────────

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: List.generate(_filtros.length, (i) {
            final activo = _filtroIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _filtroIndex = i);
                  _cargarCompras();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: activo
                        ? const Color(0xFF3366FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _filtros[i],
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: activo ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Widget tarjetas de resumen ─────────────────────────────────────────────

  Widget _buildResumen() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila 1: Total (ancho completo)
          SizedBox(
            width: double.infinity,
            child: _tarjetaResumen('Total', _totalGeneral,
                const Color(0xFF3366FF), Colors.white),
          ),
          const SizedBox(height: 8),
          // Fila 2: Efectivo · Nequi
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _tarjetaResumen('Efectivo', _totalEfectivo,
                    Colors.green.shade50, Colors.green.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _tarjetaResumen('Nequi', _totalNequi,
                    Colors.blue.shade50, Colors.blue.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Fila 3: Tarjeta · Crédito
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _tarjetaResumen('Tarjeta', _totalTarjeta,
                    Colors.purple.shade50, Colors.purple.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _tarjetaResumen('Crédito', _totalCredito,
                    Colors.orange.shade50, Colors.orange.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaResumen(
      String label, double valor, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: fg.withOpacity(0.8),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatearPesos(valor),
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget ítem de compra ──────────────────────────────────────────────────

  Widget _buildItemCompra(Map<String, dynamic> compra) {
    final formaPago = compra['forma_pago'] as String;
    final total = (compra['total'] as num).toDouble();
    final proveedor = compra['proveedor'] as String? ?? 'Proveedor';
    final producto = compra['nombre_producto'] as String? ?? 'Producto';
    final cantidad = compra['cantidad'] as int? ?? 0;
    final fechaStr = compra['fecha'] as String;
    final pagada = (compra['pagada'] as int? ?? 0) == 1;
    final esCredito = formaPago.toLowerCase() == 'crédito';

    // Etiqueta de estado
    String etiqueta = formaPago;
    if (esCredito) etiqueta = pagada ? 'Pagado' : 'Pendiente';

    Color bgEtiqueta = bgFormaPago(formaPago);
    Color fgEtiqueta = fgFormaPago(formaPago);
    if (esCredito && pagada) {
      bgEtiqueta = Colors.green.shade100;
      fgEtiqueta = Colors.green.shade800;
    }

    return GestureDetector(
      // Todos los ítems abren el diálogo de detalle al tocar
      onTap: () => _mostrarDetalleCompra(compra),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
          border: esCredito && !pagada
              ? Border.all(color: Colors.orange.shade200)
              : null,
        ),
        child: Row(
          children: [
            // Ícono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.coffee_outlined,
                  color: Color(0xFF3366FF), size: 20),
            ),
            const SizedBox(width: 12),
            // Descripción
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$producto × $cantidad',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$proveedor · ${formatearFechaCorta(fechaStr)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Total + etiqueta
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatearPesos(total),
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF3366FF)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgEtiqueta,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    etiqueta,
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: fgEtiqueta),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Diálogo de detalle de compra ───────────────────────────────────────────

  void _mostrarDetalleCompra(Map<String, dynamic> compra) {
    final formaPago = compra['forma_pago'] as String;
    final total = (compra['total'] as num).toDouble();
    final proveedor = compra['proveedor'] as String? ?? '—';
    final producto = compra['nombre_producto'] as String? ?? '—';
    final cantidad = compra['cantidad'] as int? ?? 0;
    final precioUnitario = (compra['precio_unitario'] as num?)?.toDouble() ?? 0;
    final fechaStr = compra['fecha'] as String;
    final pagada = (compra['pagada'] as int? ?? 0) == 1;
    final esCredito = formaPago.toLowerCase() == 'crédito';
    final fechaPago = compra['fecha_pago'] as String?;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera azul
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                color: Color(0xFF3366FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.coffee_outlined,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          producto,
                          style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatearPesos(total),
                    style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 26),
                  ),
                ],
              ),
            ),

            // Cuerpo con datos
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                children: [
                  _filaDetalle('Proveedor', proveedor),
                  _filaDetalle('Cantidad', '$cantidad unidades'),
                  _filaDetalle('Precio unitario', formatearPesos(precioUnitario)),
                  _filaDetalle('Fecha compra', formatearFechaCorta(fechaStr)),
                  _filaDetalle(
                    'Forma de pago',
                    esCredito
                        ? (pagada
                            ? 'Crédito — Pagado${fechaPago != null ? '\n${formatearFechaCorta(fechaPago)}' : ''}'
                            : 'Crédito — Pendiente')
                        : formaPago,
                    destacar: esCredito && !pagada,
                  ),
                ],
              ),
            ),

            // Botón pagar (solo crédito pendiente)
            if (esCredito && !pagada)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.account_balance_wallet_outlined,
                        size: 18, color: Colors.white),
                    label: Text('Registrar pago',
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3366FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _abrirPagoProveedorConCompra(compra);
                    },
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _filaDetalle(String label, String valor, {bool destacar = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: Colors.grey.shade500)),
          ),
          Expanded(
            child: Text(
              valor,
              style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: destacar ? Colors.orange.shade700 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget pantalla vacía ──────────────────────────────────────────────────

  Widget _buildVacia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Sin compras ${_filtros[_filtroIndex].toLowerCase()}',
            style: GoogleFonts.montserrat(
                fontSize: 15, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca + para registrar una compra',
            style: GoogleFonts.montserrat(
                fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Abrir pago con compra preseleccionada ──────────────────────────────────

  void _abrirPagoProveedorConCompra(Map<String, dynamic> compra) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PagoProveedorSheet(
        db: _db,
        compraPreseleccionada: compra,
        onGuardado: _cargarCompras,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHEET: NUEVA COMPRA
//  Permite registrar una compra manual o con datos pre-llenados por voz.
//  Al guardar: inserta en tabla `compras` y aumenta stock en `inventario`.
// ══════════════════════════════════════════════════════════════════════════════

class _NuevaCompraSheet extends StatefulWidget {
  final DatabaseHelper db;
  final Map<String, dynamic>? prerellenado;
  final VoidCallback onGuardado;

  const _NuevaCompraSheet({
    required this.db,
    required this.onGuardado,
    this.prerellenado,
  });

  @override
  State<_NuevaCompraSheet> createState() => _NuevaCompraSheetState();
}

class _NuevaCompraSheetState extends State<_NuevaCompraSheet> {
  final _proveedorCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  List<Map<String, dynamic>> _productos = [];
  // Guardamos solo el id para evitar el error de comparación de Maps en el Dropdown
  int? _productoSeleccionadoId;
  // Referencia al map completo, buscada por id cada vez que cambia la selección
  Map<String, dynamic>? get _productoSeleccionado => _productoSeleccionadoId == null
      ? null
      : _productos.firstWhere(
          (p) => p['id'] == _productoSeleccionadoId,
          orElse: () => <String, dynamic>{},
        );
  String _formaPago = 'Efectivo';
  bool _guardando = false;

  static const _formasPago = ['Efectivo', 'Nequi', 'Tarjeta', 'Crédito'];

  double get _total {
    final cant = int.tryParse(_cantidadCtrl.text) ?? 0;
    final precio =
        double.tryParse(_precioCtrl.text.replaceAll('.', '')) ?? 0;
    return cant * precio;
  }

  @override
  void initState() {
    super.initState();
    _cargarProductos();

    // Pre-rellenar desde voz si aplica
    final pre = widget.prerellenado;
    if (pre != null) {
      if (pre['monto'] != null) {
        _precioCtrl.text =
            (pre['monto'] as double).toStringAsFixed(0);
      }
      if (pre['descripcion'] != null) {
        _proveedorCtrl.text = pre['descripcion'] as String;
      }
    }
  }

  @override
  void dispose() {
    _proveedorCtrl.dispose();
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    final prods = await widget.db.obtenerProductos();
    setState(() => _productos = prods);
  }

  Future<void> _guardar() async {
    // Validaciones
    final proveedor = _proveedorCtrl.text.trim();
    final cantidadStr = _cantidadCtrl.text.trim();
    final precioStr = _precioCtrl.text.trim().replaceAll('.', '');

    if (proveedor.isEmpty) {
      _mostrarError('Ingresa el nombre del proveedor');
      return;
    }
    if (_productoSeleccionadoId == null || (_productoSeleccionado?.isEmpty ?? true)) {
      _mostrarError('Selecciona un producto del inventario');
      return;
    }
    if (cantidadStr.isEmpty || int.tryParse(cantidadStr) == null || int.parse(cantidadStr) <= 0) {
      _mostrarError('Ingresa una cantidad válida');
      return;
    }
    if (precioStr.isEmpty || double.tryParse(precioStr) == null || double.parse(precioStr) <= 0) {
      _mostrarError('Ingresa un precio unitario válido');
      return;
    }

    setState(() => _guardando = true);

    try {
      final cantidad = int.parse(cantidadStr);
      final precioUnitario = double.parse(precioStr);
      final total = cantidad * precioUnitario;
      final prod = _productoSeleccionado!;
      final productoId = prod['id'] as int;
      final codigoProducto = prod['codigo'] as String;

      await widget.db.registrarCompra(
        proveedor: proveedor,
        productoId: productoId,
        codigoProducto: codigoProducto,
        nombreProducto: prod['nombre'] as String,
        cantidad: cantidad,
        precioUnitario: precioUnitario,
        total: total,
        formaPago: _formaPago,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onGuardado();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Compra registrada — stock actualizado ✓',
              style: GoogleFonts.montserrat(fontSize: 13),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _guardando = false);
      _mostrarError('Error al guardar: $e');
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.montserrat(fontSize: 13)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nueva Compra',
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700, fontSize: 20)),
                    Text('Manual o por voz',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const Spacer(),
                // Botón voz desde el sheet
                _BotonVoz(
                  onTextoReconocido: (texto) {
                    final parser = VoiceParser();
                    final res = parser.parsearGastoCompra(texto);
                    if (res.monto != null) {
                      _precioCtrl.text = res.monto!.toStringAsFixed(0);
                    }
                    if (res.descripcion != null) {
                      _proveedorCtrl.text = res.descripcion!;
                    }
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Contenido desplazable
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── PROVEEDOR ────────────────────────────────────────────
                  _seccionLabel('PROVEEDOR'),
                  _campo(
                    label: 'Nombre',
                    controller: _proveedorCtrl,
                    hint: 'Ej: Café del Sur S.A.S',
                  ),
                  const SizedBox(height: 16),

                  // ── PRODUCTO ─────────────────────────────────────────────
                  _seccionLabel('PRODUCTO'),
                  const SizedBox(height: 8),

                  // Dropdown productos del inventario
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _productoSeleccionadoId,
                        isExpanded: true,
                        hint: Text('Seleccionar producto',
                            style: GoogleFonts.montserrat(
                                fontSize: 13, color: Colors.grey.shade400)),
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: Colors.black87),
                        items: _productos
                            .map((p) => DropdownMenuItem<int>(
                                  value: p['id'] as int,
                                  child: Text(p['nombre'] as String,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (id) {
                          setState(() {
                            _productoSeleccionadoId = id;
                            // Pre-rellenar precio de compra del inventario
                            final p = _productoSeleccionado;
                            if (p != null && p.isNotEmpty) {
                              final pc = (p['precio_compra'] as num).toDouble();
                              if (pc > 0) {
                                _precioCtrl.text = pc.toStringAsFixed(0);
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cantidad y precio
                  Row(
                    children: [
                      Expanded(
                        child: _campo(
                          label: 'Cantidad',
                          controller: _cantidadCtrl,
                          hint: '0',
                          teclado: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _campo(
                          label: 'Precio unitario',
                          controller: _precioCtrl,
                          hint: '\$0',
                          teclado: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Total calculado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text('Total',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(
                          _ComprasPageState.formatearPesos(_total),
                          style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3366FF)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── FORMA DE PAGO ─────────────────────────────────────────
                  _seccionLabel('FORMA DE PAGO'),
                  const SizedBox(height: 10),
                  _selectorFormaPago(),
                  const SizedBox(height: 8),

                  // Aviso crédito
                  if (_formaPago == 'Crédito')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta compra quedará como deuda pendiente con el proveedor.',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── BOTÓN GUARDAR ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3366FF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              'Registrar Compra',
                              style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────

  Widget _seccionLabel(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto,
            style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.5)),
      );

  Widget _campo({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? teclado,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: GoogleFonts.montserrat(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.montserrat(fontSize: 13, color: Colors.grey.shade600),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF3366FF), width: 1.5)),
      ),
    );
  }

  Widget _selectorFormaPago() {
    return Row(
      children: _formasPago.map((f) {
        final sel = _formaPago == f;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _formaPago = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                  right: f == _formasPago.last ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF3366FF) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel
                      ? const Color(0xFF3366FF)
                      : Colors.grey.shade300,
                ),
              ),
              alignment: Alignment.center,
              child: Text(f,
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : Colors.grey.shade700)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHEET: PAGO A PROVEEDOR
//  Muestra las compras a crédito pendientes y permite registrar el pago.
//  Al pagar: marca la compra como 'pagada' en la tabla `compras`.
// ══════════════════════════════════════════════════════════════════════════════

class _PagoProveedorSheet extends StatefulWidget {
  final DatabaseHelper db;
  final Map<String, dynamic>? compraPreseleccionada;
  final VoidCallback onGuardado;

  const _PagoProveedorSheet({
    required this.db,
    required this.onGuardado,
    this.compraPreseleccionada,
  });

  @override
  State<_PagoProveedorSheet> createState() => _PagoProveedorSheetState();
}

class _PagoProveedorSheetState extends State<_PagoProveedorSheet> {
  List<Map<String, dynamic>> _comprasPendientes = [];
  // Igual que en NuevaCompra: usamos el id como valor del dropdown para evitar crash
  int? _compraSeleccionadaId;
  Map<String, dynamic>? get _compraSeleccionada => _compraSeleccionadaId == null
      ? null
      : _comprasPendientes.firstWhere(
          (c) => c['id'] == _compraSeleccionadaId,
          orElse: () => <String, dynamic>{},
        );

  String _formaPago = 'Nequi';
  DateTime _fechaPago = DateTime.now();
  bool _cargando = true;
  bool _guardando = false;

  static const _formasPago = ['Efectivo', 'Nequi', 'Tarjeta'];

  double get _saldoPendiente {
    final c = _compraSeleccionada;
    if (c == null || c.isEmpty) return 0;
    return (c['total'] as num).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _cargarPendientes();
  }

  Future<void> _cargarPendientes() async {
    final pendientes = await widget.db.obtenerComprasPendientes();
    setState(() {
      _comprasPendientes = pendientes;
      _cargando = false;
      // Pre-seleccionar por id si viene de un ítem en la lista
      if (widget.compraPreseleccionada != null) {
        final id = widget.compraPreseleccionada!['id'];
        if (id != null) _compraSeleccionadaId = id as int;
      }
    });
  }

  Future<void> _registrarPago() async {
    final compra = _compraSeleccionada;
    if (compra == null || compra.isEmpty) return;
    setState(() => _guardando = true);

    try {
      await widget.db.registrarPagoProveedor(
        compraId: compra['id'] as int,
        fechaPago: _fechaPago,
        formaPago: _formaPago,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onGuardado();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pago registrado — deuda saldada ✓',
              style: GoogleFonts.montserrat(fontSize: 13),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e',
              style: GoogleFonts.montserrat(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaPago,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'CO'),
    );
    if (picked != null) setState(() => _fechaPago = picked);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final saldado = _saldoPendiente == 0 && _compraSeleccionada != null;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pago a Proveedor',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700, fontSize: 20)),
                Text('Registrar pago de deuda',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),

          const Divider(height: 24),

          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _comprasPendientes.isEmpty && _compraSeleccionada == null
                    ? _buildSinPendientes()
                    : SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── DEUDA PENDIENTE ─────────────────────────────
                            _seccionLabel('DEUDA PENDIENTE'),
                            Text('Compra a crédito',
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey.shade500)),
                            const SizedBox(height: 8),

                            // Dropdown compras pendientes
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FF),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _compraSeleccionadaId,
                                  isExpanded: true,
                                  hint: Text('Seleccionar compra',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          color: Colors.grey.shade400)),
                                  style: GoogleFonts.montserrat(
                                      fontSize: 13, color: Colors.black87),
                                  items: _comprasPendientes
                                      .map((c) => DropdownMenuItem<int>(
                                            value: c['id'] as int,
                                            child: Text(
                                              '#${(c['id'] as int).toString().padLeft(3, '0')} · ${c['nombre_producto']} · ${_ComprasPageState.formatearPesos((c['total'] as num).toDouble())}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (id) =>
                                      setState(() => _compraSeleccionadaId = id),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Tarjeta saldo proveedor
                            if (_compraSeleccionada != null && _compraSeleccionada!.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.red.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('SALDO CON PROVEEDOR',
                                        style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red.shade400,
                                            letterSpacing: 0.5)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _ComprasPageState
                                          .formatearPesos(_saldoPendiente),
                                      style: GoogleFonts.montserrat(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.red.shade700),
                                    ),
                                    Text(
                                      '${_compraSeleccionada!['proveedor']} · '
                                      '${_ComprasPageState.formatearFechaCorta(_compraSeleccionada!['fecha'] as String)}',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 11,
                                          color: Colors.red.shade400),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── PAGO ──────────────────────────────────────
                              _seccionLabel('PAGO'),

                              // Valor (fijo: el total de la deuda)
                              _campoLectura(
                                label: 'Valor',
                                valor: _ComprasPageState
                                    .formatearPesos(_saldoPendiente),
                              ),
                              const SizedBox(height: 12),

                              // Fecha
                              GestureDetector(
                                onTap: _seleccionarFecha,
                                child: _campoLectura(
                                  label: 'Fecha',
                                  valor:
                                      '${_fechaPago.day.toString().padLeft(2, '0')}/${_fechaPago.month.toString().padLeft(2, '0')}/${_fechaPago.year}',
                                  icono: Icons.calendar_today_outlined,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Forma de pago
                              Text('Forma de pago',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              _selectorFormaPago(),
                              const SizedBox(height: 16),

                              // Resultado
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.green.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('RESULTADO',
                                        style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.green.shade600,
                                            letterSpacing: 0.5)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Deuda saldada — \$0 pendiente',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Botón registrar pago
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed:
                                      _guardando ? null : _registrarPago,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF3366FF),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: _guardando
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5))
                                      : Text(
                                          'Registrar Pago',
                                          style: GoogleFonts.montserrat(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15),
                                        ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinPendientes() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: Colors.green.shade300),
          const SizedBox(height: 12),
          Text(
            '¡Sin deudas pendientes!',
            style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            'Todas las compras a crédito están saldadas',
            style: GoogleFonts.montserrat(
                fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _seccionLabel(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto,
            style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.5)),
      );

  Widget _campoLectura(
      {required String label, required String valor, IconData? icono}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(valor,
                  style: GoogleFonts.montserrat(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          if (icono != null)
            Icon(icono, size: 18, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _selectorFormaPago() {
    return Row(
      children: _formasPago.map((f) {
        final sel = _formaPago == f;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _formaPago = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                  right: f == _formasPago.last ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color:
                    sel ? const Color(0xFF3366FF) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel
                      ? const Color(0xFF3366FF)
                      : Colors.grey.shade300,
                ),
              ),
              alignment: Alignment.center,
              child: Text(f,
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : Colors.grey.shade700)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WIDGET AUXILIAR: Botón de voz compacto reutilizable dentro de sheets
// ══════════════════════════════════════════════════════════════════════════════

class _BotonVoz extends StatelessWidget {
  final void Function(String texto) onTextoReconocido;

  const _BotonVoz({required this.onTextoReconocido});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final texto = await VoiceListeningModal.show(
          context,
          titulo: 'Dicta tu compra',
          ejemplo: '"Compré 100 Volcán a 11460"',
          color: const Color(0xFF3366FF),
        );
        if (texto != null && texto.isNotEmpty) {
          onTextoReconocido(texto);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A5E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, color: Colors.amberAccent, size: 16),
            const SizedBox(width: 6),
            Text('Registrar por Voz',
                style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}