import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/interstitial_ad_service.dart';
import '../services/storage_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'activities_screen.dart';
import 'milestones_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  final InterstitialAdService _interstitialAdService =
      InterstitialAdService()..loadAd();

  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  final TextEditingController _editNameController =
      TextEditingController();

  final TextEditingController _editNotesController =
      TextEditingController();

  Future<Uint8List?> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        return null;
      }

      return await image.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  Future<void> _showAddChildDialog(
    BuildContext context,
    String userId,
  ) async {
    _nameController.clear();
    _notesController.clear();

    String gender = 'Male';
    DateTime dateOfBirth = DateTime.now();
    Uint8List? selectedImage;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Child'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final Uint8List? image =
                            await _pickImage();

                        if (image != null) {
                          setState(() {
                            selectedImage = image;
                          });
                        }
                      },
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                            width: 2,
                          ),
                        ),
                        child: selectedImage == null
                            ? const Icon(
                                Icons.add_a_photo,
                                size: 40,
                              )
                            : ClipOval(
                                child: Image.memory(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to choose a child photo',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Child Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            gender = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today,
                      ),
                      title: const Text('Date of Birth'),
                      subtitle: Text(
                        '${dateOfBirth.day}/'
                        '${dateOfBirth.month}/'
                        '${dateOfBirth.year}',
                      ),
                      onTap: () async {
                        final DateTime? selectedDate =
                            await showDatePicker(
                          context: context,
                          initialDate: dateOfBirth,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (selectedDate != null) {
                          setState(() {
                            dateOfBirth = selectedDate;
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
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String name =
                        _nameController.text.trim();

                    final String notes =
                        _notesController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter the child name.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final String childId =
                          await _firestoreService.createChild(
                        parentId: userId,
                        name: name,
                        gender: gender,
                        dateOfBirth: dateOfBirth,
                        photoUrl: '',
                        notes: notes,
                      );

                      if (selectedImage != null) {
                        try {
                          final String photoUrl =
                              await _storageService
                                  .uploadChildImage(
                            userId: userId,
                            childId: childId,
                            imageBytes: selectedImage!,
                          );

                          await _firestoreService.updateChild(
                            childId: childId,
                            name: name,
                            gender: gender,
                            dateOfBirth: dateOfBirth,
                            photoUrl: photoUrl,
                            notes: notes,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Photo upload failed: $e',
                                ),
                              ),
                            );
                          }
                        }
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Child added successfully.',
                            ),
                          ),
                        );
                      }

                      _interstitialAdService.showAd();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not add child: $e',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditChildDialog(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> child,
    String userId,
  ) async {
    final Map<String, dynamic> data = child.data() ?? {};

    _editNameController.text =
        data['name']?.toString() ?? '';

    _editNotesController.text =
        data['notes']?.toString() ?? '';

    String gender =
        data['gender']?.toString() ?? 'Male';

    DateTime dateOfBirth = DateTime.now();

    final Timestamp? timestamp =
        data['dateOfBirth'] as Timestamp?;

    if (timestamp != null) {
      dateOfBirth = timestamp.toDate();
    }

    String photoUrl =
        data['photoUrl']?.toString() ?? '';

    Uint8List? selectedImage;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Child'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final Uint8List? image =
                            await _pickImage();

                        if (image != null) {
                          setState(() {
                            selectedImage = image;
                          });
                        }
                      },
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                            width: 2,
                          ),
                        ),
                        child: selectedImage != null
                            ? ClipOval(
                                child: Image.memory(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : photoUrl.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return const Icon(
                                          Icons.person,
                                          size: 50,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                  ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to change the child photo',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _editNameController,
                      decoration: const InputDecoration(
                        labelText: 'Child Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            gender = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today,
                      ),
                      title: const Text('Date of Birth'),
                      subtitle: Text(
                        '${dateOfBirth.day}/'
                        '${dateOfBirth.month}/'
                        '${dateOfBirth.year}',
                      ),
                      onTap: () async {
                        final DateTime? selectedDate =
                            await showDatePicker(
                          context: context,
                          initialDate: dateOfBirth,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (selectedDate != null) {
                          setState(() {
                            dateOfBirth = selectedDate;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _editNotesController,
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
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String name =
                        _editNameController.text.trim();

                    final String notes =
                        _editNotesController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter the child name.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      if (selectedImage != null) {
                        try {
                          photoUrl =
                              await _storageService
                                  .uploadChildImage(
                            userId: userId,
                            childId: child.id,
                            imageBytes: selectedImage!,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Photo upload failed: $e',
                                ),
                              ),
                            );
                          }
                        }
                      }

                      await _firestoreService.updateChild(
                        childId: child.id,
                        name: name,
                        gender: gender,
                        dateOfBirth: dateOfBirth,
                        photoUrl: photoUrl,
                        notes: notes,
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Child updated successfully.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not update child: $e',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteChild(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> child,
    String userId,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Child'),
          content: const Text(
            'Are you sure you want to delete this child?',
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
      await _firestoreService.deleteChild(child.id);

      try {
        await _storageService.deleteChildImage(
          userId,
          child.id,
        );
      } catch (_) {
        // Storage failure should not break deletion.
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Child deleted successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not delete child: $e',
            ),
          ),
        );
      }
    }
  }

  Widget _buildChildPhoto(
    BuildContext context,
    String photoUrl,
  ) {
    if (photoUrl.isEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.child_care),
      );
    }

    return CircleAvatar(
      radius: 30,
      backgroundImage: NetworkImage(photoUrl),
      onBackgroundImageError: (_, __) {},
      child: const SizedBox.shrink(),
    );
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
        title: const Text(
          'Claudine Childcare Tracker',
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.child_care,
                    size: 45,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Childcare Tracker',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.child_care),
              title: const Text('Children'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.directions_run,
              ),
              title: const Text('Activities'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ActivitiesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.emoji_events,
              ),
              title: const Text('Milestones'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MilestonesScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                Navigator.pop(context);
                await _authService.signOut();
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getChildren(
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
                  'Could not load children.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<
                  QueryDocumentSnapshot<Map<String, dynamic>>>
              children =
              snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email ?? '',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Manage your children, '
                        'activities and milestones '
                        'in one place.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Children',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 12),
              if (children.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.child_care,
                          size: 60,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No children yet.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap + to add your first child.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ...children.map(
                (child) {
                  final Map<String, dynamic> data =
                      child.data();

                  final String name =
                      data['name']?.toString() ??
                          'Child';

                  final String gender =
                      data['gender']?.toString() ??
                          'Unknown';

                  final String notes =
                      data['notes']?.toString() ?? '';

                  final String photoUrl =
                      data['photoUrl']?.toString() ?? '';

                  String dateOfBirth =
                      'Unknown';

                  final Timestamp? dob =
                      data['dateOfBirth'] as Timestamp?;

                  if (dob != null) {
                    final DateTime date =
                        dob.toDate();

                    dateOfBirth =
                        '${date.day}/'
                        '${date.month}/'
                        '${date.year}';
                  }

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildChildPhoto(
                                context,
                                photoUrl,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      gender,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(
                                  Icons.edit,
                                ),
                                onPressed: () {
                                  _showEditChildDialog(
                                    context,
                                    child,
                                    user.uid,
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(
                                  Icons.delete,
                                ),
                                onPressed: () {
                                  _deleteChild(
                                    context,
                                    child,
                                    user.uid,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment:
                                Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date of Birth: '
                                  '$dateOfBirth',
                                ),
                                if (notes.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Notes: $notes',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const SafeArea(
        child: BannerAdWidget(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddChildDialog(
            context,
            user.uid,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}