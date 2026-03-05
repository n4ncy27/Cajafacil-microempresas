import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _productosFiltrados = [];
  bool _cargando = true;
  final TextEditingController _buscadorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    setState(() => _cargando = true);
    try {
      final productos = await _db.obtenerProductos();
      setState(() {
        _productos = productos;
        _productosFiltrados = productos;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar productos: $e')),
        );
      }
    }
  }

  void _filtrarProductos(String query) async {
    try {
      if (query.isEmpty) {
        setState(() => _productosFiltrados = _productos);
      } else {
        final resultado = await _db.buscarProductos(query);
        setState(() => _productosFiltrados = resultado);
      }
    } catch (e) {
      // Si falla la búsqueda, simplemente no filtra
    }
  }

  String _formatearId(int id) {
    return '#${id.toString().padLeft(3, '0')}';
  }

  void _abrirFormulario({Map<String, dynamic>? producto}) {
    final esEdicion = producto != null;
    final codigoCtrl = TextEditingController(text: producto?['codigo'] ?? '');
    final nombreCtrl = TextEditingController(text: producto?['nombre'] ?? '');
    final cantidadCtrl = TextEditingController(text: producto?['cantidad']?.toString() ?? '');
    final precioCompraCtrl = TextEditingController(text: producto?['precio_compra']?.toString() ?? '');
    final precioVentaCtrl = TextEditingController(text: producto?['precio_venta']?.toString() ?? '');
    final stockMinimoCtrl = TextEditingController(text: producto?['stock_minimo']?.toString() ?? '5');
    final vencimientoCtrl = TextEditingController(text: producto?['fecha_vencimiento'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    esEdicion ? 'Editar Producto' : 'Nuevo Producto',
                    style: GoogleFonts.montserrat(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: const Color(0xFF3366FF),
                    ),
                  ),
                  const Spacer(),
                  // ID solo lectura, visible solo al editar
                  if (esEdicion)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatearId(producto!['id']),
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3366FF),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _campo('Código', codigoCtrl),
              _campo('Nombre del producto', nombreCtrl),
              _campo('Cantidad', cantidadCtrl, esNumero: true),
              _campo('Precio de compra', precioCompraCtrl, esDecimal: true),
              _campo('Precio de venta', precioVentaCtrl, esDecimal: true),
              _campo('Stock mínimo', stockMinimoCtrl, esNumero: true),
              _campo('Fecha de vencimiento (YYYY-MM-DD)', vencimientoCtrl),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3366FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (codigoCtrl.text.trim().isEmpty || nombreCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código y nombre son obligatorios')),
                      );
                      return;
                    }
                    try {
                      final data = {
                        'codigo': codigoCtrl.text.trim(),
                        'nombre': nombreCtrl.text.trim(),
                        'cantidad': int.tryParse(cantidadCtrl.text) ?? 0,
                        'precio_compra': double.tryParse(precioCompraCtrl.text) ?? 0,
                        'precio_venta': double.tryParse(precioVentaCtrl.text) ?? 0,
                        'stock_minimo': int.tryParse(stockMinimoCtrl.text) ?? 5,
                        'fecha_vencimiento': vencimientoCtrl.text.trim().isEmpty
                            ? null
                            : vencimientoCtrl.text.trim(),
                      };
                      if (esEdicion) {
                        await _db.actualizarProducto(producto!['id'], data);
                      } else {
                        await _db.insertarProducto(data);
                      }
                      if (mounted) Navigator.pop(context);
                      _cargarProductos();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al guardar: $e')),
                        );
                      }
                    }
                  },
                  child: Text(
                    esEdicion ? 'Guardar cambios' : 'Agregar producto',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl,
      {bool esNumero = false, bool esDecimal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: esDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : esNumero
                ? TextInputType.number
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  void _confirmarEliminar(int id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar producto',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        content: Text('¿Eliminar "$nombre"?\nEsta acción no se puede deshacer.',
            style: GoogleFonts.montserrat()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.montserrat()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                await _db.eliminarProducto(id);
                if (mounted) Navigator.pop(context);
                _cargarProductos();
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                }
              }
            },
            child: Text('Eliminar', style: GoogleFonts.montserrat(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _colorStock(Map<String, dynamic> p) {
    final cantidad = (p['cantidad'] as num).toInt();
    final minimo = (p['stock_minimo'] as num).toInt();
    if (cantidad == 0) return Colors.red.shade100;
    if (cantidad <= minimo) return Colors.orange.shade100;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text('Inventario',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF3366FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            tooltip: 'Bajo stock',
            onPressed: () async {
              try {
                final bajoStock = await _db.obtenerProductosBajoStock();
                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Productos con bajo stock',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                    content: bajoStock.isEmpty
                        ? Text('Todo el inventario está bien.', style: GoogleFonts.montserrat())
                        : SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: bajoStock.length,
                              itemBuilder: (_, i) {
                                final p = bajoStock[i];
                                final cantidad = (p['cantidad'] as num).toInt();
                                final minimo = (p['stock_minimo'] as num).toInt();
                                return ListTile(
                                  leading: Icon(
                                    cantidad == 0 ? Icons.remove_circle : Icons.warning_amber,
                                    color: cantidad == 0 ? Colors.red : Colors.orange,
                                  ),
                                  title: Text(p['nombre'], style: GoogleFonts.montserrat(fontSize: 13)),
                                  subtitle: Text(
                                    'Stock: $cantidad / Mínimo: $minimo',
                                    style: GoogleFonts.montserrat(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      )
                    ],
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _buscadorController,
              onChanged: _filtrarProductos,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                hintStyle: GoogleFonts.montserrat(fontSize: 13),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Lista
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3366FF)))
                : _productosFiltrados.isEmpty
                    ? Center(
                        child: Text('No hay productos registrados',
                            style: GoogleFonts.montserrat(fontSize: 15, color: Colors.grey)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _productosFiltrados.length,
                        itemBuilder: (context, index) {
                          final p = _productosFiltrados[index];
                          final cantidad = (p['cantidad'] as num).toInt();
                          final minimo = (p['stock_minimo'] as num).toInt();
                          final id = p['id'] as int;

                          return Card(
                            color: _colorStock(p),
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF3366FF),
                                    radius: 20,
                                    child: Text(
                                      p['nombre'].toString()[0].toUpperCase(),
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatearId(id),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                p['nombre'],
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Código: ${p['codigo']}',
                                      style: GoogleFonts.montserrat(fontSize: 12)),
                                  Text(
                                    'Stock: $cantidad  |  Mínimo: $minimo',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: cantidad <= minimo
                                          ? (cantidad == 0 ? Colors.red.shade700 : Colors.orange.shade800)
                                          : Colors.grey.shade700,
                                      fontWeight: cantidad <= minimo
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    'Compra: \$${p['precio_compra']}  |  Venta: \$${p['precio_venta']}',
                                    style: GoogleFonts.montserrat(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Color(0xFF3366FF)),
                                    onPressed: () => _abrirFormulario(producto: p),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.redAccent),
                                    onPressed: () =>
                                        _confirmarEliminar(id, p['nombre']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: const Color(0xFF3366FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Agregar',
            style: GoogleFonts.montserrat(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}