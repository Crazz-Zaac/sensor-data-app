class Activity {
  final String id;
  final String name;
  final int durationInSeconds;
  final String description;

  Activity({
    required this.id,
    required this.name,
    required this.durationInSeconds,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'duration_seconds': durationInSeconds,
      'description': description,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      durationInSeconds: map['duration_seconds'] ?? 0,
      description: map['description'] ?? '',
    );
  }

  String get formattedDuration {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Activity copyWith({
    String? id,
    String? name,
    int? durationInSeconds,
    String? description,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      description: description ?? this.description,
    );
  }
}

