class SensorData {
  final DateTime timestamp;
  final String sensorType;
  final double x;
  final double y;
  final double z;
  final String activity;

  SensorData({
    required this.timestamp,
    required this.sensorType,
    required this.x,
    required this.y,
    required this.z,
    required this.activity,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'sensor_type': sensorType,
      'x': x,
      'y': y,
      'z': z,
      'activity': activity,
    };
  }

  List<dynamic> toCsvRow() {
    return [
      timestamp.millisecondsSinceEpoch,
      sensorType,
      x,
      y,
      z,
      activity,
    ];
  }

  static List<String> getCsvHeaders() {
    return [
      'timestamp',
      'sensor_type',
      'x',
      'y',
      'z',
      'activity',
    ];
  }
}

