import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sensor_data.dart';

class DataStorageService {
  static final DataStorageService _instance = DataStorageService._internal();
  factory DataStorageService() => _instance;
  DataStorageService._internal();

  final List<SensorData> _collectedData = [];
  
  List<SensorData> get collectedData => List.unmodifiable(_collectedData);
  int get dataCount => _collectedData.length;

  void addSensorData(SensorData data) {
    _collectedData.add(data);
  }

  void clearData() {
    _collectedData.clear();
  }

  Future<String> exportToCsv({String? filename}) async {
    if (_collectedData.isEmpty) {
      throw Exception('No data to export');
    }

    // Generate filename if not provided
    filename ??= 'sensor_data_${DateTime.now().millisecondsSinceEpoch}.csv';
    
    // Get the downloads directory (publicly accessible)
    final directory = await getDownloadsDirectory();
    if (directory == null) {
      throw Exception('Cannot access downloads directory');
    }
    
    final filePath = '${directory.path}/$filename';

    // Prepare CSV data
    final List<List<dynamic>> csvData = [];
    
    // Add headers
    csvData.add(SensorData.getCsvHeaders());
    
    // Add data rows
    for (final sensorData in _collectedData) {
      csvData.add(sensorData.toCsvRow());
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);

    // Write to file
    final file = File(filePath);
    await file.writeAsString(csvString);

    return filePath;
  }


  Future<String> exportToJson({String? filename}) async {
    if (_collectedData.isEmpty) {
      throw Exception('No data to export');
    }

    // Generate filename if not provided
    filename ??= 'sensor_data_${DateTime.now().millisecondsSinceEpoch}.json';
    
    // Get the downloads directory (publicly accessible)
    final directory = await getDownloadsDirectory();
    if (directory == null) {
      throw Exception('Cannot access downloads directory');
    }
    
    final filePath = '${directory.path}/$filename';

    // Convert data to JSON
    final jsonData = _collectedData.map((data) => data.toMap()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    // Write to file
    final file = File(filePath);
    await file.writeAsString(jsonString);

    return filePath;
  }

  Map<String, dynamic> getDataStatistics() {
   if (_collectedData.isEmpty) {
    return {
      'total_records': 0,
      'sensors': <String, int>{},
      'activities': <String, int>{},
      'duration_seconds': 0,
      'first_timestamp': null,
      'last_timestamp': null,
    };
  }

  final sensorCounts = <String, int>{};
  final activityCounts = <String, int>{};
    
    DateTime? firstTimestamp;
    DateTime? lastTimestamp;

    for (final data in _collectedData) {
      // Count by sensor type
      sensorCounts[data.sensorType] = (sensorCounts[data.sensorType] ?? 0) + 1;
      
      // Count by activity
      activityCounts[data.activity] = (activityCounts[data.activity] ?? 0) + 1;
      
      // Track time range
      if (firstTimestamp == null || data.timestamp.isBefore(firstTimestamp)) {
        firstTimestamp = data.timestamp;
      }
      if (lastTimestamp == null || data.timestamp.isAfter(lastTimestamp)) {
        lastTimestamp = data.timestamp;
      }
    }

    final durationSeconds = firstTimestamp != null && lastTimestamp != null
        ? lastTimestamp.difference(firstTimestamp).inSeconds
        : 0;

    return {
      'total_records': _collectedData.length,
      'sensors': sensorCounts,
      'activities': activityCounts,
      'duration_seconds': durationSeconds,
      'first_timestamp': firstTimestamp?.millisecondsSinceEpoch,
      'last_timestamp': lastTimestamp?.millisecondsSinceEpoch,
    };
  }

  Future<List<String>> getExportedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .map((entity) => entity as File)
          .where((file) => file.path.endsWith('.csv') || file.path.endsWith('.json'))
          .map((file) => file.path)
          .toList();
      
      return files;
    } catch (e) {
      return [];
    }
  }
}

