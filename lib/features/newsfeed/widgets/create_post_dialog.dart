import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_theme.dart';
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

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _newsfeedService = NewsfeedService();

  String _selectedCategory = 'general';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = const [
    {
      'value': 'announcement',
      'label': 'הודעה',
      'icon': Icons.campaign_rounded,
      'color': AppColors.salmon,
    },
    {
      'value': 'update',
      'label': 'עדכון',
      'icon': Icons.update_rounded,
      'color': AppColors.primaryBlue,
    },
    {
      'value': 'event',
      'label': 'אירוע',
      'icon': Icons.event_rounded,
      'color': AppColors.success,
    },
    {
      'value': 'general',
      'label': 'כללי',
      'icon': Icons.article_rounded,
      'color': AppColors.greyMedium,
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final post = PostModel(
        id: const Uuid().v4(),
        authorId: widget.authorId,
        authorName: widget.authorName,
        authorRole: widget.authorRole,
        authorProfilePicture: widget.authorProfilePicture,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        createdAt: Timestamp.now(),
        comments: const [],
        likedBy: const [],
      );

      await _newsfeedService.createPost(post);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('הפוסט פורסם בהצלחה'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בפרסום הפוסט: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== Header =====
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.deepBlue],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                    const Spacer(),
                    const Row(
                      children: [
                        Text(
                          'פוסט חדש',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.edit_note_rounded, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),

              // ===== Form =====
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Category
                        const Text(
                          'קטגוריה',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _categories.map((category) {
                            final isSelected =
                                _selectedCategory == category['value'];

                            return ChoiceChip(
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory =
                                      category['value'] as String;
                                });
                              },
                              avatar: Icon(
                                category['icon'] as IconData,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : category['color'] as Color,
                              ),
                              label: Text(category['label'] as String),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: category['color'] as Color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                                side: BorderSide(
                                  color: category['color'] as Color,
                                  width: isSelected ? 0 : 1,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        TextFormField(
                          controller: _titleController,
                          textAlign: TextAlign.right,
                          decoration: AppTheme.inputDecoration(
                            hintText: 'כותרת הפוסט',
                          ).copyWith(
                            prefixIcon: const Icon(
                              Icons.title_rounded,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'יש להזין כותרת'
                                  : null,
                        ),

                        const SizedBox(height: 16),

                        // Content
                        TextFormField(
                          controller: _contentController,
                          textAlign: TextAlign.right,
                          maxLines: 5,
                          decoration: AppTheme.inputDecoration(
                            hintText: 'תוכן הפוסט...',
                          ).copyWith(
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 80),
                              child: Icon(
                                Icons.notes_rounded,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'יש להזין תוכן'
                                  : null,
                        ),

                        const SizedBox(height: 28),

                        // Submit
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitPost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'פרסם',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.send_rounded, size: 20),
                                  ],
                                ),
                        ),
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
}
