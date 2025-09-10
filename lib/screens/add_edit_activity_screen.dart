import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/activity.dart';

class AddEditActivityScreen extends StatefulWidget {
  final Activity? activity;

  const AddEditActivityScreen({super.key, this.activity});

  @override
  State<AddEditActivityScreen> createState() => _AddEditActivityScreenState();
}

class _AddEditActivityScreenState extends State<AddEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();

  bool get isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    
    if (isEditing) {
      final activity = widget.activity!;
      _nameController.text = activity.name;
      _descriptionController.text = activity.description;
      
      final minutes = activity.durationInSeconds ~/ 60;
      final seconds = activity.durationInSeconds % 60;
      _minutesController.text = minutes.toString();
      _secondsController.text = seconds.toString();
    } else {
      _minutesController.text = '1';
      _secondsController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Activity' : 'Add Activity'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveActivity,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Activity Name',
                  hintText: 'e.g., Walking, Jumping, etc.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an activity name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief description of the activity',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Duration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minutesController,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                        suffixText: 'min',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final minutes = int.tryParse(value);
                        if (minutes == null || minutes < 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _secondsController,
                      decoration: const InputDecoration(
                        labelText: 'Seconds',
                        border: OutlineInputBorder(),
                        suffixText: 'sec',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final seconds = int.tryParse(value);
                        if (seconds == null || seconds < 0 || seconds >= 60) {
                          return 'Invalid (0-59)';
                        }
                        
                        // Check if total duration is at least 1 second
                        final minutes = int.tryParse(_minutesController.text) ?? 0;
                        if (minutes == 0 && seconds == 0) {
                          return 'Duration must be at least 1 second';
                        }
                        
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveActivity,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isEditing ? 'Update Activity' : 'Add Activity',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveActivity() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final minutes = int.parse(_minutesController.text);
    final seconds = int.parse(_secondsController.text);
    final totalSeconds = (minutes * 60) + seconds;

    final activity = Activity(
      id: isEditing ? widget.activity!.id : _generateId(name),
      name: name,
      durationInSeconds: totalSeconds,
      description: description,
    );

    Navigator.pop(context, activity);
  }

  String _generateId(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }
}

