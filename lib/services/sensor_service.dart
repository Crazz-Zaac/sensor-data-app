import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_data.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  final StreamController<SensorData> _sensorDataController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;

  bool _isRecording = false;
  String _currentActivity = 'idle';
  
  // Sensor configuration
  bool _accelerometerEnabled = true;
  bool _gyroscopeEnabled = true;
  bool _magnetometerEnabled = true;
  Duration _samplingInterval = const Duration(milliseconds: 10); // 100 Hz

  // Getters
  bool get isRecording => _isRecording;
  String get currentActivity => _currentActivity;
  bool get accelerometerEnabled => _accelerometerEnabled;
  bool get gyroscopeEnabled => _gyroscopeEnabled;
  bool get magnetometerEnabled => _magnetometerEnabled;
  Duration get samplingInterval => _samplingInterval;

  // Configuration methods
  void setSensorEnabled(String sensorType, bool enabled) {
    switch (sensorType.toLowerCase()) {
      case 'accelerometer':
        _accelerometerEnabled = enabled;
        break;
      case 'gyroscope':
        _gyroscopeEnabled = enabled;
        break;
      case 'magnetometer':
        _magnetometerEnabled = enabled;
        break;
    }
    
    if (_isRecording) {
      _stopSensors();
      _startSensors();
    }
  }

  void setSamplingRate(int frequencyHz) {
    _samplingInterval = Duration(milliseconds: (1000 / frequencyHz).round());
    
    if (_isRecording) {
      _stopSensors();
      _startSensors();
    }
  }

  void setCurrentActivity(String activity) {
    _currentActivity = activity;
  }

  void startRecording() {
    if (_isRecording) return;
    
    _isRecording = true;
    _startSensors();
  }

  void stopRecording() {
    if (!_isRecording) return;
    
    _isRecording = false;
    _stopSensors();
  }

  void _startSensors() {
    if (_accelerometerEnabled) {
      _accelerometerSubscription = accelerometerEventStream(samplingPeriod: _samplingInterval)
          .listen((AccelerometerEvent event) {
        _sensorDataController.add(SensorData(
          timestamp: DateTime.now(),
          sensorType: 'accelerometer',
          x: event.x,
          y: event.y,
          z: event.z,
          activity: _currentActivity,
        ));
      });
    }

    if (_gyroscopeEnabled) {
      _gyroscopeSubscription = gyroscopeEventStream(samplingPeriod: _samplingInterval)
          .listen((GyroscopeEvent event) {
        _sensorDataController.add(SensorData(
          timestamp: DateTime.now(),
          sensorType: 'gyroscope',
          x: event.x,
          y: event.y,
          z: event.z,
          activity: _currentActivity,
        ));
      });
    }

    if (_magnetometerEnabled) {
      _magnetometerSubscription = magnetometerEventStream(samplingPeriod: _samplingInterval)
          .listen((MagnetometerEvent event) {
        _sensorDataController.add(SensorData(
          timestamp: DateTime.now(),
          sensorType: 'magnetometer',
          x: event.x,
          y: event.y,
          z: event.z,
          activity: _currentActivity,
        ));
      });
    }
  }

  void _stopSensors() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
  }

  void dispose() {
    _stopSensors();
    _sensorDataController.close();
  }
}

