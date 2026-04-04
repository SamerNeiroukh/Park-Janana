import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/post_model.dart';
import '../services/newsfeed_service.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';

class CreatePostDialog extends StatefulWidget {
  final String authorId;
  final String authorName;
  final String authorRole;
  final String authorProfilePicture;

  const CreatePostDialog({
    super.key,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.authorProfilePicture,
  });

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _newsfeedService = NewsfeedService();
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  String _selectedCategory = 'general';
  bool _isSubmitting = false;
  bool _isPickingMedia = false;
  String _uploadStatus = '';
  double _uploadProgress = 0.0;
  late AppLocalizations _l10n;

  // Media handling
  final List<File> _selectedMedia = [];
  final ImagePicker _imagePicker = ImagePicker();
  static const int _maxMediaCount = 10;

  // Local thumbnail paths for selected videos (filePath → thumbPath or null if failed)
  final Map<String, String?> _videoThumbnails = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  List<Map<String, dynamic>> get _categories => [
    {
      'value': 'announcement',
      'label': _l10n.categoryLabelAnnouncement,
      'icon': PhosphorIconsFill.megaphone,
      'color': AppColors.salmon,
      'description': _l10n.postTypeAnnouncementDesc,
    },
    {
      'value': 'update',
      'label': _l10n.categoryLabelUpdate,
      'icon': PhosphorIconsRegular.arrowsClockwise,
      'color': AppColors.primaryBlue,
      'description': _l10n.postTypeUpdateDesc,
    },
    {
      'value': 'event',
      'label': _l10n.categoryLabelEvent,
      'icon': PhosphorIconsRegular.calendarBlank,
      'color': AppColors.success,
      'description': _l10n.postTypeEventDesc,
    },
    {
      'value': 'general',
      'label': _l10n.categoryLabelGeneral,
      'icon': PhosphorIconsRegular.article,
      'color': AppColors.greyMedium,
      'description': _l10n.postTypeGeneralDesc,
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    // Delete any locally-generated preview thumbnails
    for (final path in _videoThumbnails.values) {
      if (path != null) {
        try { File(path).deleteSync(); } catch (_) {}
      }
    }
    super.dispose();
  }

  Future<void> _generateVideoPreviewThumbnail(File videoFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath =
          '${tempDir.path}/preview_${videoFile.path.hashCode}.jpg';
      final thumb = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: thumbPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 70,
      );
      if (mounted) {
        setState(() => _videoThumbnails[videoFile.path] = thumb);
      }
    } catch (e) {
      debugPrint('Preview thumbnail error: $e');
      if (mounted) {
        setState(() => _videoThumbnails[videoFile.path] = null);
      }
    }
  }

  // ===============================
  // Media Picker Methods
  // ===============================

  Future<void> _pickImages() async {
    if (_isPickingMedia) return;
    if (_selectedMedia.length >= _maxMediaCount) {
      _showErrorSnackbar(_l10n.maxMediaError(_maxMediaCount));
      return;
    }

    setState(() => _isPickingMedia = true);
    try {
      final remaining = _maxMediaCount - _selectedMedia.length;
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        limit: remaining,
      );

      if (images.isNotEmpty && mounted) {
        setState(() {
          for (final image in images) {
            if (_selectedMedia.length < _maxMediaCount) {
              _selectedMedia.add(File(image.path));
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_isPickingMedia) return;
    if (_selectedMedia.length >= _maxMediaCount) {
      _showErrorSnackbar(_l10n.maxMediaError(_maxMediaCount));
      return;
    }

    setState(() => _isPickingMedia = true);
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null && mounted) {
        final file = File(video.path);
        setState(() => _selectedMedia.add(file));
        _generateVideoPreviewThumbnail(file);
        final ext = video.path.split('.').last.toLowerCase();
        if (ext == 'mov') {
          _showInfoSnackbar(_l10n.movWarningMessage);
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(PhosphorIconsRegular.info, color: Colors.white, size: 18),
          ],
        ),
        backgroundColor: const Color(0xFF0F5398),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _takePhoto() async {
    if (_isPickingMedia) return;
    if (_selectedMedia.length >= _maxMediaCount) {
      _showErrorSnackbar(_l10n.maxMediaError(_maxMediaCount));
      return;
    }

    setState(() => _isPickingMedia = true);
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null && mounted) {
        setState(() => _selectedMedia.add(File(photo.path)));
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  void _removeMedia(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  void _showMediaPickerOptions() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _l10n.addMediaButton,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildMediaOption(
              icon: PhosphorIconsRegular.images,
              label: _l10n.pickPhotoOption,
              subtitle: _l10n.pickPhotoSubtitle,
              color: AppColors.primaryBlue,
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            const SizedBox(height: 12),
            _buildMediaOption(
              icon: PhosphorIconsRegular.videoCamera,
              label: _l10n.pickVideoOption,
              subtitle: _l10n.pickVideoSubtitle,
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            const SizedBox(height: 12),
            _buildMediaOption(
              icon: PhosphorIconsRegular.camera,
              label: _l10n.takePhotoOption,
              subtitle: _l10n.takePhotoSubtitle,
              color: AppColors.salmon,
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.greyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isVideoFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'mpeg', 'mpg', 'm4v'].contains(ext);
  }

  Widget _buildVideoPreview(File file) {
    final bool isGenerating = !_videoThumbnails.containsKey(file.path);
    final String? thumbPath = _videoThumbnails[file.path];

    if (isGenerating) {
      // Thumbnail not ready yet — show pulsing video icon + label
      return Container(
        color: const Color(0xFF1E2A3A),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _l10n.videoLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (thumbPath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(thumbPath), fit: BoxFit.cover),
          // Dark gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                ),
              ),
            ),
          ),
          const Center(
            child: Icon(
              PhosphorIconsFill.playCircle,
              color: Colors.white,
              size: 28,
              shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
            ),
          ),
        ],
      );
    }

    // Thumbnail generation failed — show static icon
    return Container(
      color: const Color(0xFF1E2A3A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(PhosphorIconsRegular.videoCamera, color: Colors.white54, size: 28),
          const SizedBox(height: 4),
          Text(
            _l10n.videoLabel,
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = _l10n.preparingUploadStatus;
    });

    try {
      final postId = const Uuid().v4();
      List<PostMedia> uploadedMedia = [];

      // Upload media if any selected
      if (_selectedMedia.isNotEmpty) {
        uploadedMedia = await _newsfeedService.uploadPostMedia(
          postId: postId,
          files: _selectedMedia,
          onProgress: (progress, status) {
            if (mounted) {
              setState(() {
                _uploadProgress = progress;
                _uploadStatus = status;
              });
            }
          },
        );
      }

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = _l10n.publishingPostStatus;
      });

      final post = PostModel(
        id: postId,
        authorId: widget.authorId,
        authorName: widget.authorName,
        authorRole: widget.authorRole,
        authorProfilePicture: widget.authorProfilePicture,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        media: uploadedMedia,
        category: _selectedCategory,
        createdAt: Timestamp.now(),
        comments: const [],
        likedBy: const [],
      );

      await _newsfeedService.createPost(post);

      if (!mounted) return;
      // Show snackbar BEFORE popping so the context is still valid
      _showSuccessSnackbar();
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Create post error: $e');
      if (!mounted) return;
      _showErrorSnackbar(_l10n.postPublishError(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
          _uploadStatus = '';
        });
      }
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _l10n.postPublishedSuccess,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            const Icon(PhosphorIconsFill.checkCircle, color: Colors.white, size: 20),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Icon(PhosphorIconsRegular.warningCircle, color: Colors.white, size: 20),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCategorySection(),
                          const SizedBox(height: 28),
                          _buildTitleField(),
                          const SizedBox(height: 18),
                          _buildContentField(),
                          const SizedBox(height: 20),
                          _buildMediaSection(),
                          const SizedBox(height: 28),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 24, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.deepBlue],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  PhosphorIconsRegular.notePencil,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _l10n.createPostTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _l10n.createPostSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Material(
            color: Colors.white.withValues(alpha: _isSubmitting ? 0.1 : 0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _isSubmitting ? null : () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  PhosphorIconsRegular.x,
                  color: Colors.white.withValues(alpha: _isSubmitting ? 0.4 : 1.0),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIconsRegular.squaresFour,
              size: 18,
              color: AppColors.primaryBlue.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              _l10n.selectCategoryLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category['value'];
            final color = category['color'] as Color;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = category['value'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [color, color.withValues(alpha: 0.8)],
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIconsRegular.textT,
              size: 18,
              color: AppColors.primaryBlue.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              _l10n.postTitleLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _titleController,
          focusNode: _titleFocus,
          textAlign: TextAlign.start,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: _inputDecoration(
            hint: _l10n.postTitleHint,
            prefixIcon: PhosphorIconsRegular.textAlignLeft,
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? _l10n.postTitleRequired : null,
          onFieldSubmitted: (_) => _contentFocus.requestFocus(),
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIconsRegular.note,
              size: 18,
              color: AppColors.primaryBlue.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              _l10n.postContentLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _contentController,
          focusNode: _contentFocus,
          textAlign: TextAlign.start,
          maxLines: 5,
          style: const TextStyle(fontSize: 15, height: 1.5),
          decoration: _inputDecoration(
            hint: _l10n.postContentHint,
            prefixIcon: null,
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? _l10n.postContentRequired : null,
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIconsRegular.images,
              size: 18,
              color: AppColors.primaryBlue.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              _l10n.mediaLabel(_selectedMedia.length, _maxMediaCount),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Media preview grid
        if (_selectedMedia.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.greyLight.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                ..._selectedMedia.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  final isVideo = _isVideoFile(file.path);

                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.greyLight,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: isVideo
                              ? _buildVideoPreview(file)
                              : Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: AppColors.greyLight,
                                    child: const Icon(PhosphorIconsRegular.imageBroken),
                                  ),
                                ),
                        ),
                      ),
                      // Remove button
                      Positioned(
                        top: -4,
                        left: -4,
                        child: GestureDetector(
                          onTap: () => _removeMedia(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.x,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Video indicator
                      if (isVideo)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _l10n.videoLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Add media button
        GestureDetector(
          onTap: _isSubmitting ? null : _showMediaPickerOptions,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsRegular.images,
                  color: AppColors.primaryBlue.withValues(alpha: 0.7),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedMedia.isEmpty ? _l10n.addMediaButton : _l10n.addMoreMediaButton,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.greyMedium.withValues(alpha: 0.6),
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(prefixIcon, color: AppColors.primaryBlue.withValues(alpha: 0.5)),
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.greyLight.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.primaryBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  Widget _buildSubmitButton() {
    if (_isSubmitting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _uploadStatus.isEmpty ? _l10n.preparingUploadShort : _uploadStatus,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${(_uploadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                minHeight: 6,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.deepBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _submitPost,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _l10n.publishPostButton,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(PhosphorIconsRegular.paperPlaneTilt, color: Colors.white, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
