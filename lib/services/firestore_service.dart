import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================
  // USERS
  // =========================

  Future<void> createUser({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
    required String profileImageUrl,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUsers() {
    return _firestore
        .collection('users')
        .snapshots();
  }

  Future<void> updateUser({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
    required String profileImageUrl,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUser(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .delete();
  }

  // =========================
  // CHILDREN
  // =========================

  Future<String> createChild({
    required String parentId,
    required String name,
    required String gender,
    required DateTime dateOfBirth,
    required String photoUrl,
    required String notes,
  }) async {
    final document =
        await _firestore.collection('children').add({
      'parentId': parentId,
      'name': name,
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'photoUrl': photoUrl,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getChildren(
    String parentId,
  ) {
    return _firestore
        .collection('children')
        .where(
          'parentId',
          isEqualTo: parentId,
        )
        .snapshots();
  }

  Future<void> updateChild({
    required String childId,
    required String name,
    required String gender,
    required DateTime dateOfBirth,
    required String photoUrl,
    required String notes,
  }) async {
    await _firestore
        .collection('children')
        .doc(childId)
        .update({
      'name': name,
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'photoUrl': photoUrl,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChild(String childId) async {
    await _firestore
        .collection('children')
        .doc(childId)
        .delete();
  }

  // =========================
  // ACTIVITIES
  // =========================

  Future<String> createActivity({
    required String childId,
    required String parentId,
    required String activityType,
    required String description,
    required DateTime activityDate,
    required int durationMinutes,
    required String notes,
  }) async {
    final document =
        await _firestore.collection('activities').add({
      'childId': childId,
      'parentId': parentId,
      'activityType': activityType,
      'description': description,
      'activityDate': Timestamp.fromDate(activityDate),
      'durationMinutes': durationMinutes,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getActivities(
    String parentId,
  ) {
    return _firestore
        .collection('activities')
        .where(
          'parentId',
          isEqualTo: parentId,
        )
        .snapshots();
  }

  Future<void> updateActivity({
    required String activityId,
    required String activityType,
    required String description,
    required DateTime activityDate,
    required int durationMinutes,
    required String notes,
  }) async {
    await _firestore
        .collection('activities')
        .doc(activityId)
        .update({
      'activityType': activityType,
      'description': description,
      'activityDate': Timestamp.fromDate(activityDate),
      'durationMinutes': durationMinutes,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteActivity(String activityId) async {
    await _firestore
        .collection('activities')
        .doc(activityId)
        .delete();
  }

  // =========================
  // MILESTONES
  // =========================

  Future<String> createMilestone({
    required String childId,
    required String parentId,
    required String title,
    required String description,
    required DateTime milestoneDate,
    required String category,
    required bool achieved,
    required String photoUrl,
  }) async {
    final document =
        await _firestore.collection('milestones').add({
      'childId': childId,
      'parentId': parentId,
      'title': title,
      'description': description,
      'milestoneDate': Timestamp.fromDate(milestoneDate),
      'category': category,
      'achieved': achieved,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMilestones(
    String parentId,
  ) {
    return _firestore
        .collection('milestones')
        .where(
          'parentId',
          isEqualTo: parentId,
        )
        .snapshots();
  }

  Future<void> updateMilestone({
    required String milestoneId,
    required String title,
    required String description,
    required DateTime milestoneDate,
    required String category,
    required bool achieved,
    required String photoUrl,
  }) async {
    await _firestore
        .collection('milestones')
        .doc(milestoneId)
        .update({
      'title': title,
      'description': description,
      'milestoneDate': Timestamp.fromDate(milestoneDate),
      'category': category,
      'achieved': achieved,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMilestone(String milestoneId) async {
    await _firestore
        .collection('milestones')
        .doc(milestoneId)
        .delete();
  }
}