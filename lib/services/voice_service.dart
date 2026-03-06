import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Servicio singleton para reconocimiento de voz
class VoiceService {
  static final VoiceService instance = VoiceService._internal();
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool get isListening => _speech.isListening;

  /// Inicializa el motor de voz. Devuelve true si está disponible.
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  /// Comienza a escuchar. [onResult] recibe el texto reconocido.
  /// [onStatus] recibe el estado ("listening", "notListening", "done").
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(String status)? onStatus,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return;
    }
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      onSoundLevelChange: null,
      localeId: 'es_CO',
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );
    if (onStatus != null) {
      _speech.statusListener = onStatus;
    }
  }

  /// Detiene la escucha
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Cancela la escucha
  Future<void> cancel() async {
    await _speech.cancel();
  }
}
