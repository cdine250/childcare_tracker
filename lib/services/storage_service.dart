
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  Future<String> uploadChildImage({
    required String userId,
    required String childId,
    required Uint8List imageBytes,
  }) async {
    try {
      final Reference reference = _storage
          .ref()
          .child('children')
          .child(userId)
          .child('$childId.jpg');

      final SettableMetadata metadata =
          SettableMetadata(
        contentType: 'image/jpeg',
      );

      await reference.putData(
        imageBytes,
        metadata,
      );

      return await reference.getDownloadURL();
    } catch (e) {
      throw Exception(
        'Failed to upload child image: $e',
      );
    }
  }

  Future<void> deleteChildImage(
    String userId,
    String childId,
  ) async {
    try {
      final Reference reference = _storage
          .ref()
          .child('children')
          .child(userId)
          .child('$childId.jpg');

      await reference.delete();
    } catch (_) {
      // Image deletion failure should not
      // break the application.
    }
  }
}
