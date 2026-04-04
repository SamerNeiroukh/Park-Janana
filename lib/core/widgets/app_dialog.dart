import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';

/// Displays a modern, polished confirmation dialog with an icon, title,
/// message and two action buttons (cancel + confirm).
///
/// Returns `true` if the user confirmed, `false` / `null` otherwise.
Future<bool?> showAppDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,

  /// Falls back to the localized "Cancel" string when omitted.
  String? cancelText,

  /// Icon shown inside the coloured circle.
  IconData icon = PhosphorIconsRegular.question,

  /// Gradient colours for the icon circle.
  /// Defaults to a blue gradient. Pass a red pair for destructive actions.
  List<Color>? iconGradient,

  /// When true the confirm button text is coloured red.
  bool isDestructive = false,
}) {
  final gradient = iconGradient ??
      (isDestructive
          ? const [Color(0xFFEE7752), Color(0xFFD8363A)]
          : const [Color(0xFF56C2F4), Color(0xFF1E88E5)]);

  final confirmColor =
      isDestructive ? const Color(0xFFD8363A) : const Color(0xFF1565C0);

  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, _) {
      final resolvedCancelText =
          cancelText ?? AppLocalizations.of(ctx).cancelButton;
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.88,
            constraints: const BoxConstraints(maxWidth: 380),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 36,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon + texts ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
                  child: Column(
                    children: [
                      // Icon circle
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: gradient.last.withValues(alpha: 0.38),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 38, color: Colors.white),
                      ),
                      const SizedBox(height: 22),

                      // Title
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Message
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // ── Divider ───────────────────────────────────────────────
                const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                // ── Buttons ───────────────────────────────────────────────
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black45,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: const RoundedRectangleBorder(),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(
                            resolvedCancelText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Vertical separator
                      Container(
                        width: 1,
                        color: const Color(0xFFEEEEEE),
                      ),

                      // Confirm
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: confirmColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: const RoundedRectangleBorder(),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, _, child) {
      final clamped = anim.value.clamp(0.0, 1.0);
      final curve = Curves.easeOutBack.transform(clamped);
      return Opacity(
        opacity: clamped,
        child: Transform.scale(scale: 0.82 + 0.18 * curve, child: child),
      );
    },
  );
}
