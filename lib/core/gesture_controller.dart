import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math' as math;

class GestureController extends ChangeNotifier {
  static final GestureController _instance = GestureController._internal();
  factory GestureController() => _instance;
  GestureController._internal();

  // Speech recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  // Text-to-speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsEnabled = true;

  // Camera for gesture recognition (basic implementation)
  CameraController? _cameraController;
  bool _cameraEnabled = false;
  bool _gestureDetectionActive = false;
  bool _cameraPermissionGranted = false;
  bool _microphonePermissionGranted = false;
  String? _cameraPermissionMessage;
  String? _speechPermissionMessage;

  // Sensor data for tilt controls
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  bool _tiltControlsEnabled = true;
  double _tiltSensitivity = 1.0;

  // Gesture detection state
  double _currentTiltX = 0.0;
  double _currentTiltY = 0.0;
  double _tiltThreshold = 0.3;

  // Voice command callbacks
  Function(String)? _onVoiceCommand;
  Function(String)? _onGestureDetected;
  Function(double, double)? _onTiltChanged;

  // Accessibility features
  bool _highContrastEnabled = false;
  bool _largeTextEnabled = false;
  bool _reduceMotionEnabled = false;
  double _gameSpeed = 1.0;

  // Getters
  bool get speechEnabled => _speechEnabled;
  bool get isListening => _isListening;
  bool get ttsEnabled => _ttsEnabled;
  bool get cameraEnabled => _cameraEnabled;
  bool get tiltControlsEnabled => _tiltControlsEnabled;
  bool get highContrastEnabled => _highContrastEnabled;
  bool get largeTextEnabled => _largeTextEnabled;
  bool get reduceMotionEnabled => _reduceMotionEnabled;
  double get gameSpeed => _gameSpeed;
  double get currentTiltX => _currentTiltX;
  double get currentTiltY => _currentTiltY;
  String get lastWords => _lastWords;
  bool get cameraPermissionGranted => _cameraPermissionGranted;
  bool get microphonePermissionGranted => _microphonePermissionGranted;
  String? get cameraPermissionMessage => _cameraPermissionMessage;
  String? get speechPermissionMessage => _speechPermissionMessage;

  // Initialize all gesture and accessibility systems
  Future<void> initialize() async {
    await _initializeSpeechToText();
    await _initializeTextToSpeech();
    await _initializeSensors();
    // Camera initialization is optional and done on demand
    print('Gesture Controller initialized successfully');
  }

