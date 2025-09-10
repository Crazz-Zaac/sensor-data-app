import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/sensor_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final SensorService _sensorService = SensorService();

  // Notification settings
  bool _ttsEnabled = true;
  bool _soundEnabled = true;
  double _speechRate = 0.5;
  double _speechVolume = 1.0;
  double _speechPitch = 1.0;

  // Sensor settings
  bool _accelerometerEnabled = true;
  bool _gyroscopeEnabled = true;
  bool _magnetometerEnabled = true;
  int _samplingRate = 100; // Hz

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      // Load notification settings
      _ttsEnabled = _notificationService.ttsEnabled;
      _soundEnabled = _notificationService.soundEnabled;
      _speechRate = _notificationService.speechRate;
      _speechVolume = _notificationService.speechVolume;
      _speechPitch = _notificationService.speechPitch;

      // Load sensor settings
      _accelerometerEnabled = _sensorService.accelerometerEnabled;
      _gyroscopeEnabled = _sensorService.gyroscopeEnabled;
      _magnetometerEnabled = _sensorService.magnetometerEnabled;
      _samplingRate = (1000 / _sensorService.samplingInterval.inMilliseconds).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNotificationSettings(),
          const SizedBox(height: 24),
          _buildSensorSettings(),
          const SizedBox(height: 24),
          _buildTestSection(),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Voice Notifications (TTS)'),
              subtitle: const Text('Enable text-to-speech announcements'),
              value: _ttsEnabled,
              onChanged: (value) {
                setState(() {
                  _ttsEnabled = value;
                });
                _notificationService.setTtsEnabled(value);
              },
            ),
            SwitchListTile(
              title: const Text('Sound Effects'),
              subtitle: const Text('Enable notification sounds'),
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
                _notificationService.setSoundEnabled(value);
              },
            ),
            const Divider(),
            const Text(
              'Speech Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Speech Rate'),
              subtitle: Slider(
                value: _speechRate,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: _speechRate.toStringAsFixed(1),
                onChanged: _ttsEnabled ? (value) {
                  setState(() {
                    _speechRate = value;
                  });
                  _notificationService.setSpeechRate(value);
                } : null,
              ),
            ),
            ListTile(
              title: const Text('Speech Volume'),
              subtitle: Slider(
                value: _speechVolume,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: _speechVolume.toStringAsFixed(1),
                onChanged: _ttsEnabled ? (value) {
                  setState(() {
                    _speechVolume = value;
                  });
                  _notificationService.setSpeechVolume(value);
                } : null,
              ),
            ),
            ListTile(
              title: const Text('Speech Pitch'),
              subtitle: Slider(
                value: _speechPitch,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                label: _speechPitch.toStringAsFixed(1),
                onChanged: _ttsEnabled ? (value) {
                  setState(() {
                    _speechPitch = value;
                  });
                  _notificationService.setSpeechPitch(value);
                } : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sensor Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Accelerometer'),
              subtitle: const Text('Measure linear acceleration'),
              value: _accelerometerEnabled,
              onChanged: (value) {
                setState(() {
                  _accelerometerEnabled = value;
                });
                _sensorService.setSensorEnabled('accelerometer', value);
              },
            ),
            SwitchListTile(
              title: const Text('Gyroscope'),
              subtitle: const Text('Measure angular velocity'),
              value: _gyroscopeEnabled,
              onChanged: (value) {
                setState(() {
                  _gyroscopeEnabled = value;
                });
                _sensorService.setSensorEnabled('gyroscope', value);
              },
            ),
            SwitchListTile(
              title: const Text('Magnetometer'),
              subtitle: const Text('Measure magnetic field'),
              value: _magnetometerEnabled,
              onChanged: (value) {
                setState(() {
                  _magnetometerEnabled = value;
                });
                _sensorService.setSensorEnabled('magnetometer', value);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Sampling Rate'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_samplingRate Hz'),
                  Slider(
                    value: _samplingRate.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    label: '$_samplingRate Hz',
                    onChanged: (value) {
                      setState(() {
                        _samplingRate = value.round();
                      });
                      _sensorService.setSamplingRate(_samplingRate);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _notificationService.notify('This is a test notification');
                    },
                    child: const Text('Test Voice'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _notificationService.playNotificationSound();
                    },
                    child: const Text('Test Sound'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _notificationService.notifyActivityStarted('Test Activity');
                },
                child: const Text('Test Activity Notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

