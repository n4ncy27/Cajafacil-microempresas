import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../widgets/voice_listening_modal.dart';
import '../services/voice_parser.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GastosPage — pantalla principal del módulo de Gastos
// ─────────────────────────────────────────────────────────────────────────────

class GastosPage extends StatefulWidget {
  const GastosPage({super.key});

  @override
  State<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends State<GastosPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  String _periodo = 'Hoy';
  List<Map<String, dynamic>> _gastos = [];
  bool _cargando = true;

  static const _periodos = ['Hoy', 'Semana', 'Mes'];

  static const _categoriasIconos = <String, IconData>{
    'Arriendo': Icons.home_outlined,
    'Nómina': Icons.person_outline,
    'Seguridad Social': Icons.security_outlined,
    'Internet': Icons.wifi_outlined,
    'Agua': Icons.water_drop_outlined,
    'Luz': Icons.electric_bolt_outlined,
    'Vigilancia': Icons.shield_outlined,
    'Útiles de Aseo': Icons.cleaning_services_outlined,
    'Otros': Icons.receipt_outlined,
  };

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() => _cargando = true);
    try {
      final ahora = DateTime.now();
      final DateTime desde;
      switch (_periodo) {
        case 'Semana':
          desde = ahora.subtract(const Duration(days: 6));
          break;
        case 'Mes':
          desde = DateTime(ahora.year, ahora.month, 1);
          break;
        default:
          desde = DateTime(ahora.year, ahora.month, ahora.day);
      }
      final hasta = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
      final gastos = await _db.obtenerGastosPorPeriodo(
        desde.toIso8601String(),
        hasta.toIso8601String(),
      );
      setState(() {
        _gastos = gastos;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
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

  String _formatearFechaCorta(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const m = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
      return '${dt.day.toString().padLeft(2, '0')} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  // ── VOZ ────────────────────────────────────────────────────────────────
  Future<void> _procesarVozGasto(String texto) async {
    final parser = VoiceParser();
    final resultado = parser.parsearGastoCompra(texto);

    if (!mounted) return;

    if (resultado.isValid) {
      // Abrir formulario pre-llenado en vez de registrar directamente
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => _NuevoGastoPage(
            categoriaInicial: resultado.categoria,
            valorInicial: resultado.monto,
            formaPagoInicial: resultado.formaPago,
          ),
        ),
      );
      if (ok == true) _cargarGastos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se detectó monto. Di: "Gasté 150000 en arriendo"',
            style: GoogleFonts.montserrat(fontSize: 13),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── NAVEGACIÓN ────────────────────────────────────────────────────────────
  Future<void> _abrirNuevoGasto() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _NuevoGastoPage(),
      ),
    );
    if (ok == true) _cargarGastos();
  }

  Future<void> _abrirPagoGasto() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _PagoGastoPage()),
    );
    if (ok == true) _cargarGastos();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final total = _gastos.fold<double>(
        0, (s, g) => s + (g['valor'] as num).toDouble());

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: const Color(0xFF3366FF),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gastos',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white)),
            Text('Gastos operativos del negocio',
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.payment_outlined),
            tooltip: 'Pagar gastos pendientes',
            onPressed: _abrirPagoGasto,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltro(),
          _buildResumen(total),
          Expanded(child: _buildLista()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VoiceListeningModal.holdButton(
            onResult: _procesarVozGasto,
            heroTag: 'voice_gastos',
            mini: true,
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_gasto',
            onPressed: _abrirNuevoGasto,
            backgroundColor: const Color(0xFF3366FF),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltro() {
    return Container(
      color: const Color(0xFF3366FF),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: _periodos.map((p) {
          final selected = p == _periodo;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _periodo = p);
                _cargarGastos();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? const Color(0xFF3366FF) : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResumen(double total) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Total Gastos',
              valor: _formatearPesos(total),
              valorColor: const Color(0xFFEF5350),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              label: 'Registros',
              valor: _gastos.length.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3366FF)),
      );
    }
    if (_gastos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_downward,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Sin gastos en este período',
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              'Toca + para registrar un gasto',
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
      itemCount: _gastos.length,
      itemBuilder: (_, i) => _GastoItem(
        gasto: _gastos[i],
        formatearPesos: _formatearPesos,
        formatearFecha: _formatearFechaCorta,
        iconos: _categoriasIconos,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares compartidos
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String valor;
  final Color valorColor;

  const _SummaryCard({
    required this.label,
    required this.valor,
    this.valorColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(valor,
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: valorColor)),
        ],
      ),
    );
  }
}

class _GastoItem extends StatelessWidget {
  final Map<String, dynamic> gasto;
  final String Function(double) formatearPesos;
  final String Function(String) formatearFecha;
  final Map<String, IconData> iconos;

  const _GastoItem({
    required this.gasto,
    required this.formatearPesos,
    required this.formatearFecha,
    required this.iconos,
  });

