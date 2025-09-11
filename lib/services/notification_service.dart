import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _ttsEnabled = true;
  bool _soundEnabled = true;
  double _speechRate = 0.5;
  double _speechVolume = 1.0;
  double _speechPitch = 1.0;
  String _language = 'en-US';

  // Getters
  bool get ttsEnabled => _ttsEnabled;
  bool get soundEnabled => _soundEnabled;
  double get speechRate => _speechRate;
  double get speechVolume => _speechVolume;
  double get speechPitch => _speechPitch;
  String get language => _language;

  Future<void> initialize() async {
    await _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      // Set TTS configuration
      await _flutterTts.setLanguage(_language);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_speechVolume);
      await _flutterTts.setPitch(_speechPitch);

      // Set up TTS handlers
      _flutterTts.setStartHandler(() {
        print("TTS Started");
      });

      _flutterTts.setCompletionHandler(() {
        print("TTS Completed");
      });

      _flutterTts.setErrorHandler((msg) {
        print("TTS Error: $msg");
      });

    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  // Configuration methods
  void setTtsEnabled(bool enabled) {
    _ttsEnabled = enabled;
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setSpeechVolume(double volume) async {
    _speechVolume = volume;
    await _flutterTts.setVolume(volume);
  }

  Future<void> setSpeechPitch(double pitch) async {
    _speechPitch = pitch;
    await _flutterTts.setPitch(pitch);
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    await _flutterTts.setLanguage(language);
  }

  // Notification methods
  Future<void> speakText(String text) async {
    if (!_ttsEnabled) return;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking text: $e');
    }
  }

  Future<void> playNotificationSound() async {
    if (!_soundEnabled) return;

    try {
      // Play a simple beep sound (you can replace this with a custom sound file)
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print('Error playing notification sound: $e');
      // Fallback: try to play a system sound or generate a tone
    }
  }

  Future<void> playAlertSound() async {
    if (!_soundEnabled) return;

    try {
      // Play an alert sound (you can replace this with a custom sound file)
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      print('Error playing alert sound: $e');
    }
  }

  // Predefined notification methods
  Future<void> notifyActivityStarting(String activityName, int secondsRemaining) async {
    final minutes = secondsRemaining ~/ 60;
    final String message;
    
    if (minutes == 1) {
      message = 'Prepare for $activityName in 1 minute';
    } else if (minutes > 1) {
      message = 'Prepare for $activityName in $minutes minutes';
    } else {
      message = 'Prepare for $activityName in $secondsRemaining seconds';
    }
    
    await playNotificationSound();
    await speakText(message);
  }

  Future<void> notifyActivityStarted(String activityName) async {
    final message = '$activityName activity started';
    await playAlertSound();
    await speakText(message);
  }

  Future<void> notifyActivityCompleted(String activityName) async {
    final message = '$activityName activity completed';
    await playAlertSound();
    await speakText(message);
  }

  Future<void> notifyActivityStopped(String activityName) async {
    const message = 'Activity stopped';
    await playNotificationSound();
    await speakText('$message: $activityName');
  }

  Future<void> notifyRecordingStarted() async {
    const message = 'Recording started';
    await playNotificationSound();
    await speakText(message);
  }

  Future<void> notifyRecordingStopped() async {
    const message = 'Recording stopped';
    await playNotificationSound();
    await speakText(message);
  }

  Future<void> notifyDataExported(String filename) async {
    const message = 'Data exported successfully';
    await playNotificationSound();
    await speakText(message);
  }

  Future<void> notifyError(String errorMessage) async {
    await playAlertSound();
    await speakText('Error: $errorMessage');
  }

  // Generic notification method
  Future<void> notify(String message, {bool playSound = true}) async {
    if (playSound) {
      await playNotificationSound();
    }
    await speakText(message);
  }

  // Stop any ongoing speech
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  // Stop any ongoing audio
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      print('Error getting available languages: $e');
      return ['en-US'];
    }
  }

  // Get available voices
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(voices);
    } catch (e) {
      print('Error getting available voices: $e');
      return [];
    }
  }

  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose();
  }
}

