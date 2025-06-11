// speech_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _ttsInitialized = false;
  bool _sttInitialized = false;

  bool get isAvailable => _sttInitialized && _ttsInitialized;

  Future<void> init() async {
    _sttInitialized = await _speech.initialize();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    _ttsInitialized = true;
  }

  Future<bool> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    if (!_sttInitialized) {
      onError('Speech recognition not initialized');
      return false;
    }
    final result = await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
    return result ?? false;
  }

  Future<void> stopListening() async {
    if (_sttInitialized) await _speech.stop();
  }

  Future<void> speak(String text) async {
    if (_ttsInitialized && text.isNotEmpty) {
      await _tts.stop(); // Stop any current speech
      await _tts.speak(text);
    }
  }

  Future<void> stopSpeaking() async {
    if (_ttsInitialized) await _tts.stop();
  }
}