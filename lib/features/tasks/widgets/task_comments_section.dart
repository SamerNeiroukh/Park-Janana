import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';

class TaskCommentsSection extends StatelessWidget {
  final List<Map<String, dynamic>> comments;
  final String taskId;

  const TaskCommentsSection(
      {super.key, required this.comments, required this.taskId});

  Future<String> _fetchUserName(String uid, String fallback) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['fullName'] ?? fallback;
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(l10n.noCommentsEmpty, style: AppTheme.bodyText),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: comments.map((comment) {
        final message = comment['message'] ?? '';
        final uid = comment['by'] ?? '';
        final timestamp =
            comment['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
        final time = DateTime.fromMillisecondsSinceEpoch(timestamp);

        return FutureBuilder<String>(
          future: _fetchUserName(uid, l10n.userFallbackName),
          builder: (context, snapshot) {
            final name = snapshot.data ?? '...';

            return Card(
              elevation: 1,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(PhosphorIconsRegular.chatText, color: AppColors.primary),
                title: Text(message, textAlign: TextAlign.right),
                subtitle: Text(
                  '$name • ${DateFormat('dd/MM/yyyy HH:mm').format(time)}',
                  textAlign: TextAlign.right,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
