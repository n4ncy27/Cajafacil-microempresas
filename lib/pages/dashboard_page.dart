import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/voice_listening_modal.dart';
import '../services/voice_parser.dart';
import '../database/database_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static bool _seeded = false;

  double _totalHoy = 0;
  double _ingresosTotal = 0;
  int _ventasHoyCount = 0;
  int _productosBajoStock = 0;
  double _comprasTotal = 0;
  double _gastosTotal = 0;
  double _cajaCierreHoy = 0;
  double _ingresosContadoHoy = 0;
  double _egresosContadoHoy = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    // Seed de datos demo (solo una vez)
    if (!_seeded) {
      await _db.seedDemoData();
      _seeded = true;
    }
    final ventas = await _db.obtenerVentas();
    final bajoStock = await _db.obtenerProductosBajoStock();
    final comprasTotal = await _db.obtenerTotalComprasAcumulado();
    final gastosTotal = await _db.obtenerTotalGastosAcumulado();
    final flujoCaja = await _db.obtenerFlujoCaja('Hoy');

    final hoy = DateTime.now();
    final ventasHoy = ventas.where((v) {
      final f = DateTime.parse(v['fecha']);
      return f.day == hoy.day && f.month == hoy.month && f.year == hoy.year;
    }).toList();

    final totalHoy = ventasHoy.fold<double>(
        0, (s, v) => s + (v['total'] as num).toDouble());
    final ingresosTotal = ventas.fold<double>(
        0, (s, v) => s + (v['total'] as num).toDouble());

    if (mounted) {
      setState(() {
        _totalHoy = totalHoy;
        _ingresosTotal = ingresosTotal;
        _ventasHoyCount = ventasHoy.length;
        _productosBajoStock = bajoStock.length;
        _comprasTotal = comprasTotal;
        _gastosTotal = gastosTotal;
        _cajaCierreHoy = flujoCaja['total_caja'] ?? 0;
        _ingresosContadoHoy = flujoCaja['ingresos_efectivo'] ?? 0;
        _egresosContadoHoy = (flujoCaja['compras_efectivo'] ?? 0) + (flujoCaja['gastos_efectivo'] ?? 0);
        _cargando = false;
      });
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

  String _formatearCompacto(double valor) {
    if (valor >= 1000000) {
      return '\$${(valor / 1000000).toStringAsFixed(1)}M';
    } else if (valor >= 1000) {
      return '\$${(valor / 1000).toStringAsFixed(0)}K';
    }
    return _formatearPesos(valor);
  }

  Future<void> _procesarVoz(String texto) async {
    final parser = VoiceParser();
    final accion = VoiceParser.detectarAccion(texto);

    if (!mounted) return;

    if (accion == 'venta') {
      // Registrar venta
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

      final db = DatabaseHelper.instance;
      final items = resultado.items.map((i) => i.toMap()).toList();
      final formaPago = resultado.formaPago ?? 'Efectivo';
      await db.registrarVenta(
        formaPago: formaPago,
        tipo: formaPago == 'Crédito' ? 'crédito' : 'contado',
        items: items,
        cliente: resultado.cliente,
      );

      if (!mounted) return;
      final total = resultado.items.fold<double>(0, (s, i) => s + i.subtotal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Venta registrada: ${_formatearPesos(total)} en $formaPago',
            style: GoogleFonts.montserrat(fontSize: 13),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (accion == 'compra') {
      // Registrar compra — matchear producto del inventario
      final resultado = await parser.parsearVenta(texto);
      if (!mounted) return;

      if (resultado.hasItems) {
        final item = resultado.items.first;
        final formaPago = resultado.formaPago ?? 'Efectivo';
        await _db.registrarCompra(
          proveedor: 'Proveedor (voz)',
          productoId: item.productoId!,
          codigoProducto: item.codigo,
          nombreProducto: item.nombre,
          cantidad: item.cantidad,
          precioUnitario: (await _db.obtenerProductos())
              .firstWhere((p) => p['id'] == item.productoId)['precio_compra'] as double,
          total: item.cantidad *
              ((await _db.obtenerProductos())
                  .firstWhere((p) => p['id'] == item.productoId)['precio_compra'] as double),
          formaPago: formaPago,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Compra registrada: ${item.cantidad}x ${item.nombre}',
              style: GoogleFonts.montserrat(fontSize: 13),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontró producto en: "$texto"',
                style: GoogleFonts.montserrat(fontSize: 13)),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else if (accion == 'gasto') {
      // Registrar gasto
      final resultado = parser.parsearGastoCompra(texto);
      if (!mounted) return;

      if (resultado.isValid) {
        final formaPago = resultado.formaPago ?? 'Efectivo';
        final tipo = formaPago == 'Crédito' ? 'crédito' : 'contado';
        await _db.insertarGasto({
          'descripcion': resultado.categoria!,
          'categoria': resultado.categoria!,
          'valor': resultado.monto!,
          'forma_pago': formaPago,
          'tipo': tipo,
          'saldo_pendiente': tipo == 'crédito' ? resultado.monto! : 0.0,
          'fecha': DateTime.now().toIso8601String(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gasto registrado: ${resultado.categoria} por ${_formatearPesos(resultado.monto!)}',
              style: GoogleFonts.montserrat(fontSize: 13),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se detectó monto en: "$texto"',
                style: GoogleFonts.montserrat(fontSize: 13)),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else {
      // No se detectó acción
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Di "vendí", "compré" o "gasté" seguido de los datos.\nEj: "Vendí 2 Café Volcán en efectivo"',
            style: GoogleFonts.montserrat(fontSize: 13),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          // Header azul
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF3366FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saludo + avatar
                Text(
                  'Bienvenido a CajaFácil',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                // Card total en caja
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2A5E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL EN CAJA — HOY',
                        style: GoogleFonts.montserrat(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _cargando ? '...' : _formatearPesos(_cajaCierreHoy),
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildBadge(
                            '+ Ingresos ${_formatearCompacto(_ingresosContadoHoy)}',
                            const Color(0xFF4CAF50),
                          ),
                          const SizedBox(width: 10),
                          _buildBadge(
                            '- Egresos ${_formatearCompacto(_egresosContadoHoy)}',
                            const Color(0xFFEF5350),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Registrar por voz (mantener presionado)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2A5E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        VoiceListeningModal.holdButton(
                          onResult: _procesarVoz,
                          color: Colors.white12,
                          iconColor: Colors.amberAccent,
                          size: 44,
                          heroTag: 'voice_home',
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrar por Voz',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mantén presionado: "Vendí…", "Compré…" o "Gasté…"',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Grid de 4 cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildModuleCard(
                          icon: Icons.arrow_upward,
                          iconColor: const Color(0xFF4CAF50),
                          borderColor: const Color(0xFF4CAF50),
                          title: 'Ingresos',
                          subtitle: 'Ventas y abonos',
                          value: _cargando ? '...' : _formatearCompacto(_ingresosTotal),
                          valueColor: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModuleCard(
                          icon: Icons.receipt_long,
                          iconColor: const Color(0xFF3366FF),
                          borderColor: const Color(0xFF3366FF),
                          title: 'Compras',
                          subtitle: 'Proveedores',
                          value: _cargando ? '...' : _formatearCompacto(_comprasTotal),
                          valueColor: const Color(0xFF3366FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModuleCard(
                          icon: Icons.arrow_downward,
                          iconColor: const Color(0xFFEF5350),
                          borderColor: const Color(0xFFEF5350),
                          title: 'Gastos',
                          subtitle: 'Operativos',
                          value: _cargando ? '...' : _formatearCompacto(_gastosTotal),
                          valueColor: const Color(0xFFEF5350),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModuleCard(
                          icon: Icons.inventory_2_outlined,
                          iconColor: const Color(0xFFFF9800),
                          borderColor: const Color(0xFFFF9800),
                          title: 'Inventario',
                          subtitle: 'Control stock',
                          value: '',
                          valueColor: Colors.transparent,
                          badge: _cargando ? '...' : '$_productosBajoStock bajos',
                          badgeColor: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Reportes card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bar_chart,
                            color: Color(0xFF7C4DFF),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reportes',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Flujo de Caja · CxC · CxP · Estado de Resultado',
                                style: GoogleFonts.montserrat(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required String value,
    required Color valueColor,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (value.isNotEmpty)
            Text(
              value,
              style: GoogleFonts.montserrat(
                color: valueColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: GoogleFonts.montserrat(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
