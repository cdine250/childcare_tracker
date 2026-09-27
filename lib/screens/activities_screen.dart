import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ActivitiesScreen extends StatelessWidget {
  ActivitiesScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _childIdController =
      TextEditingController();

  final TextEditingController _activityTypeController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _durationController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  void _clearControllers() {
    _childIdController.clear();
    _activityTypeController.clear();
    _descriptionController.clear();
    _durationController.clear();
    _notesController.clear();
  }

  Future<void> _showActivityDialog(
    BuildContext context, {
    DocumentSnapshot<Map<String, dynamic>>? activity,
  }) async {
    final bool isEditing = activity != null;

    DateTime activityDate = DateTime.now();

    if (isEditing) {
      final Timestamp? timestamp =
          activity.data()?['activityDate'] as Timestamp?;

      if (timestamp != null) {
        activityDate = timestamp.toDate();
      }

      _childIdController.text =
          activity.data()?['childId']?.toString() ?? '';

      _activityTypeController.text =
          activity.data()?['activityType']?.toString() ?? '';

      _descriptionController.text =
          activity.data()?['description']?.toString() ?? '';

      _durationController.text =
          activity.data()?['durationMinutes']?.toString() ?? '';

      _notesController.text =
          activity.data()?['notes']?.toString() ?? '';
    } else {
      _clearControllers();
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Edit Activity'
                    : 'Add Activity',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _childIdController,
                      decoration: const InputDecoration(
                        labelText: 'Child ID',
                        hintText: 'Enter the child document ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _activityTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Activity Type',
                        hintText: 'e.g. Feeding, Playing',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Activity Date'),
                      subtitle: Text(
                        '${activityDate.day}/'
                        '${activityDate.month}/'
                        '${activityDate.year}',
                      ),
                      onTap: () async {
                        final DateTime? selectedDate =
                            await showDatePicker(
                          context: context,
                          initialDate: activityDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (selectedDate != null) {
                          setState(() {
                            activityDate = selectedDate;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearControllers();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String childId =
                        _childIdController.text.trim();

                    final String activityType =
                        _activityTypeController.text.trim();

                    final String description =
                        _descriptionController.text.trim();

                    final String durationText =
                        _durationController.text.trim();

                    final String notes =
                        _notesController.text.trim();

                    if (childId.isEmpty ||
                        activityType.isEmpty ||
                        description.isEmpty ||
                        durationText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill in all required fields.',
                          ),
                        ),
                      );
                      return;
                    }

                    final int? duration =
                        int.tryParse(durationText);

                    if (duration == null || duration < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Duration must be a valid number.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final User? user =
                          FirebaseAuth.instance.currentUser;

                      if (user == null) {
                        throw Exception(
                          'You must be signed in.',
                        );
                      }

                      if (isEditing) {
                        await _firestoreService.updateActivity(
                          activityId: activity.id,
                          activityType: activityType,
                          description: description,
                          activityDate: activityDate,
                          durationMinutes: duration,
                          notes: notes,
                        );
                      } else {
                        await _firestoreService.createActivity(
                          childId: childId,
                          parentId: user.uid,
                          activityType: activityType,
                          description: description,
                          activityDate: activityDate,
                          durationMinutes: duration,
                          notes: notes,
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      _clearControllers();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'Activity updated successfully.'
                                  : 'Activity added successfully.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Operation failed: $e',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    isEditing ? 'Update' : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteActivity(
    BuildContext context,
    String activityId,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: const Text(
            'Are you sure you want to delete this activity?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _firestoreService.deleteActivity(activityId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Activity deleted successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not delete activity: $e',
            ),
          ),
        );
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final DateTime date = value.toDate();

      return '${date.day}/'
          '${date.month}/'
          '${date.year}';
    }

    return 'Unknown date';
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please sign in first.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getActivities(
          user.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load activities.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<
                  QueryDocumentSnapshot<Map<String, dynamic>>>
              activities =
              snapshot.data?.docs ?? [];

          if (activities.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_run,
                      size: 70,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No activities yet.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap + to add your first childcare activity.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final data = activity.data();

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(
                              Icons.directions_run,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['activityType']
                                      ?.toString() ??
                                  'Activity',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showActivityDialog(
                                context,
                                activity: activity,
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(
                              Icons.delete,
                            ),
                            onPressed: () {
                              _deleteActivity(
                                context,
                                activity.id,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Child ID: '
                        '${data['childId'] ?? 'Unknown'}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Description: '
                        '${data['description'] ?? ''}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Duration: '
                        '${data['durationMinutes'] ?? 0} minutes',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Date: '
                        '${_formatDate(data['activityDate'])}',
                      ),
                      if ((data['notes'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Notes: ${data['notes']}',
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showActivityDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}