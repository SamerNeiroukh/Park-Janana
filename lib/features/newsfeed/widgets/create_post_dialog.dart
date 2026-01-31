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

  final List<Map<String, dynamic>> _categories = [
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
        comments: [],
        likedBy: [],
      );

      await _newsfeedService.createPost(post);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הפוסט פורסם בהצלחה'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בפרסום הפוסט: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.deepBlue],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const Spacer(),
                    const Text(
                      'פוסט חדש',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.create_rounded, color: Colors.white),
                  ],
                ),
              ),

              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Category selection
                        const Text(
                          'קטגוריה',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          children: _categories.map((category) {
                            final isSelected =
                                _selectedCategory == category['value'];
                            return ChoiceChip(
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() =>
                                      _selectedCategory = category['value']);
                                }
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
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: category['color'] as Color,
                                  width: isSelected ? 0 : 1,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Title field
                        TextFormField(
                          controller: _titleController,
                          decoration: AppTheme.inputDecoration(
                            hintText: 'כותרת הפוסט',
                          ).copyWith(
                            prefixIcon:
                                const Icon(Icons.title, color: AppColors.primaryBlue),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'יש להזין כותרת';
                            }
                            return null;
                          },
                          textAlign: TextAlign.right,
                        ),

                        const SizedBox(height: 16),

                        // Content field
                        TextFormField(
                          controller: _contentController,
                          maxLines: 5,
                          decoration: AppTheme.inputDecoration(
                            hintText: 'תוכן הפוסט...',
                          ).copyWith(
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 80),
                              child: Icon(Icons.notes, color: AppColors.primaryBlue),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'יש להזין תוכן';
                            }
                            return null;
                          },
                          textAlign: TextAlign.right,
                        ),

                        const SizedBox(height: 24),

                        // Submit button
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitPost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
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
