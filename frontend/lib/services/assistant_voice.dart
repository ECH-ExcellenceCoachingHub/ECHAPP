import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

/// Speaks AI assistant replies in the ElevenLabs voice used for course videos
/// (via POST /api/ai/tts), falling back to the device voice when the backend
/// has no ElevenLabs audio for it.
class AssistantVoice {
  AssistantVoice({this.onSpeakingChanged}) {
    _player.onPlayerStateChanged.listen((state) {
      _setSpeaking(state == PlayerState.playing);
    });
    _tts.setStartHandler(() => _setSpeaking(true));
    _tts.setCompletionHandler(() => _setSpeaking(false));
    _tts.setCancelHandler(() => _setSpeaking(false));
    _tts.setErrorHandler((_) => _setSpeaking(false));
  }

  final void Function(bool speaking)? onSpeakingChanged;
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _ttsConfigured = false;
  bool _speaking = false;
  // Bumped on every speak/stop so a slow audio request cannot start playing
  // after the user has moved on.
  int _generation = 0;

  // Text -> audio URL, shared by every chat widget in the session.
  static final Map<String, String> _urlCache = {};

  bool get isSpeaking => _speaking;

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await stop();
    final generation = _generation;

    final url = await _fetchAudioUrl(text);
    if (generation != _generation) return;

    if (url != null) {
      try {
        await _player.play(UrlSource(url));
        return;
      } catch (e) {
        print('ElevenLabs audio playback failed, using device voice: $e');
      }
    }
    await _configureDeviceVoice();
    if (generation != _generation) return;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    _generation++;
    await _player.stop();
    await _tts.stop();
    _setSpeaking(false);
  }

  void dispose() {
    _generation++;
    _player.dispose();
    _tts.stop();
  }

  void _setSpeaking(bool value) {
    if (_speaking == value) return;
    _speaking = value;
    onSpeakingChanged?.call(value);
  }

  Future<String?> _fetchAudioUrl(String text) async {
    final cached = _urlCache[text];
    if (cached != null) return cached;
    try {
      final token = await firebase_auth.FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return null;
      final response = await http
          .post(
            Uri.parse('${ApiConfig.aiBaseUrl}/tts'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'text': text}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      final url = json.decode(response.body)['audioUrl'] as String?;
      if (url != null) _urlCache[text] = url;
      return url;
    } catch (e) {
      print('Error fetching assistant speech: $e');
      return null;
    }
  }

  Future<void> _configureDeviceVoice() async {
    if (_ttsConfigured) return;
    _ttsConfigured = true;
    await _tts.setLanguage('en-GB');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    try {
      final voices = await _tts.getVoices as List;
      final british = voices.cast<Map>().where((v) =>
          v['locale'].toString().toLowerCase().contains('gb') ||
          v['name'].toString().toLowerCase().contains('british'));
      if (british.isNotEmpty) {
        final voice = british.first;
        await _tts.setVoice({'name': voice['name'], 'locale': voice['locale']});
      }
    } catch (e) {
      print('Error setting device voice: $e');
    }
  }
}
