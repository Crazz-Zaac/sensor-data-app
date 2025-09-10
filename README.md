# Sensor Data Recorder

A Flutter mobile application for recording sensor data during different activities with ML-ready CSV output. This app is designed to collect accelerometer, gyroscope, and magnetometer data for machine learning applications, particularly for anomaly detection.

## Features

### Core Functionality
- **Multi-sensor Data Collection**: Records data from accelerometer, gyroscope, and magnetometer
- **Configurable Sampling Rates**: Adjustable from 10Hz to 200Hz for different research requirements
- **Activity Management**: Pre-define and manage different activities (walking, jumping, rotating, jogging, patting device)
- **Voice Notifications**: Text-to-speech announcements for activity reminders and status updates
- **CSV Export**: Export collected data with activity labels in ML-ready CSV format
- **Real-time Monitoring**: Live display of sensor readings and recording status

### Activity Features
- Pre-plan activities with custom durations
- 1-minute advance warning notifications
- Activity start/stop announcements
- Progress tracking with visual indicators
- Automatic activity completion

### Data Export
- CSV format with columns: timestamp, sensor_type, x, y, z, activity
- JSON format for alternative data processing
- File management with statistics and metadata
- Data visualization and summary statistics

### Customization
- Enable/disable individual sensors
- Adjustable speech rate, volume, and pitch for TTS
- Sound effect controls
- Sampling rate configuration

## Installation

### Prerequisites
- Flutter SDK (3.22.2 or later)
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)

### Setup
1. Clone or download the project
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

## Dependencies

The app uses the following key packages:
- `sensors_plus`: For accessing device sensors
- `flutter_tts`: For text-to-speech functionality
- `audioplayers`: For sound effects
- `csv`: For CSV file generation
- `path_provider`: For file system access
- `permission_handler`: For managing device permissions

## Usage

### Getting Started
1. Launch the app
2. Configure sensors and sampling rate in Settings
3. Set up voice notification preferences
4. Create or select activities in Activity Management

### Recording Data
1. Select an activity from the Activity Management screen
2. Start the activity (optional - for timed sessions)
3. Tap "Start Recording" on the home screen
4. Perform the desired movements/activities
5. Stop recording when complete

### Exporting Data
1. Navigate to the Data Export screen
2. Review data statistics
3. Choose export format (CSV or JSON)
4. Access exported files from the file list

### Activity Management
- Add new activities with custom names and durations
- Edit existing activities
- Delete unused activities
- Start activities directly from the management screen

## Data Format

### CSV Output
The exported CSV file contains the following columns:
- `timestamp`: Unix timestamp in milliseconds
- `sensor_type`: Type of sensor (accelerometer, gyroscope, magnetometer)
- `x`: X-axis sensor reading
- `y`: Y-axis sensor reading
- `z`: Z-axis sensor reading
- `activity`: Current activity label

### Example CSV Data
```csv
timestamp,sensor_type,x,y,z,activity
1694123456789,accelerometer,0.123,-9.456,0.789,walking
1694123456799,gyroscope,0.012,0.034,-0.056,walking
1694123456809,magnetometer,23.45,-12.67,45.89,walking
```

## Machine Learning Integration

The collected data is formatted for direct use in machine learning pipelines:
- Consistent timestamp format for time-series analysis
- Clear activity labeling for supervised learning
- Multiple sensor types for comprehensive feature extraction
- Configurable sampling rates for different model requirements

## Permissions

The app requires the following permissions:
- **Storage**: For saving CSV/JSON files
- **Audio Recording**: For text-to-speech functionality
- **Internet/Network**: For potential future cloud features

## Architecture

The app follows a modular architecture with clear separation of concerns:
- **Models**: Data structures for sensor data and activities
- **Services**: Business logic for sensors, activities, notifications, and data storage
- **Screens**: UI components for different app sections
- **Main**: Application entry point and routing

## Troubleshooting

### Common Issues
1. **Sensors not working**: Ensure device permissions are granted
2. **TTS not speaking**: Check device volume and TTS settings
3. **Files not saving**: Verify storage permissions
4. **App crashes**: Check Flutter and dependency versions

### Performance Tips
- Lower sampling rates for longer recording sessions
- Disable unused sensors to reduce data volume
- Export data regularly to prevent memory issues

## Contributing

This project is designed for research and educational purposes. Contributions are welcome for:
- Additional sensor support
- Enhanced data visualization
- Cloud storage integration
- Advanced ML preprocessing features

## License

This project is provided as-is for educational and research purposes.

## Support

For technical issues or questions about the implementation, refer to the Flutter documentation and the individual package documentation for the dependencies used.