  // Speech-to-text initialization
  Future<void> _initializeSpeechToText() async {
    try {
      final hasPermission = await _ensureSpeechPermissions();
      if (!hasPermission) {
        _speechEnabled = false;
        return;
      }

      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (error) => print('Speech error: $error'),
      );
      print('Speech recognition initialized: $_speechEnabled');
    } catch (e) {
      print('Speech initialization error: $e');
      _speechEnabled = false;
    }
  }

  // Text-to-speech initialization
  Future<void> _initializeTextToSpeech() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.8);
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);
      print('Text-to-speech initialized successfully');
    } catch (e) {
      print('TTS initialization error: $e');
      _ttsEnabled = false;
    }
  }

  // Sensor initialization for tilt controls
  Future<void> _initializeSensors() async {
    try {
      _accelerometerSubscription =
          accelerometerEvents.listen(_handleAccelerometerData);
      _gyroscopeSubscription = gyroscopeEvents.listen(_handleGyroscopeData);
      print('Sensor systems initialized for tilt controls');
    } catch (e) {
      print('Sensor initialization error: $e');
      _tiltControlsEnabled = false;
    }
  }

  // Handle accelerometer data for tilt detection
  void _handleAccelerometerData(AccelerometerEvent event) {
    if (!_tiltControlsEnabled) return;

    // Apply sensitivity and smoothing
    final newTiltX = (event.x * _tiltSensitivity).clamp(-1.0, 1.0);
    final newTiltY = (event.y * _tiltSensitivity).clamp(-1.0, 1.0);

    // Smoothing filter to reduce noise
    _currentTiltX = _currentTiltX * 0.8 + newTiltX * 0.2;
    _currentTiltY = _currentTiltY * 0.8 + newTiltY * 0.2;

    // Trigger callbacks if significant tilt detected
    if (math.sqrt(
            _currentTiltX * _currentTiltX + _currentTiltY * _currentTiltY) >
        _tiltThreshold) {
      _onTiltChanged?.call(_currentTiltX, _currentTiltY);
    }

    notifyListeners();
  }

  // Handle gyroscope data for rotation gestures
  void _handleGyroscopeData(GyroscopeEvent event) {
    if (!_tiltControlsEnabled) return;

    // Detect shake gestures (rapid rotation)
    final rotationMagnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (rotationMagnitude > 5.0) {
      _onGestureDetected?.call('shake');
    }
  }

  // Voice command system
  Future<void> startListening() async {
    if (_isListening) return;

    final hasPermission = await _ensureSpeechPermissions();
    if (!hasPermission) {
      _speechEnabled = false;
      return;
    }

    if (!_speechEnabled) {
      await _initializeSpeechToText();
    }

    if (!_speechEnabled) return;

    try {
      await _speechToText.listen(
        onResult: _handleSpeechResult,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: 'en_US',
        onSoundLevelChange: null,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      _isListening = true;
      notifyListeners();

      // Provide haptic feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Start listening error: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      print('Stop listening error: $e');
    }
  }

  void _handleSpeechResult(result) {
    _lastWords = result.recognizedWords;

    if (result.finalResult) {
      _processVoiceCommand(_lastWords.toLowerCase());
      _isListening = false;
      notifyListeners();
    }
  }

  void _processVoiceCommand(String command) {
    print('Voice command received: $command');

    // Process common game commands
    if (command.contains('hint') || command.contains('help')) {
      _onVoiceCommand?.call('hint');
      _speak('Here\'s a hint for you!');
    } else if (command.contains('pause') || command.contains('stop')) {
      _onVoiceCommand?.call('pause');
      _speak('Game paused');
    } else if (command.contains('restart') || command.contains('reset')) {
      _onVoiceCommand?.call('restart');
      _speak('Restarting level');
    } else if (command.contains('menu') || command.contains('home')) {
      _onVoiceCommand?.call('menu');
      _speak('Going to main menu');
    } else if (command.contains('settings')) {
      _onVoiceCommand?.call('settings');
      _speak('Opening settings');
    } else if (command.contains('volume up') || command.contains('louder')) {
      _onVoiceCommand?.call('volume_up');
    } else if (command.contains('volume down') || command.contains('quieter')) {
      _onVoiceCommand?.call('volume_down');
    } else if (command.contains('faster') || command.contains('speed up')) {
      setGameSpeed(math.min(2.0, _gameSpeed + 0.2));
      _speak('Game speed increased');
    } else if (command.contains('slower') || command.contains('slow down')) {
      setGameSpeed(math.max(0.5, _gameSpeed - 0.2));
      _speak('Game speed decreased');
    } else {
      _speak('Command not recognized. Try saying hint, pause, or menu.');
    }
  }

  // Text-to-speech functionality
  Future<void> _speak(String text) async {
    if (!_ttsEnabled) return;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS speak error: $e');
    }
  }

  // Announce game events for accessibility
  Future<void> announceGameEvent(String event, {bool interrupt = false}) async {
    if (!_ttsEnabled) return;

    String announcement = '';
    switch (event) {
      case 'level_start':
        announcement =
            'Level started. Sort the items into the correct containers.';
        break;
      case 'correct_placement':
        announcement = 'Correct! Item placed successfully.';
        break;
      case 'incorrect_placement':
        announcement = 'Incorrect placement. Try again.';
        break;
      case 'level_complete':
        announcement = 'Excellent! Level completed successfully.';
        break;
      case 'hint_available':
        announcement = 'Hint: Look for the highlighted container.';
        break;
      case 'achievement_unlocked':
        announcement = 'Achievement unlocked! Great job.';
        break;
      default:
        announcement = event;
    }

    if (interrupt) {
      await _flutterTts.stop();
    }

    await _speak(announcement);
  }

  // Camera initialization for gesture recognition (basic)
  Future<void> initializeCamera() async {
    if (_cameraEnabled) return;

    try {
      final hasPermission = await _ensureCameraPermission();
      if (!hasPermission) {
        _cameraEnabled = false;
        notifyListeners();
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        _cameraEnabled = true;
        print('Camera initialized for gesture recognition');
        notifyListeners();
      }
    } catch (e) {
      print('Camera initialization error: $e');
      _cameraEnabled = false;
      notifyListeners();
    }
  }

  Future<void> startGestureDetection() async {
    if (_gestureDetectionActive) return;

    if (!_cameraEnabled) {
      await initializeCamera();
    }

    if (!_cameraEnabled) return;

    _gestureDetectionActive = true;
    // Basic gesture detection would be implemented here
    // This is a simplified version - real gesture recognition would require
    // ML models like MediaPipe or TensorFlow Lite
    print('Gesture detection started (basic implementation)');
  }

  Future<void> stopGestureDetection() async {
    _gestureDetectionActive = false;
    print('Gesture detection stopped');
  }

  // Accessibility methods
  void toggleHighContrast() {
    _highContrastEnabled = !_highContrastEnabled;
    notifyListeners();
    _speak(_highContrastEnabled
        ? 'High contrast enabled'
        : 'High contrast disabled');
  }

  void toggleLargeText() {
    _largeTextEnabled = !_largeTextEnabled;
    notifyListeners();
    _speak(_largeTextEnabled ? 'Large text enabled' : 'Large text disabled');
  }

  void toggleReduceMotion() {
    _reduceMotionEnabled = !_reduceMotionEnabled;
    notifyListeners();
    _speak(_reduceMotionEnabled
        ? 'Reduced motion enabled'
        : 'Reduced motion disabled');
  }

  void setGameSpeed(double speed) {
    _gameSpeed = speed.clamp(0.1, 3.0);
    notifyListeners();
  }

  void setTiltSensitivity(double sensitivity) {
    _tiltSensitivity = sensitivity.clamp(0.1, 3.0);
    notifyListeners();
  }

  // Callback setters
  void setVoiceCommandCallback(Function(String)? callback) {
    _onVoiceCommand = callback;
  }

  void setGestureDetectedCallback(Function(String)? callback) {
    _onGestureDetected = callback;
  }

  void setTiltChangedCallback(Function(double, double)? callback) {
    _onTiltChanged = callback;
  }

  // Settings
  Future<void> setTtsEnabled(bool enabled) async {
    _ttsEnabled = enabled;
    if (!enabled) {
      await _flutterTts.stop();
    }
    notifyListeners();
  }

  void setTiltControlsEnabled(bool enabled) {
    _tiltControlsEnabled = enabled;
    if (!enabled) {
      _currentTiltX = 0.0;
      _currentTiltY = 0.0;
    }
    notifyListeners();
  }

  // Cleanup
  Future<void> dispose() async {
    await stopListening();
    await _flutterTts.stop();
    await stopGestureDetection();

    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();

    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    super.dispose();
  }

  bool _permissionStatusAllowsUse(PermissionStatus status) {
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  Future<bool> _ensureCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (!_permissionStatusAllowsUse(status)) {
      status = await Permission.camera.request();
    }

    if (_permissionStatusAllowsUse(status)) {
      _updateCameraPermissionState(true, null);
      return true;
    }

    final bool permanentlyDenied = status.isPermanentlyDenied;
    final bool restricted = status.isRestricted;
    final message = permanentlyDenied
        ? 'Camera access permanently denied. Camera gestures are disabled until permissions are enabled in system settings.'
        : restricted
            ? 'Camera access is restricted on this device. Camera gestures are disabled.'
            : 'Camera access denied. Camera gestures are disabled.';
    _updateCameraPermissionState(false, message);
    return false;
  }

  Future<bool> _ensureSpeechPermissions() async {
    PermissionStatus microphoneStatus = await Permission.microphone.status;

    if (!_permissionStatusAllowsUse(microphoneStatus)) {
      microphoneStatus = await Permission.microphone.request();
    }

    PermissionStatus speechStatus = PermissionStatus.granted;
    final bool supportsSpeechPermission = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (supportsSpeechPermission) {
      speechStatus = await Permission.speech.status;
      if (!_permissionStatusAllowsUse(speechStatus)) {
        speechStatus = await Permission.speech.request();
      }
    }

    final bool granted =
        _permissionStatusAllowsUse(microphoneStatus) &&
            _permissionStatusAllowsUse(speechStatus);

    if (granted) {
      _updateSpeechPermissionState(true, null);
      return true;
    }

    final bool permanentlyDenied =
        microphoneStatus.isPermanentlyDenied || speechStatus.isPermanentlyDenied;
    final bool restricted =
        microphoneStatus.isRestricted || speechStatus.isRestricted;
    final message = permanentlyDenied
        ? 'Microphone or speech recognition access permanently denied. Voice commands are disabled until permissions are enabled in system settings.'
        : restricted
            ? 'Microphone or speech recognition access is restricted on this device. Voice commands are disabled.'
            : 'Microphone or speech recognition access denied. Voice commands are disabled.';
    _updateSpeechPermissionState(false, message);
    return false;
  }

  void _updateCameraPermissionState(bool granted, String? message) {
    if (_cameraPermissionGranted != granted ||
        _cameraPermissionMessage != message) {
      _cameraPermissionGranted = granted;
      _cameraPermissionMessage = message;
      notifyListeners();
    }
  }

  void _updateSpeechPermissionState(bool granted, String? message) {
    if (_microphonePermissionGranted != granted ||
        _speechPermissionMessage != message) {
      _microphonePermissionGranted = granted;
      _speechPermissionMessage = message;
      notifyListeners();
    }
  }
}
