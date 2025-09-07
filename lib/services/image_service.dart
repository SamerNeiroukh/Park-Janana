import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../utils/custom_exception.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick multiple images from gallery or single image from camera
  Future<List<XFile>> pickImages({bool fromCamera = false, bool multiSelect = true}) async {
    try {
      if (fromCamera) {
        final XFile? image = await _picker.pickImage(source: ImageSource.camera);
        return image != null ? [image] : [];
      } else {
        if (multiSelect) {
          final List<XFile> images = await _picker.pickMultiImage();
          return images;
        } else {
          final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
          return image != null ? [image] : [];
        }
      }
    } catch (e) {
      throw CustomException('שגיאה בבחירת תמונות: $e');
    }
  }

  /// Upload image to Firebase Storage
  Future<String> uploadTaskImage(String taskId, XFile imageFile) async {
    try {
      // Generate unique filename
      final String fileName = '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'storage/tasks/$taskId/$fileName';
      
      // Create reference and upload
      final Reference ref = _storage.ref(path);
      final File file = File(imageFile.path);
      
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw CustomException('שגיאה בהעלאת תמונה: $e');
    }
  }

  /// Upload multiple images and return list of URLs
  Future<List<String>> uploadMultipleTaskImages(String taskId, List<XFile> imageFiles) async {
    final List<String> uploadedUrls = [];
    
    for (final imageFile in imageFiles) {
      try {
        final String url = await uploadTaskImage(taskId, imageFile);
        uploadedUrls.add(url);
      } catch (e) {
        // Continue with other images even if one fails
        print('Failed to upload image ${imageFile.name}: $e');
      }
    }
    
    return uploadedUrls;
  }

  /// Delete image from Firebase Storage
  Future<void> deleteTaskImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Failed to delete image: $e');
      // Don't throw error for delete operations to avoid blocking other operations
    }
  }

  /// Delete multiple images
  Future<void> deleteMultipleTaskImages(List<String> imageUrls) async {
    for (final imageUrl in imageUrls) {
      await deleteTaskImage(imageUrl);
    }
  }

  /// Get image file size in MB
  static Future<double> getImageSizeMB(XFile imageFile) async {
    final File file = File(imageFile.path);
    final int bytes = await file.length();
    return bytes / (1024 * 1024); // Convert bytes to MB
  }

  /// Check if image size is within acceptable limits (10MB)
  static Future<bool> isImageSizeAcceptable(XFile imageFile) async {
    final double sizeMB = await getImageSizeMB(imageFile);
    return sizeMB <= 10.0; // 10MB limit
  }
}