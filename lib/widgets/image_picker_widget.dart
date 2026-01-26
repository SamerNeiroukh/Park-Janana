import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class ImagePickerWidget extends StatefulWidget {
  final List<String> initialImages;
  final Function(List<String>) onImagesChanged;
  final bool enabled;
  final String? taskId; // For uploading images during task creation/editing

  const ImagePickerWidget({
    super.key,
    this.initialImages = const [],
    required this.onImagesChanged,
    this.enabled = true,
    this.taskId,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImageService _imageService = ImageService();
  List<String> _imageUrls = [];
  List<XFile> _pendingImages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImages);
  }

  Future<void> _pickImages() async {
    if (!widget.enabled) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _buildImageSourceBottomSheet(),
    );

    if (result != null) {
      try {
        List<XFile> newImages = [];
        
        if (result == 'camera') {
          newImages = await _imageService.pickImages(fromCamera: true);
        } else if (result == 'gallery') {
          newImages = await _imageService.pickImages(fromCamera: false, multiSelect: true);
        }

        if (newImages.isNotEmpty) {
          // Filter out images that are too large
          final validImages = <XFile>[];
          for (final image in newImages) {
            if (await ImageService.isImageSizeAcceptable(image)) {
              validImages.add(image);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('תמונה ${image.name} גדולה מדי (מעל 10MB)')),
                );
              }
            }
          }

          if (validImages.isNotEmpty) {
            setState(() {
              _pendingImages.addAll(validImages);
            });

            // Upload images if taskId is provided, otherwise store locally
            if (widget.taskId != null) {
              await _uploadPendingImages();
            } else {
              // For task creation, we'll handle upload later when task is created
              widget.onImagesChanged([..._imageUrls, ..._pendingImages.map((e) => e.path)]);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('שגיאה בבחירת תמונות: $e')),
          );
        }
      }
    }
  }

  Future<void> _uploadPendingImages() async {
    if (_pendingImages.isEmpty || widget.taskId == null) return;

    setState(() => _isUploading = true);

    try {
      final uploadedUrls = await _imageService.uploadMultipleTaskImages(
        widget.taskId!,
        _pendingImages,
      );

      setState(() {
        _imageUrls.addAll(uploadedUrls);
        _pendingImages.clear();
        _isUploading = false;
      });

      widget.onImagesChanged(_imageUrls);
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בהעלאת תמונות: $e')),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    if (!widget.enabled) return;

    if (index < _imageUrls.length) {
      // Remove uploaded image
      final imageUrl = _imageUrls[index];
      try {
        await _imageService.deleteTaskImage(imageUrl);
        setState(() {
          _imageUrls.removeAt(index);
        });
        widget.onImagesChanged(_imageUrls);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('שגיאה במחיקת תמונה: $e')),
          );
        }
      }
    } else {
      // Remove pending image
      final pendingIndex = index - _imageUrls.length;
      setState(() {
        _pendingImages.removeAt(pendingIndex);
      });
      widget.onImagesChanged([..._imageUrls, ..._pendingImages.map((e) => e.path)]);
    }
  }

  Widget _buildImageSourceBottomSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('בחר מקור תמונה', style: AppTheme.sectionTitle),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceButton(
                  icon: Icons.camera_alt,
                  label: 'מצלמה',
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                _buildSourceButton(
                  icon: Icons.photo_library,
                  label: 'גלריה',
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('תמונות', style: AppTheme.sectionTitle),
            const Spacer(),
            if (_isUploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Image grid
        if (_imageUrls.isNotEmpty || _pendingImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _imageUrls.length + _pendingImages.length + (widget.enabled ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _imageUrls.length + _pendingImages.length) {
                // Add button
                return _buildAddImageButton();
              } else if (index < _imageUrls.length) {
                // Uploaded image
                return _buildImageThumbnail(_imageUrls[index], index, isUploaded: true);
              } else {
                // Pending image
                final pendingIndex = index - _imageUrls.length;
                return _buildImageThumbnail(_pendingImages[pendingIndex].path, index, isUploaded: false);
              }
            },
          )
        else if (widget.enabled)
          _buildAddImageButton(),
        
        if (_imageUrls.isEmpty && _pendingImages.isEmpty && !widget.enabled)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('אין תמונות', style: TextStyle(color: Colors.grey)),
            ),
          ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
            SizedBox(height: 4),
            Text('הוסף תמונה', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String imagePath, int index, {required bool isUploaded}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isUploaded
                ? CachedNetworkImage(
                    imageUrl: imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  )
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
          ),
        ),
        if (widget.enabled)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        if (!isUploaded)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ממתין להעלאה',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}