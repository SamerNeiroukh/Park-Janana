import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import '../models/post_model.dart';
import '../services/newsfeed_service.dart';

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
  String _uploadStatus = '';

  // Media handling
  final List<File> _selectedMedia = [];
  final ImagePicker _imagePicker = ImagePicker();
  static const int _maxMediaCount = 10;

  final List<Map<String, dynamic>> _categories = const [
    {
      'value': 'announcement',
      'label': 'הודעה',
      'icon': Icons.campaign_rounded,
      'color': AppColors.salmon,
      'description': 'הודעות חשובות לכלל העובדים',
    },
    {
      'value': 'update',
      'label': 'עדכון',
      'icon': Icons.update_rounded,
      'color': AppColors.primaryBlue,
      'description': 'עדכונים ושינויים',
    },
    {
      'value': 'event',
      'label': 'אירוע',
      'icon': Icons.event_rounded,
      'color': AppColors.success,
      'description': 'אירועים ופעילויות',
    },
    {
      'value': 'general',
      'label': 'כללי',
      'icon': Icons.article_rounded,
      'color': AppColors.greyMedium,
      'description': 'מידע כללי',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  // ===============================
  // Media Picker Methods
  // ===============================

  Future<void> _pickImages() async {
    if (_selectedMedia.length >= _maxMediaCount) {
      _showErrorSnackbar('ניתן להעלות עד $_maxMediaCount קבצים');
      return;
    }

    final remaining = _maxMediaCount - _selectedMedia.length;
    final images = await _imagePicker.pickMultiImage(
      imageQuality: 80,
      limit: remaining,
    );

    if (images.isNotEmpty) {
      setState(() {
        for (final image in images) {
          if (_selectedMedia.length < _maxMediaCount) {
            _selectedMedia.add(File(image.path));
          }
        }
      });
    }
  }

  Future<void> _pickVideo() async {
    if (_selectedMedia.length >= _maxMediaCount) {
      _showErrorSnackbar('ניתן להעלות עד $_maxMediaCount קבצים');
      return;
    }

    final video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (video != null) {
      setState(() {
        _selectedMedia.add(File(video.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedMedia.length >= _maxMediaCount) {
      _showErrorSnackbar('ניתן להעלות עד $_maxMediaCount קבצים');
      return;
    }

    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        _selectedMedia.add(File(photo.path));
      });
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
            const Text(
              'הוסף מדיה',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildMediaOption(
              icon: Icons.photo_library_rounded,
              label: 'בחר תמונות',
              subtitle: 'בחר תמונות מהגלריה',
              color: AppColors.primaryBlue,
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            const SizedBox(height: 12),
            _buildMediaOption(
              icon: Icons.videocam_rounded,
              label: 'בחר סרטון',
              subtitle: 'בחר סרטון מהגלריה',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            const SizedBox(height: 12),
            _buildMediaOption(
              icon: Icons.camera_alt_rounded,
              label: 'צלם תמונה',
              subtitle: 'פתח את המצלמה',
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
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
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

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isSubmitting = true;
      _uploadStatus = 'מכין להעלאה...';
    });

    try {
      final postId = const Uuid().v4();
      List<PostMedia> uploadedMedia = [];

      // Upload media if any selected
      if (_selectedMedia.isNotEmpty) {
        setState(() => _uploadStatus = 'מעלה קבצים...');
        uploadedMedia = await _newsfeedService.uploadPostMedia(
          postId: postId,
          files: _selectedMedia,
          onProgress: (current, total) {
            if (mounted) {
              setState(() => _uploadStatus = 'מעלה $current מתוך $total...');
            }
          },
        );
      }

      setState(() => _uploadStatus = 'מפרסם פוסט...');

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
      Navigator.of(context).pop(true);
      _showSuccessSnackbar();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('שגיאה בפרסום הפוסט');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadStatus = '';
        });
      }
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'הפוסט פורסם בהצלחה',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
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
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
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
    return Directionality(
      textDirection: TextDirection.rtl,
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
                Colors.white.withOpacity(0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
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
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'פוסט חדש',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'שתף עדכונים עם הצוות',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
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
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.category_rounded,
              size: 18,
              color: AppColors.primaryBlue.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            const Text(
              'בחר קטגוריה',
              style: TextStyle(
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
                          colors: [color, color.withOpacity(0.8)],
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : color.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
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
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.title_rounded,
              size: 18,
              color: AppColors.primaryBlue.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            const Text(
              'כותרת',
              style: TextStyle(
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
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: _inputDecoration(
            hint: 'הזן כותרת לפוסט...',
            prefixIcon: Icons.short_text_rounded,
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'יש להזין כותרת' : null,
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
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.notes_rounded,
              size: 18,
              color: AppColors.primaryBlue.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            const Text(
              'תוכן הפוסט',
              style: TextStyle(
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
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          maxLines: 5,
          style: const TextStyle(fontSize: 15, height: 1.5),
          decoration: _inputDecoration(
            hint: 'מה תרצה לשתף?',
            prefixIcon: null,
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'יש להזין תוכן' : null,
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.photo_library_rounded,
              size: 18,
              color: AppColors.primaryBlue.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'מדיה (${_selectedMedia.length}/$_maxMediaCount)',
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
                color: AppColors.greyLight.withOpacity(0.5),
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
                              ? Container(
                                  color: AppColors.greyDark,
                                  child: const Center(
                                    child: Icon(
                                      Icons.videocam_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                )
                              : Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.greyLight,
                                    child: const Icon(Icons.broken_image_rounded),
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
                              Icons.close_rounded,
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
                            child: const Text(
                              'וידאו',
                              style: TextStyle(
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
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  color: AppColors.primaryBlue.withOpacity(0.7),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedMedia.isEmpty ? 'הוסף תמונות או סרטונים' : 'הוסף עוד',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue.withOpacity(0.8),
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
        color: AppColors.greyMedium.withOpacity(0.6),
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(prefixIcon, color: AppColors.primaryBlue.withOpacity(0.5)),
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.greyLight.withOpacity(0.5),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.deepBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submitPost,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isSubmitting
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        if (_uploadStatus.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _uploadStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          'פרסם פוסט',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
