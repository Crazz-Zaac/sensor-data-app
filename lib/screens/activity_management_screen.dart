import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import 'add_edit_activity_screen.dart';

class ActivityManagementScreen extends StatefulWidget {
  const ActivityManagementScreen({super.key});

  @override
  State<ActivityManagementScreen> createState() => _ActivityManagementScreenState();
}

class _ActivityManagementScreenState extends State<ActivityManagementScreen> {
  final ActivityService _activityService = ActivityService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<Activity?>(
        stream: _activityService.currentActivityStream,
        builder: (context, currentActivitySnapshot) {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _activityService.activities.length,
            itemBuilder: (context, index) {
              final activity = _activityService.activities[index];
              final isCurrentActivity = currentActivitySnapshot.data?.id == activity.id;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                color: isCurrentActivity ? Colors.green.shade50 : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrentActivity ? Colors.green : Colors.blue,
                    child: Text(
                      activity.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    activity.name,
                    style: TextStyle(
                      fontWeight: isCurrentActivity ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duration: ${activity.formattedDuration}'),
                      if (activity.description.isNotEmpty)
                        Text(
                          activity.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrentActivity)
                        StreamBuilder<int>(
                          stream: _activityService.remainingTimeStream,
                          builder: (context, snapshot) {
                            final remainingSeconds = snapshot.data ?? 0;
                            final minutes = remainingSeconds ~/ 60;
                            final seconds = remainingSeconds % 60;
                            return Text(
                              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            );
                          },
                        ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleMenuAction(value, activity),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'start',
                            child: Text('Start Activity'),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _startActivity(activity),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addActivity',
            onPressed: _addNewActivity,
            tooltip: 'Add Activity',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'startSequence',
            onPressed: _startActivitySequence,
            tooltip: 'Start Sequence',
            child: const Icon(Icons.play_arrow),
          ),
        ],
      ),

    );
  }

  void _startActivitySequence() {
    final activityIds = _activityService.activities.map((a) => a.id).toList();

    if (activityIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No activities in sequence')),
      );
      return;
    }

    _activityService.startActivitySequence(activityIds);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting activity sequence'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMenuAction(String action, Activity activity) {
    switch (action) {
      case 'start':
        _startActivity(activity);
        break;
      case 'edit':
        _editActivity(activity);
        break;
      case 'delete':
        _deleteActivity(activity);
        break;
    }
  }

  void _startActivity(Activity activity) {
    _activityService.startActivity(activity.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started activity: ${activity.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addNewActivity() async {
    final result = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditActivityScreen(),
      ),
    );

    if (result != null) {
      await _activityService.addActivity(result);
      setState(() {});
    }
  }

  void _editActivity(Activity activity) async {
    final result = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditActivityScreen(activity: activity),
      ),
    );

    if (result != null) {
      await _activityService.updateActivity(result);
      setState(() {});
    }
  }

  void _deleteActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${activity.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _activityService.removeActivity(activity.id);
      setState(() {});
    }
  }
}

