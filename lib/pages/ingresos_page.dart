import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../widgets/voice_listening_modal.dart';
import '../services/voice_parser.dart';

class IngresosPage extends StatefulWidget {
  const IngresosPage({super.key});

  @override
  State<IngresosPage> createState() => _IngresosPageState();
}

class _IngresosPageState extends State<IngresosPage>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late TabController _tabController;
  List<Map<String, dynamic>> _ventas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarVentas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarVentas() async {
    setState(() => _cargando = true);
    try {
      final ventas = await _db.obtenerVentas();
      setState(() {
        _ventas = ventas;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  String _formatearFecha(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _formatearPesos(double valor) {
    final str = valor.toStringAsFixed(0);
    final buffer = StringBuffer();
    int contador = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (contador > 0 && contador % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      contador++;
    }
    return '\$${buffer.toString().split('').reversed.join()}';
  }

  Color _colorFormaPago(String forma) {
    switch (forma.toLowerCase()) {
      case 'efectivo': return Colors.green.shade100;
      case 'crédito': return Colors.orange.shade100;
      case 'transferencia': return Colors.blue.shade100;
      case 'tarjeta': return Colors.purple.shade100;
      default: return Colors.grey.shade100;
    }
  }

  Color _colorTextoFormaPago(String forma) {
    switch (forma.toLowerCase()) {
      case 'efectivo': return Colors.green.shade800;
      case 'crédito': return Colors.orange.shade800;
      case 'transferencia': return Colors.blue.shade800;
      case 'tarjeta': return Colors.purple.shade800;
      default: return Colors.grey.shade800;
    }
  }

  void _abrirSeleccionProductos() {
    final carrito = <Map<String, dynamic>>[];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModalSeleccionProductos(
        db: _db,
        carrito: carrito,
        formatearPesos: _formatearPesos,
        onConfirmar: (carritoFinal) {
          Navigator.pop(context);
          _abrirConfirmacion(carritoFinal);
        },
      ),
    );
  }

  void _abrirConfirmacion(List<Map<String, dynamic>> carrito) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModalConfirmacion(
        db: _db,
        carrito: carrito,
        formatearPesos: _formatearPesos,
        onGuardado: _cargarVentas,
        onVolverAtras: () {
          Navigator.pop(context);
          _abrirSeleccionProductos();
        },
      ),
    );
  }

  void _verDetalle(Map<String, dynamic> venta) async {
    final detalles = await _db.obtenerDetalleVenta(venta['id']);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text('Venta #${venta['id'].toString().padLeft(3, '0')}',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _colorFormaPago(venta['forma_pago']),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(venta['forma_pago'],
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: _colorTextoFormaPago(venta['forma_pago']),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatearFecha(venta['fecha']),
                  style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
              if (venta['cliente'] != null && venta['cliente'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Cliente: ${venta['cliente']}',
                      style: GoogleFonts.montserrat(fontSize: 12)),
                ),
              const Divider(height: 16),
              Text('Productos:',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              ...detalles.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${d['nombre']} x${d['cantidad']}',
                              style: GoogleFonts.montserrat(fontSize: 13)),
                        ),
                        Text(_formatearPesos((d['subtotal'] as num).toDouble()),
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  )),
              const Divider(height: 16),
              Row(
                children: [
                  Text('TOTAL',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(_formatearPesos((venta['total'] as num).toDouble()),
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: const Color(0xFF3366FF))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: GoogleFonts.montserrat()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _confirmarEliminarVenta(venta['id']);
            },
            child: Text('Eliminar',
                style: GoogleFonts.montserrat(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminarVenta(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar venta',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        content: Text(
            'Se eliminará la venta y el stock se restaurará automáticamente. ¿Continuar?',
            style: GoogleFonts.montserrat()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.montserrat()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _db.eliminarVenta(id);
              if (mounted) Navigator.pop(context);
              _cargarVentas();
            },
            child: Text('Eliminar',
                style: GoogleFonts.montserrat(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _registrarPorVoz() async {
    final texto = await VoiceListeningModal.show(
      context,
      titulo: 'Dicta tu venta',
      ejemplo: '"Vendí 2 Café Volcán en efectivo"',
      color: const Color(0xFF3366FF),
    );
    if (texto == null || texto.isEmpty || !mounted) return;

    final parser = VoiceParser();
    final resultado = await parser.parsearVenta(texto);

    if (!mounted) return;

    if (!resultado.hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontraron productos en: "$texto"',
              style: GoogleFonts.montserrat(fontSize: 13)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _mostrarConfirmacionVoz(resultado);
  }

  void _mostrarConfirmacionVoz(VoiceParseResult resultado) {
    String formaPagoSeleccionada = resultado.formaPago ?? 'Efectivo';
    final clienteCtrl = TextEditingController(text: resultado.cliente ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final total = resultado.items.fold<double>(0, (s, i) => s + i.subtotal);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.mic, color: Color(0xFF3366FF), size: 22),
                const SizedBox(width: 8),
                Text('Confirmar venta por voz',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('"${resultado.rawText}"',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                  ),
                  const SizedBox(height: 12),
                  Text('Productos:',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...resultado.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.nombre} x${item.cantidad}',
                              style: GoogleFonts.montserrat(fontSize: 13)),
                        ),
                        Text(_formatearPesos(item.subtotal),
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  )),
                  const Divider(height: 16),
                  Text('Forma de pago:',
                      style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: ['Efectivo', 'Crédito', 'Transferencia', 'Tarjeta']
                        .map((fp) => ChoiceChip(
                              label: Text(fp,
                                  style: GoogleFonts.montserrat(fontSize: 11)),
                              selected: formaPagoSeleccionada == fp,
                              selectedColor: const Color(0xFF3366FF).withValues(alpha: 0.2),
                              onSelected: (_) =>
                                  setDialogState(() => formaPagoSeleccionada = fp),
                            ))
                        .toList(),
                  ),
                  if (formaPagoSeleccionada == 'Crédito') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: clienteCtrl,
                      decoration: InputDecoration(
                        labelText: 'Cliente',
                        labelStyle: GoogleFonts.montserrat(fontSize: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    children: [
                      Text('TOTAL',
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(_formatearPesos(total),
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: const Color(0xFF3366FF))),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: GoogleFonts.montserrat()),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3366FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final items = resultado.items.map((i) => i.toMap()).toList();
                  await _db.registrarVenta(
                    formaPago: formaPagoSeleccionada,
                    tipo: formaPagoSeleccionada == 'Crédito' ? 'crédito' : 'contado',
                    items: items,
                    cliente: clienteCtrl.text.isNotEmpty ? clienteCtrl.text : null,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    _cargarVentas();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Venta registrada por voz',
                            style: GoogleFonts.montserrat(fontSize: 13)),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                label: Text('Confirmar',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text('Ingresos',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF3366FF),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Ventas'), Tab(text: 'Abonos')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_vistaVentas(), _vistaAbonos()],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'voice_ingresos',
            onPressed: _registrarPorVoz,
            backgroundColor: const Color(0xFF1A2A5E),
            child: const Icon(Icons.mic, color: Colors.amberAccent),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'nueva_venta',
            onPressed: _abrirSeleccionProductos,
            backgroundColor: const Color(0xFF3366FF),
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            label: Text('Nueva venta',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _vistaVentas() {
    if (_cargando) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF3366FF)));
    }
    if (_ventas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No hay ventas registradas',
                style: GoogleFonts.montserrat(fontSize: 15, color: Colors.grey)),
          ],
        ),
      );
    }

    final hoy = DateTime.now();
    final ventasHoy = _ventas.where((v) {
      final f = DateTime.parse(v['fecha']);
      return f.day == hoy.day && f.month == hoy.month && f.year == hoy.year;
    }).toList();
    final totalHoy =
        ventasHoy.fold<double>(0, (s, v) => s + (v['total'] as num).toDouble());

    return Column(
      children: [
        // Resumen del día
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3366FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ventas de hoy',
                      style: GoogleFonts.montserrat(
                          color: Colors.white70, fontSize: 12)),
                  Text(_formatearPesos(totalHoy),
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Transacciones',
                      style: GoogleFonts.montserrat(
                          color: Colors.white70, fontSize: 12)),
                  Text('${ventasHoy.length}',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22)),
                ],
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _ventas.length,
            itemBuilder: (context, index) {
              final v = _ventas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEEF2FF),
                    child: Text(
                      '#${v['id'].toString().padLeft(2, '0')}',
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: const Color(0xFF3366FF),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          v['cliente'] != null &&
                                  v['cliente'].toString().isNotEmpty
                              ? v['cliente']
                              : 'Venta directa',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _colorFormaPago(v['forma_pago']),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(v['forma_pago'],
                            style: GoogleFonts.montserrat(
                                fontSize: 10,
                                color: _colorTextoFormaPago(v['forma_pago']),
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatearFecha(v['fecha']),
                          style: GoogleFonts.montserrat(
                              fontSize: 11, color: Colors.grey)),
                      Text(_formatearPesos((v['total'] as num).toDouble()),
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF3366FF))),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _verDetalle(v),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _vistaAbonos() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Selecciona una venta a crédito\npara registrar abonos',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.montserrat(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3366FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _tabController.animateTo(0),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            label: Text('Ver ventas',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Modal 1: Selección de productos ─────────────────────────────────────────

class _ModalSeleccionProductos extends StatefulWidget {
  final DatabaseHelper db;
  final List<Map<String, dynamic>> carrito;
  final String Function(double) formatearPesos;
  final void Function(List<Map<String, dynamic>>) onConfirmar;

  const _ModalSeleccionProductos({
    required this.db,
    required this.carrito,
    required this.formatearPesos,
    required this.onConfirmar,
  });

  @override
  State<_ModalSeleccionProductos> createState() =>
      _ModalSeleccionProductosState();
}

class _ModalSeleccionProductosState extends State<_ModalSeleccionProductos> {
  List<Map<String, dynamic>> _todos = [];
  List<Map<String, dynamic>> _filtrados = [];
  late List<Map<String, dynamic>> _carrito;
  final TextEditingController _buscarCtrl = TextEditingController();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _carrito = List.from(widget.carrito);
    _cargarProductos();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    final productos = await widget.db.obtenerProductos();
    setState(() {
      _todos = productos;
      _filtrados = productos;
      _cargando = false;
    });
  }

  void _filtrar(String q) {
    setState(() {
      _filtrados = q.isEmpty
          ? _todos
          : _todos
              .where((p) =>
                  p['nombre'].toString().toLowerCase().contains(q.toLowerCase()) ||
                  p['codigo'].toString().toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  int _cantidadEnCarrito(int productoId) {
    final idx = _carrito.indexWhere((i) => i['producto_id'] == productoId);
    return idx >= 0 ? _carrito[idx]['cantidad'] as int : 0;
  }

  void _agregar(Map<String, dynamic> producto) {
    final stock = (producto['cantidad'] as num).toInt();
    final idx = _carrito.indexWhere((i) => i['producto_id'] == producto['id']);
    if (idx >= 0) {
      if (_carrito[idx]['cantidad'] < stock) {
        setState(() => _carrito[idx]['cantidad']++);
        _recalcular(idx);
      }
    } else {
      if (stock > 0) {
        setState(() {
          _carrito.add({
            'producto_id': producto['id'],
            'codigo': producto['codigo'],
            'nombre': producto['nombre'],
            'cantidad': 1,
            'precio_unitario': (producto['precio_venta'] as num).toDouble(),
            'subtotal': (producto['precio_venta'] as num).toDouble(),
          });
        });
      }
    }
  }

  void _quitar(Map<String, dynamic> producto) {
    final idx = _carrito.indexWhere((i) => i['producto_id'] == producto['id']);
    if (idx >= 0) {
      setState(() {
        if (_carrito[idx]['cantidad'] > 1) {
          _carrito[idx]['cantidad']--;
          _recalcular(idx);
        } else {
          _carrito.removeAt(idx);
        }
      });
    }
  }

  void _recalcular(int idx) {
    _carrito[idx]['subtotal'] =
        _carrito[idx]['cantidad'] * _carrito[idx]['precio_unitario'];
  }

  int get _totalItems =>
      _carrito.fold(0, (s, i) => s + (i['cantidad'] as int));

  double get _totalPesos =>
      _carrito.fold(0, (s, i) => s + (i['subtotal'] as double));

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F4F7),
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
                Text('Seleccionar productos',
                    style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3366FF))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _buscarCtrl,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                hintStyle: GoogleFonts.montserrat(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Tabla de productos
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF3366FF)))
                : _filtrados.isEmpty
                    ? Center(
                        child: Text('Sin resultados',
                            style: GoogleFonts.montserrat(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtrados.length,
                        itemBuilder: (context, i) {
                          final p = _filtrados[i];
                          final stock = (p['cantidad'] as num).toInt();
                          final enCarrito = _cantidadEnCarrito(p['id'] as int);
                          final sinStock = stock == 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: sinStock
                                ? Colors.grey.shade100
                                : enCarrito > 0
                                    ? const Color(0xFFF0F4FF)
                                    : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  // Info del producto
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p['nombre'],
                                            style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: sinStock
                                                    ? Colors.grey
                                                    : Colors.black87)),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(p['codigo'],
                                                style: GoogleFonts.montserrat(
                                                    fontSize: 11,
                                                    color: Colors.grey)),
                                            const SizedBox(width: 8),
                                            Text(
                                              widget.formatearPesos((p['precio_venta'] as num).toDouble()),
                                              style: GoogleFonts.montserrat(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF3366FF)),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: sinStock
                                                    ? Colors.red.shade100
                                                    : stock <= (p['stock_minimo'] as num).toInt()
                                                        ? Colors.orange.shade100
                                                        : Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                sinStock ? 'Sin stock' : 'Stock: $stock',
                                                style: GoogleFonts.montserrat(
                                                    fontSize: 10,
                                                    color: sinStock
                                                        ? Colors.red.shade800
                                                        : stock <= (p['stock_minimo'] as num).toInt()
                                                            ? Colors.orange.shade800
                                                            : Colors.green.shade800,
                                                    fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Controles cantidad
                                  if (!sinStock)
                                    Row(
                                      children: [
                                        if (enCarrito > 0) ...[
                                          GestureDetector(
                                            onTap: () => _quitar(p),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.remove, size: 16),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: Text('$enCarrito',
                                                style: GoogleFonts.montserrat(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15)),
                                          ),
                                        ],
                                        GestureDetector(
                                          onTap: () => _agregar(p),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3366FF),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.add,
                                                size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (sinStock)
                                    Icon(Icons.block,
                                        color: Colors.grey.shade400, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Botón ver carrito
          if (_carrito.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              color: Colors.white,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3366FF),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => widget.onConfirmar(_carrito),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_checkout,
                        color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'Ver carrito  ($_totalItems ${_totalItems == 1 ? 'producto' : 'productos'})  •  ${widget.formatearPesos(_totalPesos)}',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Modal 2: Confirmación de venta ───────────────────────────────────────────

class _ModalConfirmacion extends StatefulWidget {
  final DatabaseHelper db;
  final List<Map<String, dynamic>> carrito;
  final String Function(double) formatearPesos;
  final VoidCallback onGuardado;
  final VoidCallback onVolverAtras;

  const _ModalConfirmacion({
    required this.db,
    required this.carrito,
    required this.formatearPesos,
    required this.onGuardado,
    required this.onVolverAtras,
  });

  @override
  State<_ModalConfirmacion> createState() => _ModalConfirmacionState();
}

class _ModalConfirmacionState extends State<_ModalConfirmacion> {
  late List<Map<String, dynamic>> _items;
  String _formaPago = 'Efectivo';
  final TextEditingController _clienteCtrl = TextEditingController();
  final List<String> _formasPago = ['Efectivo', 'Crédito', 'Transferencia', 'Tarjeta'];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _items = widget.carrito.map((i) => Map<String, dynamic>.from(i)).toList();
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    super.dispose();
  }

  void _recalcular(int idx) {
    setState(() {
      _items[idx]['subtotal'] =
          _items[idx]['cantidad'] * _items[idx]['precio_unitario'];
    });
  }

  double get _total =>
      _items.fold(0, (s, i) => s + (i['subtotal'] as double));

  Future<void> _confirmar() async {
    if (_formaPago == 'Crédito' && _clienteCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Las ventas a crédito requieren nombre del cliente')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      await widget.db.registrarVenta(
        formaPago: _formaPago,
        tipo: _formaPago == 'Crédito' ? 'crédito' : 'contado',
        items: _items,
        cliente: _clienteCtrl.text.trim().isEmpty ? null : _clienteCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
      widget.onGuardado();
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F4F7),
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
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: widget.onVolverAtras,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 4),
                Text('Confirmar venta',
                    style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3366FF))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lista de productos
                  Text('Productos',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  ..._items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nombre'],
                                      style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                    widget.formatearPesos(
                                        item['precio_unitario'] as double),
                                    style: GoogleFonts.montserrat(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            // Controles cantidad
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if ((item['cantidad'] as int) > 1) {
                                      setState(() => _items[idx]['cantidad']--);
                                      _recalcular(idx);
                                    } else {
                                      setState(() => _items.removeAt(idx));
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.remove, size: 16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text('${item['cantidad']}',
                                      style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _items[idx]['cantidad']++);
                                    _recalcular(idx);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3366FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.add,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.formatearPesos(item['subtotal'] as double),
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: const Color(0xFF3366FF)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (_items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('No hay productos en el carrito',
                            style: GoogleFonts.montserrat(color: Colors.grey)),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Forma de pago
                  Text('Forma de pago',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _formasPago.map((f) {
                      final sel = _formaPago == f;
                      return ChoiceChip(
                        label: Text(f,
                            style: GoogleFonts.montserrat(fontSize: 13)),
                        selected: sel,
                        selectedColor: const Color(0xFF3366FF),
                        labelStyle: GoogleFonts.montserrat(
                            color: sel ? Colors.white : Colors.black87,
                            fontSize: 13),
                        onSelected: (_) =>
                            setState(() => _formaPago = f),
                      );
                    }).toList(),
                  ),

                  // Cliente
                  if (_formaPago == 'Crédito') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _clienteCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre del cliente (obligatorio)',
                        labelStyle: GoogleFonts.montserrat(fontSize: 13),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3366FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text('TOTAL',
                            style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        const Spacer(),
                        Text(widget.formatearPesos(_total),
                            style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 22)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // Botón confirmar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            color: Colors.white,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _items.isEmpty
                    ? Colors.grey
                    : const Color(0xFF3366FF),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed:
                  _items.isEmpty || _guardando ? null : _confirmar,
              child: _guardando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Confirmar venta',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}