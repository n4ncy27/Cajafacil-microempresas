import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ── Flujo de Caja ──────────────────────────────────────────────────────────
  int _flujoCajaFiltro = 0;
  static const _flujoCajaFiltros = ['Hoy', 'Semana', 'Mes'];
  Map<String, double> _flujoCaja = {};
  bool _cargandoFlujo = true;

  // ── Cuentas por Cobrar ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _cuentasCobrar = [];
  bool _cargandoCxC = true;

  // ── Cuentas por Pagar ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> _cuentasPagar = [];
  bool _cargandoCxP = true;

  // ── Estado de Resultado ───────────────────────────────────────────────────
  int _estadoResultadoFiltro = 0;
  static const _estadoResultadoFiltros = ['Hoy', 'Mes', 'Año'];
  Map<String, double> _estadoResultado = {};
  bool _cargandoEstado = true;

  // ── Kardex ─────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _kardex = [];
  bool _cargandoKardex = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    await Future.wait([
      _cargarFlujoCaja(),
      _cargarCuentasCobrar(),
      _cargarCuentasPagar(),
      _cargarEstadoResultado(),
      _cargarKardex(),
    ]);
  }

  Future<void> _cargarFlujoCaja() async {
    setState(() => _cargandoFlujo = true);
    final data = await _db.obtenerFlujoCaja(_flujoCajaFiltros[_flujoCajaFiltro]);
    if (mounted) setState(() { _flujoCaja = data; _cargandoFlujo = false; });
  }

  Future<void> _cargarCuentasCobrar() async {
    setState(() => _cargandoCxC = true);
    final data = await _db.obtenerCuentasPorCobrar();
    if (mounted) setState(() { _cuentasCobrar = data; _cargandoCxC = false; });
  }

  Future<void> _cargarCuentasPagar() async {
    setState(() => _cargandoCxP = true);
    final data = await _db.obtenerCuentasPorPagar();
    if (mounted) setState(() { _cuentasPagar = data; _cargandoCxP = false; });
  }

  Future<void> _cargarEstadoResultado() async {
    setState(() => _cargandoEstado = true);
    final data = await _db.obtenerEstadoResultado(
        _estadoResultadoFiltros[_estadoResultadoFiltro]);
    if (mounted) setState(() { _estadoResultado = data; _cargandoEstado = false; });
  }

  Future<void> _cargarKardex() async {
    setState(() => _cargandoKardex = true);
    final data = await _db.obtenerKardex();
    if (mounted) setState(() { _kardex = data; _cargandoKardex = false; });
  }

  String _formatearPesos(double valor) {
    final negativo = valor < 0;
    final abs = valor.abs();
    final str = abs.toStringAsFixed(0);
    final buffer = StringBuffer();
    int c = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      c++;
    }
    final formatted = buffer.toString().split('').reversed.join();
    return negativo ? '-\$$formatted' : '\$$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20, right: 20, bottom: 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF3366FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reportes',
                        style: GoogleFonts.montserrat(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
                    Text('Informes financieros del negocio',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargarTodo,
              color: const Color(0xFF3366FF),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSeccionFlujoCaja(),
                  const SizedBox(height: 12),
                  _buildSeccionCuentasCobrar(),
                  const SizedBox(height: 12),
                  _buildSeccionCuentasPagar(),
                  const SizedBox(height: 12),
                  _buildSeccionEstadoResultado(),
                  const SizedBox(height: 12),
                  _buildSeccionKardex(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FLUJO DE CAJA
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSeccionFlujoCaja() {
    final ingresos = _flujoCaja['ingresos_efectivo'] ?? 0;
    final compras = _flujoCaja['compras_efectivo'] ?? 0;
    final gastos = _flujoCaja['gastos_efectivo'] ?? 0;
    final totalCaja = _flujoCaja['total_caja'] ?? 0;

    return _SeccionExpandible(
      titulo: 'FLUJO DE CAJA',
      subtitulo: 'Dinero que entra y sale en efectivo',
      icono: Icons.account_balance_wallet_outlined,
      colorIcono: const Color(0xFF3366FF),
      inicialmenteExpandido: true,
      child: Column(
        children: [
          // Filtros
          _buildFiltroChips(
            filtros: _flujoCajaFiltros,
            seleccionado: _flujoCajaFiltro,
            onChanged: (i) {
              setState(() => _flujoCajaFiltro = i);
              _cargarFlujoCaja();
            },
          ),
          const SizedBox(height: 16),

          if (_cargandoFlujo)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else ...[
            _filaReporte(
              '+ Ingresos en efectivo',
              _formatearPesos(ingresos),
              Colors.green.shade700,
            ),
            _filaReporte(
              '− Compras en efectivo',
              _formatearPesos(compras),
              Colors.red.shade600,
            ),
            _filaReporte(
              '− Gastos en efectivo',
              _formatearPesos(gastos),
              Colors.red.shade600,
            ),
            const Divider(height: 20),
            _filaTotalReporte(
              '= Total en Caja',
              _formatearPesos(totalCaja),
              totalCaja >= 0 ? const Color(0xFF3366FF) : Colors.red.shade700,
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CUENTAS POR COBRAR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSeccionCuentasCobrar() {
    final totalCxC = _cuentasCobrar.fold<double>(
        0, (s, c) => s + ((c['saldo_pendiente'] as num?)?.toDouble() ?? 0));

    return _SeccionExpandible(
      titulo: 'CUENTAS POR COBRAR',
      subtitulo: 'Lo que los clientes deben',
      icono: Icons.people_outline,
      colorIcono: Colors.green.shade700,
      child: Column(
        children: [
          if (_cargandoCxC)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else if (_cuentasCobrar.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 40, color: Colors.green.shade300),
                  const SizedBox(height: 8),
                  Text('Sin cuentas pendientes',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            )
          else ...[
            ..._cuentasCobrar.map((cuenta) {
              final cliente = cuenta['cliente'] as String? ?? 'Cliente';
              final saldo = (cuenta['saldo_pendiente'] as num?)?.toDouble() ?? 0;
              final total = (cuenta['total'] as num).toDouble();
              final abonado = (cuenta['total_abonado'] as num).toDouble();
              return _itemCuenta(
                titulo: cliente,
                detalle: abonado > 0
                    ? 'Total: ${_formatearPesos(total)} · Abonado: ${_formatearPesos(abonado)}'
                    : 'Venta a crédito',
                monto: _formatearPesos(saldo),
                color: const Color(0xFF3366FF),
              );
            }),
            const Divider(height: 20),
            _filaTotalReporte(
              '= Total por Cobrar',
              _formatearPesos(totalCxC),
              Colors.green.shade700,
              bgColor: Colors.green.shade50,
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CUENTAS POR PAGAR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSeccionCuentasPagar() {
    final totalCxP = _cuentasPagar.fold<double>(
        0, (s, c) => s + ((c['total'] as num?)?.toDouble() ?? 0));

    return _SeccionExpandible(
      titulo: 'CUENTAS POR PAGAR',
      subtitulo: 'Deudas con proveedores',
      icono: Icons.store_outlined,
      colorIcono: Colors.orange.shade700,
      child: Column(
        children: [
          if (_cargandoCxP)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else if (_cuentasPagar.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 40, color: Colors.green.shade300),
                  const SizedBox(height: 8),
                  Text('Sin deudas pendientes',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            )
          else ...[
            ..._cuentasPagar.map((compra) {
              final producto = compra['nombre_producto'] as String? ?? 'Producto';
              final proveedor = compra['proveedor'] as String? ?? 'Proveedor';
              final cantidad = compra['cantidad'] as int? ?? 0;
              final total = (compra['total'] as num).toDouble();
              return _itemCuenta(
                titulo: '$producto × $cantidad',
                detalle: proveedor,
                monto: _formatearPesos(total),
                color: Colors.red.shade600,
              );
            }),
            const Divider(height: 20),
            _filaTotalReporte(
              '= Total por Pagar',
              _formatearPesos(totalCxP),
              Colors.red.shade700,
              bgColor: Colors.orange.shade50,
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ESTADO DE RESULTADO
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSeccionEstadoResultado() {
    final ingresos = _estadoResultado['total_ingresos'] ?? 0;
    final costos = _estadoResultado['total_costos'] ?? 0;
    final gastos = _estadoResultado['total_gastos'] ?? 0;
    final utilidad = _estadoResultado['utilidad'] ?? 0;
    final esGanancia = utilidad >= 0;

    return _SeccionExpandible(
      titulo: 'ESTADO DE RESULTADO',
      subtitulo: 'Utilidad o pérdida del negocio',
      icono: Icons.trending_up_rounded,
      colorIcono: const Color(0xFF7C4DFF),
      child: Column(
        children: [
          // Filtros
          _buildFiltroChips(
            filtros: _estadoResultadoFiltros,
            seleccionado: _estadoResultadoFiltro,
            onChanged: (i) {
              setState(() => _estadoResultadoFiltro = i);
              _cargarEstadoResultado();
            },
          ),
          const SizedBox(height: 16),

          if (_cargandoEstado)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else ...[
            _filaReporte(
              '+ Total Ingresos',
              _formatearPesos(ingresos),
              Colors.green.shade700,
              detalle: 'Contado y Crédito',
            ),
            _filaReporte(
              '− Total Costo',
              _formatearPesos(costos),
              Colors.red.shade600,
              detalle: 'Contado y Crédito',
            ),
            _filaReporte(
              '− Total Gastos',
              _formatearPesos(gastos),
              Colors.red.shade600,
              detalle: 'Contado y Crédito',
            ),
            const Divider(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: esGanancia ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: esGanancia ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    esGanancia ? Icons.trending_up : Icons.trending_down,
                    color: esGanancia ? Colors.green.shade700 : Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esGanancia ? '= Utilidad' : '= Pérdida',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: esGanancia ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatearPesos(utilidad),
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: esGanancia ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  KARDEX
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSeccionKardex() {
    final totalValor = _kardex.fold<double>(
        0, (s, k) => s + ((k['valor_inventario'] as num?)?.toDouble() ?? 0));

    return _SeccionExpandible(
      titulo: 'KARDEX',
      subtitulo: 'Movimiento y valorización del inventario',
      icono: Icons.inventory_2_outlined,
      colorIcono: const Color(0xFF00897B),
      child: Column(
        children: [
          if (_cargandoKardex)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else if (_kardex.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.inventory_outlined, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Sin productos en inventario',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            )
          else ...[
            // Encabezado de tabla
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('Cód',
                        style: GoogleFonts.montserrat(
                            fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Producto',
                        style: GoogleFonts.montserrat(
                            fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text('Ent',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                            fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text('Sal',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                            fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red.shade600)),
                  ),
                  SizedBox(
                    width: 34,
                    child: Text('Stock',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                            fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF3366FF))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Valor',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.montserrat(
                            fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Filas de productos
            ..._kardex.map((k) {
              final codigo = k['codigo'] as String? ?? '';
              final nombre = k['nombre'] as String? ?? '';
              final entradas = (k['entradas'] as num?)?.toInt() ?? 0;
              final salidas = (k['salidas'] as num?)?.toInt() ?? 0;
              final stock = (k['stock'] as num?)?.toInt() ?? 0;
              final valor = (k['valor_inventario'] as num?)?.toDouble() ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(codigo,
                          style: GoogleFonts.montserrat(
                              fontSize: 10, color: Colors.grey.shade500)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(nombre,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                              fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text('$entradas',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text('$salidas',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade600)),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text('$stock',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                              fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF3366FF))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(_formatearPesos(valor),
                          textAlign: TextAlign.end,
                          style: GoogleFonts.montserrat(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 20),
            _filaTotalReporte(
              '= Valor total inventario',
              _formatearPesos(totalValor),
              const Color(0xFF00897B),
              bgColor: const Color(0xFF00897B).withOpacity(0.08),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  WIDGETS AUXILIARES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFiltroChips({
    required List<String> filtros,
    required int seleccionado,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(filtros.length, (i) {
          final activo = seleccionado == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: activo ? const Color(0xFF3366FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  filtros[i],
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: activo ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _filaReporte(String label, String valor, Color valorColor, {String? detalle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.montserrat(
                        fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
                if (detalle != null)
                  Text(detalle,
                      style: GoogleFonts.montserrat(
                          fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Text(valor,
              style: GoogleFonts.montserrat(
                  fontSize: 15, fontWeight: FontWeight.w700, color: valorColor)),
        ],
      ),
    );
  }

  Widget _filaTotalReporte(String label, String valor, Color valorColor, {Color? bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
          ),
          Text(valor,
              style: GoogleFonts.montserrat(
                  fontSize: 17, fontWeight: FontWeight.w800, color: valorColor)),
        ],
      ),
    );
  }

  Widget _itemCuenta({
    required String titulo,
    required String detalle,
    required String monto,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: GoogleFonts.montserrat(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(detalle,
                    style: GoogleFonts.montserrat(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(monto,
              style: GoogleFonts.montserrat(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Sección expandible reutilizable
// ══════════════════════════════════════════════════════════════════════════════

class _SeccionExpandible extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color colorIcono;
  final Widget child;
  final bool inicialmenteExpandido;

  const _SeccionExpandible({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.colorIcono,
    required this.child,
    this.inicialmenteExpandido = false,
  });

  @override
  State<_SeccionExpandible> createState() => _SeccionExpandibleState();
}

class _SeccionExpandibleState extends State<_SeccionExpandible>
    with SingleTickerProviderStateMixin {
  late bool _expandido;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotacionAnimation;

  @override
  void initState() {
    super.initState();
    _expandido = widget.inicialmenteExpandido;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _rotacionAnimation = Tween<double>(begin: 0, end: 0.5).animate(_expandAnimation);

    if (_expandido) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expandido = !_expandido);
    if (_expandido) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (siempre visible, sirve como botón)
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.colorIcono.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icono, color: widget.colorIcono, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.titulo,
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.5)),
                        Text(widget.subtitulo,
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotacionAnimation,
                    child: Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade400, size: 24),
                  ),
                ],
              ),
            ),
          ),

          // Contenido expandible
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
