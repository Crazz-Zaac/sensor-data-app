import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/activity.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final List<Activity> _activities = [];
  Activity? _currentActivity;
  Timer? _activityTimer;
  Timer? _reminderTimer;
  
  final StreamController<Activity?> _currentActivityController = StreamController<Activity?>.broadcast();
  final StreamController<int> _remainingTimeController = StreamController<int>.broadcast();
  final StreamController<String> _notificationController = StreamController<String>.broadcast();

  // Streams
  Stream<Activity?> get currentActivityStream => _currentActivityController.stream;
  Stream<int> get remainingTimeStream => _remainingTimeController.stream;
  Stream<String> get notificationStream => _notificationController.stream;

  // Getters
  List<Activity> get activities => List.unmodifiable(_activities);
  Activity? get currentActivity => _currentActivity;
  bool get isActivityRunning => _activityTimer != null;

  List<Activity> _activitySequence = [];
  int _currentActivityIndex = -1;
  Timer? _preparationTimer;

  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  Future<void> initialize() async {
    await _loadActivities();
    
    // Add default activities if none exist
    if (_activities.isEmpty) {
      await _addDefaultActivities();
    }
  }

  Future<void> _addDefaultActivities() async {
    final defaultActivities = [
      Activity(
        id: 'walking',
        name: 'Walking',
        durationInSeconds: 300, // 5 minutes
        description: 'Normal walking pace',
      ),
      Activity(
        id: 'jumping',
        name: 'Jumping',
        durationInSeconds: 60, // 1 minute
        description: 'Vertical jumping motion',
      ),
      Activity(
        id: 'rotating',
        name: 'Rotating',
        durationInSeconds: 120, // 2 minutes
        description: 'Rotating the device in different directions',
      ),
      Activity(
        id: 'jogging',
        name: 'Jogging',
        durationInSeconds: 300, // 5 minutes
        description: 'Light jogging pace',
      ),
      Activity(
        id: 'patting',
        name: 'Patting Device',
        durationInSeconds: 30, // 30 seconds
        description: 'Gently patting the mobile device',
      ),
    ];

    for (final activity in defaultActivities) {
      await addActivity(activity);
    }
  }

  Future<void> addActivity(Activity activity) async {
    _activities.add(activity);
    await _saveActivities();
  }

  Future<void> updateActivity(Activity activity) async {
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _activities[index] = activity;
      await _saveActivities();
    }
  }

  Future<void> removeActivity(String activityId) async {
    _activities.removeWhere((a) => a.id == activityId);
    await _saveActivities();
  }

  Activity? getActivityById(String id) {
    try {
      return _activities.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add this method to start a sequence of activities
  void startActivitySequence(List<String> activityIds) {
    stopActivity();
    _activitySequence = activityIds.map((id) => getActivityById(id)).whereType<Activity>().toList();
    _currentActivityIndex = -1;
    _startNextActivity();
  }

  void _startNextActivity() {
    _currentActivityIndex++;
    if (_currentActivityIndex >= _activitySequence.length) {
      // All activities completed
      _notificationController.add('All activities completed');
      return;
    }

    final nextActivity = _activitySequence[_currentActivityIndex];
    final preparationTime = 10; // seconds to prepare for next activity

    // Notify about upcoming activity
    _notificationController.add('Prepare for ${nextActivity.name} in $preparationTime seconds');
    
    // Set up preparation timer
    _preparationTimer = Timer(Duration(seconds: preparationTime), () {
      _startActivity(nextActivity);
    });
  }

  void _startActivity(Activity activity) {
    _currentActivity = activity;
    _remainingSeconds = activity.durationInSeconds;
    
    _currentActivityController.add(_currentActivity);
    _notificationController.add('Activity "${activity.name}" started');

    // Set up activity timer
    _activityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _remainingTimeController.add(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        _notificationController.add('Activity "${activity.name}" completed');
        timer.cancel();
        _startNextActivity();
      }
    });
  }

  void startActivity(String activityId) {
    final activity = getActivityById(activityId);
    if (activity == null) return;

    // Stop any current activity
    stopActivity();

    _startActivity(activity);

    _currentActivity = activity;
    _remainingSeconds = activity.durationInSeconds;
    
    // Set up reminder timer (1 minute before start)
    if (activity.durationInSeconds > 60) {
      _reminderTimer = Timer(Duration(seconds: activity.durationInSeconds - 60), () {
        _notificationController.add('Activity "${activity.name}" starting in 1 minute');
      });
    }

    // Set up activity timer
    _activityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _remainingTimeController.add(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        _notificationController.add('Activity "${activity.name}" completed');
        stopActivity();
      }
    });

    _currentActivityController.add(_currentActivity);
    _notificationController.add('Activity "${activity.name}" started');
  }

  void stopActivity() {
    _activityTimer?.cancel();
    _reminderTimer?.cancel();
    _activityTimer = null;
    _reminderTimer = null;
    
    final previousActivity = _currentActivity;
    _currentActivity = null;
    _remainingSeconds = 0;
    
    _currentActivityController.add(null);
    _remainingTimeController.add(0);
    
    if (previousActivity != null) {
      _notificationController.add('Activity "${previousActivity.name}" stopped');
    }
  }

  void pauseActivity() {
    _activityTimer?.cancel();
    _reminderTimer?.cancel();
    // Keep current activity and remaining time, but stop timers
  }

  void resumeActivity() {
    if (_currentActivity == null) return;

    // Resume with remaining time
    _activityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _remainingTimeController.add(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        _notificationController.add('Activity "${_currentActivity!.name}" completed');
        stopActivity();
      }
    });
  }

  Future<void> _saveActivities() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/activities.json');
      
      final activitiesJson = _activities.map((a) => a.toMap()).toList();
      await file.writeAsString(jsonEncode(activitiesJson));
    } catch (e) {
      print('Error saving activities: $e');
    }
  }

  Future<void> _loadActivities() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/activities.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> activitiesJson = jsonDecode(jsonString);
        
        _activities.clear();
        _activities.addAll(
          activitiesJson.map((json) => Activity.fromMap(json)).toList(),
        );
      }
    } catch (e) {
      print('Error loading activities: $e');
    }
  }

  void dispose() {
    stopActivity();
    _currentActivityController.close();
    _remainingTimeController.close();
    _notificationController.close();
  }
}

