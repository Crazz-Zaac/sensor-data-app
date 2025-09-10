import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/data_storage_service.dart';
import '../services/notification_service.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final DataStorageService _dataStorageService = DataStorageService();
  final NotificationService _notificationService = NotificationService();
  
  Map<String, dynamic>? _statistics;
  List<String> _exportedFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _statistics = _dataStorageService.getDataStatistics();
    });
    _loadExportedFiles();
  }

  Future<void> _loadExportedFiles() async {
    final files = await _dataStorageService.getExportedFiles();
    setState(() {
      _exportedFiles = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Export'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildStatisticsCard(),
                const SizedBox(height: 16),
                _buildExportCard(),
                const SizedBox(height: 16),
                _buildExportedFilesCard(),
              ],
            ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_statistics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No data available'),
        ),
      );
    }

    final totalRecords = _statistics!['total_records'] as int;
    final sensors = _statistics!['sensors'] as Map<String, dynamic>;
    final activities = _statistics!['activities'] as Map<String, dynamic>;
    final durationSeconds = _statistics!['duration_seconds'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Records', totalRecords.toString()),
            _buildStatRow('Duration', _formatDuration(durationSeconds)),
            const SizedBox(height: 8),
            const Text(
              'Sensors:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...sensors.entries.map((entry) => 
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildStatRow(entry.key, entry.value.toString()),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Activities:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...activities.entries.map((entry) => 
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildStatRow(entry.key, entry.value.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
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

  Widget _buildExportCard() {
    final hasData = _statistics != null && (_statistics!['total_records'] as int) > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (!hasData)
              const Text(
                'No data to export. Start recording to collect sensor data.',
                style: TextStyle(color: Colors.grey),
              )
            else ...[
              const Text(
                'Choose export format:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportData('csv'),
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Export CSV'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportData('json'),
                      icon: const Icon(Icons.code),
                      label: const Text('Export JSON'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearData,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear All Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportedFilesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exported Files',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_exportedFiles.isEmpty)
              const Text(
                'No exported files found.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...(_exportedFiles.map((filePath) => _buildFileItem(filePath))),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(String filePath) {
    final fileName = filePath.split('/').last;
    final file = File(filePath);
    
    return FutureBuilder<FileStat>(
      future: file.stat(),
      builder: (context, snapshot) {
        final size = snapshot.data?.size ?? 0;
        final modified = snapshot.data?.modified;
        
        return ListTile(
          leading: Icon(
            fileName.endsWith('.csv') ? Icons.table_chart : Icons.code,
            color: Colors.blue,
          ),
          title: Text(fileName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Size: ${_formatFileSize(size)}'),
              if (modified != null)
                Text('Modified: ${_formatDateTime(modified)}'),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleFileAction(value, filePath),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_path',
                child: Text('Copy Path'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportData(String format) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String filePath;
      if (format == 'csv') {
        filePath = await _dataStorageService.exportToCsv();
      } else {
        filePath = await _dataStorageService.exportToJson();
      }

      await _notificationService.notifyDataExported(filePath.split('/').last);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to ${filePath.split('/').last}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await _loadExportedFiles();
    } catch (e) {
      await _notificationService.notifyError('Failed to export data');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to clear all collected sensor data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _dataStorageService.clearData();
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared'),
        ),
      );
    }
  }

  void _handleFileAction(String action, String filePath) async {
    switch (action) {
      case 'copy_path':
        await Clipboard.setData(ClipboardData(text: filePath));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File path copied to clipboard')),
        );
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete File'),
            content: Text('Are you sure you want to delete ${filePath.split('/').last}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            await File(filePath).delete();
            await _loadExportedFiles();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File deleted')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

