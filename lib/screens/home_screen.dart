import 'package:flutter/material.dart';
import 'dart:async';
import '../models/activity.dart';
import '../models/sensor_data.dart';
import '../services/sensor_service.dart';
import '../services/activity_service.dart';
import '../services/data_storage_service.dart';
import '../services/notification_service.dart';
import 'activity_management_screen.dart';
import 'settings_screen.dart';
import 'data_export_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SensorService _sensorService = SensorService();
  final ActivityService _activityService = ActivityService();
  final DataStorageService _dataStorageService = DataStorageService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription<SensorData>? _sensorDataSubscription;
  StreamSubscription<Activity?>? _currentActivitySubscription;
  StreamSubscription<int>? _remainingTimeSubscription;
  StreamSubscription<String>? _notificationSubscription;

  Activity? _currentActivity;
  int _remainingTime = 0;
  bool _isRecording = false;
  int _dataCount = 0;
  SensorData? _latestSensorData;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupListeners();
  }

  Future<void> _initializeServices() async {
    await _activityService.initialize();
    await _notificationService.initialize();
  }

  void _setupListeners() {
    // Listen to sensor data
    _sensorDataSubscription = _sensorService.sensorDataStream.listen((data) {
      setState(() {
        _latestSensorData = data;
      });
      
      if (_isRecording) {
        _dataStorageService.addSensorData(data);
        setState(() {
          _dataCount = _dataStorageService.dataCount;
        });
      }
    });

    // Listen to current activity changes
    _currentActivitySubscription = _activityService.currentActivityStream.listen((activity) {
      setState(() {
        _currentActivity = activity;
      });
      
      if (activity != null) {
        _sensorService.setCurrentActivity(activity.name);
      } else {
        _sensorService.setCurrentActivity('idle');
      }
    });

    // Listen to remaining time changes
    _remainingTimeSubscription = _activityService.remainingTimeStream.listen((time) {
      setState(() {
        _remainingTime = time;
      });
    });

    // Listen to notifications
    _notificationSubscription = _activityService.notificationStream.listen((message) {
      _showNotificationSnackBar(message);
    });
  }

  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    _currentActivitySubscription?.cancel();
    _remainingTimeSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Data Recorder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildCurrentActivityCard(),
            const SizedBox(height: 16),
            _buildSensorDataCard(),
            const SizedBox(height: 16),
            _buildControlButtons(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Activities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_download),
            label: 'Export',
          ),
        ],
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recording Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _isRecording ? Icons.fiber_manual_record : Icons.stop,
                  color: _isRecording ? Colors.red : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRecording ? 'Recording' : 'Stopped',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isRecording ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Data Points Collected: $_dataCount'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_currentActivity != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.directions_run,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentActivity!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_remainingTime > 0) ...[
                Text('Time Remaining: ${_formatTime(_remainingTime)}'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 1.0 - (_remainingTime / _currentActivity!.durationInSeconds),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ] else
              const Text(
                'No active activity',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Sensor Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_latestSensorData != null) ...[
              _buildSensorRow('Sensor Type', _latestSensorData!.sensorType),
              _buildSensorRow('X', _latestSensorData!.x.toStringAsFixed(3)),
              _buildSensorRow('Y', _latestSensorData!.y.toStringAsFixed(3)),
              _buildSensorRow('Z', _latestSensorData!.z.toStringAsFixed(3)),
              _buildSensorRow('Activity', _latestSensorData!.activity),
            ] else
              const Text(
                'No sensor data available',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _toggleRecording,
          icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
          label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 8),
        if (_currentActivity != null)
          OutlinedButton.icon(
            onPressed: _stopActivity,
            icon: const Icon(Icons.stop),
            label: const Text('Stop Activity'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
      ],
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      // Use the planned activity sequence
      _activityService.setActivitySequence(_activityService.activities);
      _activityService.startActivitySequence(
        _activityService.activities.map((a) => a.id).toList(),
      );
      _sensorService.startRecording();
      _notificationService.notifyRecordingStarted();
    } else {
      _activityService.stopActivity();
      _sensorService.stopRecording();
      _notificationService.notifyRecordingStopped();
    }
  }


  void _stopActivity() {
    _activityService.stopActivity();
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        _navigateToActivities();
        break;
      case 2:
        _navigateToExport();
        break;
    }
  }

  void _navigateToActivities() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActivityManagementScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToExport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DataExportScreen()),
    );
  }

  void _showNotificationSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

