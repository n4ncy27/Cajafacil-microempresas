import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/voice_listening_modal.dart';
import '../services/voice_parser.dart';

class ComprasPage extends StatelessWidget {
  const ComprasPage({super.key});

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

  Future<void> _registrarPorVoz(BuildContext context) async {
    final texto = await VoiceListeningModal.show(
      context,
      titulo: 'Dicta tu compra',
      ejemplo: '"Compré 50 Café Volcán a 45000"',
      color: const Color(0xFF3366FF),
    );
    if (texto == null || texto.isEmpty) return;

    final parser = VoiceParser();
    final resultado = parser.parsearGastoCompra(texto);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultado.isValid
              ? 'Compra detectada: ${resultado.descripcion} por ${_formatearPesos(resultado.monto!)}'
              : 'Texto reconocido: "$texto" — Módulo de compras próximamente',
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        backgroundColor: resultado.isValid ? Colors.green : Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(
          'Compras',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3366FF),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Módulo de compras\npróximamente',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes registrar por voz con el botón del micrófono',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'voice_compras',
        onPressed: () => _registrarPorVoz(context),
        backgroundColor: const Color(0xFF1A2A5E),
        child: const Icon(Icons.mic, color: Colors.amberAccent),
      ),
    );
  }
}
