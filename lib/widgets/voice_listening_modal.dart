import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/voice_service.dart';

/// Modal reutilizable de escucha por voz.
/// Muestra una animación pulsante mientras escucha y devuelve el texto reconocido.
class VoiceListeningModal extends StatefulWidget {
  final String titulo;
  final String ejemplo;
  final Color color;

  const VoiceListeningModal({
    super.key,
    this.titulo = 'Escuchando...',
    this.ejemplo = '"Vendí 2 Café Volcán en efectivo"',
    this.color = const Color(0xFF3366FF),
  });

  /// Muestra el modal y devuelve el texto reconocido o null si se cancela.
  static Future<String?> show(
    BuildContext context, {
    String titulo = 'Escuchando...',
    String ejemplo = '"Vendí 2 Café Volcán en efectivo"',
    Color color = const Color(0xFF3366FF),
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => VoiceListeningModal(
        titulo: titulo,
        ejemplo: ejemplo,
        color: color,
      ),
    );
  }

  @override
  State<VoiceListeningModal> createState() => _VoiceListeningModalState();
}

class _VoiceListeningModalState extends State<VoiceListeningModal>
    with SingleTickerProviderStateMixin {
  final VoiceService _voice = VoiceService.instance;
  late AnimationController _pulseController;
  String _textoReconocido = '';
  bool _escuchando = false;
  bool _error = false;
  String _mensajeError = '';
  bool _cerrado = false;

  void _cerrarConTexto(String? texto) {
    if (_cerrado || !mounted) return;
    _cerrado = true;
    _voice.stopListening();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, texto);
    });
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _iniciarEscucha();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voice.stopListening();
    super.dispose();
  }

  Future<void> _iniciarEscucha() async {
    final disponible = await _voice.initialize();
    if (!disponible) {
      setState(() {
        _error = true;
        _mensajeError = 'El micrófono no está disponible.\nVerifica los permisos de la app.';
      });
      return;
    }

    setState(() {
      _escuchando = true;
      _cerrado = false;
    });

    await _voice.startListening(
      onResult: (texto, esFinal) {
        if (!mounted) return;
        setState(() => _textoReconocido = texto);
        if (esFinal && texto.isNotEmpty) {
          _cerrarConTexto(texto);
        }
      },
      onStatus: (status) {
        if (!mounted || _cerrado) return;
        if (status == 'done' || status == 'notListening') {
          if (_textoReconocido.isNotEmpty) {
            _cerrarConTexto(_textoReconocido);
          } else {
            setState(() => _escuchando = false);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Micrófono animado
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_escuchando ? _pulseController.value * 0.15 : 0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _error
                        ? Colors.red.shade50
                        : _escuchando
                            ? widget.color.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                    border: Border.all(
                      color: _error
                          ? Colors.red.shade300
                          : _escuchando
                              ? widget.color
                              : Colors.grey.shade300,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    _error ? Icons.mic_off : Icons.mic,
                    size: 36,
                    color: _error
                        ? Colors.red
                        : _escuchando
                            ? widget.color
                            : Colors.grey,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Título
          Text(
            _error
                ? 'Error'
                : _escuchando
                    ? widget.titulo
                    : 'Toca para reintentar',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _error ? Colors.red : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Texto reconocido o ejemplo
          if (_error)
            Text(
              _mensajeError,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 13, color: Colors.red.shade400),
            )
          else if (_textoReconocido.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.color.withValues(alpha: 0.2)),
              ),
              child: Text(
                _textoReconocido,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Text(
              widget.ejemplo,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 24),
          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cancelar
              TextButton(
                onPressed: () => _cerrarConTexto(null),
                child: Text('Cancelar',
                    style: GoogleFonts.montserrat(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
              ),
              if (!_escuchando && !_error) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _iniciarEscucha,
                  icon: const Icon(Icons.mic, color: Colors.white, size: 18),
                  label: Text('Reintentar',
                      style: GoogleFonts.montserrat(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
              if (_textoReconocido.isNotEmpty && _escuchando) ...[
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _cerrarConTexto(_textoReconocido),
                  child: Text('Listo',
                      style: GoogleFonts.montserrat(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
