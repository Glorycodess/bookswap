import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload book image
  Future<String> uploadBookImage(String filePath) async {
    try {
      String userId = _auth.currentUser!.uid;
      String fileName = const Uuid().v4();
      
      Reference ref = _storage.ref().child('books/$userId/$fileName.jpg');
      
      await ref.putFile(File(filePath));
      
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload image error: $e');
      rethrow;
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(String filePath) async {
    try {
      String userId = _auth.currentUser!.uid;
      
      Reference ref = _storage.ref().child('profiles/$userId/profile.jpg');
      
      await ref.putFile(File(filePath));
      
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload profile image error: $e');
      rethrow;
    }
  }

  // Delete image
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Delete image error: $e');
      // Don't rethrow - deletion errors shouldn't block other operations
    }
  }
}