
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class MilestonesScreen extends StatelessWidget {
  MilestonesScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _childIdController =
      TextEditingController();

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _categoryController =
      TextEditingController();

  final TextEditingController _photoUrlController =
      TextEditingController();

  void _clearControllers() {
    _childIdController.clear();
    _titleController.clear();
    _descriptionController.clear();
    _categoryController.clear();
    _photoUrlController.clear();
  }

  Future<void> _showMilestoneDialog(
    BuildContext context, {
    DocumentSnapshot<Map<String, dynamic>>? milestone,
  }) async {
    final bool isEditing = milestone != null;

    DateTime milestoneDate = DateTime.now();
    bool achieved = false;

    if (isEditing) {
      final Map<String, dynamic>? data = milestone.data();

      _childIdController.text =
          data?['childId']?.toString() ?? '';

      _titleController.text =
          data?['title']?.toString() ?? '';

      _descriptionController.text =
          data?['description']?.toString() ?? '';

      _categoryController.text =
          data?['category']?.toString() ?? '';

      _photoUrlController.text =
          data?['photoUrl']?.toString() ?? '';

      achieved = data?['achieved'] == true;

      final Timestamp? timestamp =
          data?['milestoneDate'] as Timestamp?;

      if (timestamp != null) {
        milestoneDate = timestamp.toDate();
      }
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
                    ? 'Edit Milestone'
                    : 'Add Milestone',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _childIdController,
                      decoration: const InputDecoration(
                        labelText: 'Child ID',
                        hintText: 'Enter child document ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. First Steps',
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
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'e.g. Physical, Language',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today,
                      ),
                      title: const Text('Milestone Date'),
                      subtitle: Text(
                        '${milestoneDate.day}/'
                        '${milestoneDate.month}/'
                        '${milestoneDate.year}',
                      ),
                      onTap: () async {
                        final DateTime? selectedDate =
                            await showDatePicker(
                          context: context,
                          initialDate: milestoneDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (selectedDate != null) {
                          setState(() {
                            milestoneDate = selectedDate;
                          });
                        }
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Achieved'),
                      value: achieved,
                      onChanged: (value) {
                        setState(() {
                          achieved = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _photoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Photo URL',
                        hintText: 'Optional',
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

                    final String title =
                        _titleController.text.trim();

                    final String description =
                        _descriptionController.text.trim();

                    final String category =
                        _categoryController.text.trim();

                    final String photoUrl =
                        _photoUrlController.text.trim();

                    if (childId.isEmpty ||
                        title.isEmpty ||
                        description.isEmpty ||
                        category.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill in all required fields.',
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
                        await _firestoreService.updateMilestone(
                          milestoneId: milestone.id,
                          title: title,
                          description: description,
                          milestoneDate: milestoneDate,
                          category: category,
                          achieved: achieved,
                          photoUrl: photoUrl,
                        );
                      } else {
                        await _firestoreService.createMilestone(
                          childId: childId,
                          parentId: user.uid,
                          title: title,
                          description: description,
                          milestoneDate: milestoneDate,
                          category: category,
                          achieved: achieved,
                          photoUrl: photoUrl,
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
                                  ? 'Milestone updated successfully.'
                                  : 'Milestone added successfully.',
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

  Future<void> _deleteMilestone(
    BuildContext context,
    String milestoneId,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Milestone'),
          content: const Text(
            'Are you sure you want to delete this milestone?',
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
      await _firestoreService.deleteMilestone(milestoneId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Milestone deleted successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not delete milestone: $e',
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
    final User? user =
        FirebaseAuth.instance.currentUser;

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
        title: const Text('Milestones'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getMilestones(
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
                  'Could not load milestones.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<
                  QueryDocumentSnapshot<Map<String, dynamic>>>
              milestones =
              snapshot.data?.docs ?? [];

          if (milestones.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 70,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No milestones yet.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap + to add a child milestone.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final milestone = milestones[index];
              final data = milestone.data();

              final bool achieved =
                  data['achieved'] == true;

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
                          CircleAvatar(
                            child: Icon(
                              achieved
                                  ? Icons.check
                                  : Icons.flag,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['title']
                                      ?.toString() ??
                                  'Milestone',
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
                              _showMilestoneDialog(
                                context,
                                milestone: milestone,
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(
                              Icons.delete,
                            ),
                            onPressed: () {
                              _deleteMilestone(
                                context,
                                milestone.id,
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
                        'Category: '
                        '${data['category'] ?? ''}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Date: '
                        '${_formatDate(data['milestoneDate'])}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Status: '
                        '${achieved ? 'Achieved' : 'Not achieved'}',
                      ),
                      if ((data['photoUrl'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Photo URL: '
                          '${data['photoUrl']}',
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
          _showMilestoneDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