  @override
  Widget build(BuildContext context) {
    final categoria = gasto['categoria'] as String? ?? 'Otros';
    final formaPago = gasto['forma_pago'] as String? ?? '';
    final valor = (gasto['valor'] as num).toDouble();
    final pendiente = (gasto['saldo_pendiente'] as num? ?? 0).toDouble();
    final fecha = gasto['fecha'] as String? ?? '';
    final icono = iconos[categoria] ?? Icons.receipt_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icono, color: const Color(0xFFEF5350), size: 22),
        ),
        title: Text(
          categoria,
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formaPago,
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: Colors.grey)),
            if (pendiente > 0)
              Text(
                'Pendiente: ${formatearPesos(pendiente)}',
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: Colors.orange.shade700),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatearPesos(valor),
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF5350)),
            ),
            Text(
              formatearFecha(fecha),
              style:
                  GoogleFonts.montserrat(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _gastoInputDeco({String? prefix}) => InputDecoration(
      prefixText: prefix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3366FF))),
      filled: true,
      fillColor: Colors.white,
    );

Widget _gastoSectionCard(
    {required String title, required List<Widget> children}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
            color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

Widget _gastoLabel(String text) => Text(
      text,
      style:
          GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade700),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla: Nuevo Gasto
// ─────────────────────────────────────────────────────────────────────────────

class _NuevoGastoPage extends StatefulWidget {
  final String? categoriaInicial;
  final double? valorInicial;
  final String? formaPagoInicial;

  const _NuevoGastoPage({
    this.categoriaInicial,
    this.valorInicial,
    this.formaPagoInicial,
  });

  @override
  State<_NuevoGastoPage> createState() => _NuevoGastoPageState();
}

class _NuevoGastoPageState extends State<_NuevoGastoPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();

  late String _categoria;
  DateTime _fecha = DateTime.now();
  late String _formaPago;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _categoria = widget.categoriaInicial ?? 'Arriendo';
    _formaPago = widget.formaPagoInicial ?? 'Nequi';
    if (widget.valorInicial != null) {
      _valorController.text = widget.valorInicial!.toStringAsFixed(0);
    }
  }

  static const _categorias = [
    'Arriendo',
    'Nómina',
    'Seguridad Social',
    'Internet',
    'Agua',
    'Luz',
    'Vigilancia',
    'Útiles de Aseo',
    'Otros',
  ];

  static const _formasPago = ['Efectivo', 'Nequi', 'Transf.', 'Crédito'];

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  String _fmtFecha(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'CO'),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final valor = double.parse(
          _valorController.text.replaceAll(RegExp(r'[^\d.]'), ''));
      final tipo = _formaPago == 'Crédito' ? 'crédito' : 'contado';
      await _db.insertarGasto({
        'descripcion': _categoria,
        'categoria': _categoria,
        'valor': valor,
        'forma_pago': _formaPago,
        'tipo': tipo,
        'saldo_pendiente': tipo == 'crédito' ? valor : 0.0,
        'fecha': _fecha.toIso8601String(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _guardando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al registrar: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: const Color(0xFF3366FF),
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nuevo Gasto',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white)),
            Text('Manual o por voz',
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Sección: Gasto
              _gastoSectionCard(
                title: 'GASTO',
                children: [
                  _gastoLabel('Categoría'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _categoria,
                    decoration: _gastoInputDeco(),
                    items: _categorias
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style:
                                    GoogleFonts.montserrat(fontSize: 14))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _categoria = v ?? _categoria),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _gastoLabel('Valor'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _valorController,
                              keyboardType: TextInputType.number,
                              decoration: _gastoInputDeco(prefix: '\$'),
                              style: GoogleFonts.montserrat(fontSize: 14),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                final clean = v.replaceAll(
                                    RegExp(r'[^\d.]'), '');
                                if (double.tryParse(clean) == null) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _gastoLabel('Fecha'),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _seleccionarFecha,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 15),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _fmtFecha(_fecha),
                                        style: GoogleFonts.montserrat(
                                            fontSize: 13),
                                      ),
                                    ),
                                    Icon(Icons.calendar_today_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Sección: Forma de pago
              _gastoSectionCard(
                title: 'FORMA DE PAGO',
                children: [
                  Row(
                    children: _formasPago.map((f) {
                      final sel = f == _formaPago;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _formaPago = f),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF3366FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: sel
                                      ? const Color(0xFF3366FF)
                                      : Colors.grey.shade300),
                            ),
                            child: Text(
                              f,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : Colors.black87),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botón registrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF5350),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Registrar Gasto',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla: Pago de Gasto Pendiente
// ─────────────────────────────────────────────────────────────────────────────

class _PagoGastoPage extends StatefulWidget {
  const _PagoGastoPage();

  @override
  State<_PagoGastoPage> createState() => _PagoGastoPageState();
}

class _PagoGastoPageState extends State<_PagoGastoPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _pagoController = TextEditingController();

  List<Map<String, dynamic>> _pendientes = [];
  Map<String, dynamic>? _seleccionado;
  DateTime _fecha = DateTime.now();
  String _formaPago = 'Nequi';
  bool _cargando = true;
  bool _guardando = false;

  static const _formasPago = ['Efectivo', 'Nequi', 'Transf.', 'Tarjeta'];

  @override
  void initState() {
    super.initState();
    _cargarPendientes();
  }

  @override
  void dispose() {
    _pagoController.dispose();
    super.dispose();
  }

  Future<void> _cargarPendientes() async {
    final p = await _db.obtenerGastosPendientes();
    setState(() {
      _pendientes = p;
      _seleccionado = p.isNotEmpty ? p.first : null;
      if (_seleccionado != null) {
        _pagoController.text =
            (_seleccionado!['saldo_pendiente'] as num).toStringAsFixed(0);
      }
      _cargando = false;
    });
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

  String _fmtFechaCorta(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const m = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
      return '${dt.day.toString().padLeft(2, '0')} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _fmtFecha(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  double get _saldoPendiente =>
      _seleccionado == null
          ? 0
          : (_seleccionado!['saldo_pendiente'] as num).toDouble();

  double get _montoPago =>
      double.tryParse(
          _pagoController.text.replaceAll(RegExp(r'[^\d.]'), '')) ??
      0;

  double get _saldoResultante =>
      (_saldoPendiente - _montoPago).clamp(0, double.infinity);

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'CO'),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _registrarPago() async {
    if (_seleccionado == null) return;
    if (_pagoController.text.isEmpty) return;
    final monto = _montoPago;
    if (monto <= 0) return;

    setState(() => _guardando = true);
    try {
      await _db.registrarPagoGasto(
        gastoId: _seleccionado!['id'] as int,
        monto: monto,
        formaPago: _formaPago,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _guardando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al registrar pago: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: const Color(0xFF3366FF),
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pago de Gasto',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white)),
            Text('Pagar gasto pendiente',
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: _pendientes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No hay gastos pendientes',
                    style: GoogleFonts.montserrat(
                        fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // — Gasto pendiente —
                  _gastoSectionCard(
                    title: 'GASTO PENDIENTE',
                    children: [
                      _gastoLabel('Seleccionar'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        initialValue: _seleccionado,
                        decoration: _gastoInputDeco(),
                        items: _pendientes.map((g) {
                          final cat = g['categoria'] as String? ?? '';
                          final saldo =
                              (g['saldo_pendiente'] as num).toDouble();
                          return DropdownMenuItem(
                            value: g,
                            child: Text(
                              '$cat · ${_formatearPesos(saldo)}',
                              style: GoogleFonts.montserrat(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _seleccionado = v;
                            if (v != null) {
                              _pagoController.text = (v['saldo_pendiente']
                                      as num)
                                  .toStringAsFixed(0);
                            }
                          });
                        },
                      ),
                      if (_seleccionado != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SALDO PENDIENTE',
                                style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFEF5350)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatearPesos(_saldoPendiente),
                                style: GoogleFonts.montserrat(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFEF5350)),
                              ),
                              Text(
                                '${_seleccionado!['categoria']} · ${_fmtFechaCorta(_seleccionado!['fecha'] as String? ?? '')}',
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // — Pago —
                  _gastoSectionCard(
                    title: 'PAGO',
                    children: [
                      _gastoLabel('Valor'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pagoController,
                        keyboardType: TextInputType.number,
                        decoration: _gastoInputDeco(prefix: '\$'),
                        style: GoogleFonts.montserrat(fontSize: 14),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _gastoLabel('Fecha'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _seleccionarFecha,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Text(_fmtFecha(_fecha),
                                  style:
                                      GoogleFonts.montserrat(fontSize: 13)),
                              const Spacer(),
                              Icon(Icons.calendar_today_outlined,
                                  size: 16, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _gastoLabel('Forma de pago'),
                      const SizedBox(height: 8),
                      Row(
                        children: _formasPago.map((f) {
                          final sel = f == _formaPago;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _formaPago = f),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 3),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFF3366FF)
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                      color: sel
                                          ? const Color(0xFF3366FF)
                                          : Colors.grey.shade300),
                                ),
                                child: Text(
                                  f,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? Colors.white
                                          : Colors.black87),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // — Resultado —
                  if (_seleccionado != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _saldoResultante == 0
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RESULTADO',
                            style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _saldoResultante == 0
                                ? 'Gasto saldado — \$0 pendiente'
                                : 'Saldo restante: ${_formatearPesos(_saldoResultante)}',
                            style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _saldoResultante == 0
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _registrarPago,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF5350),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              'Registrar Pago',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

