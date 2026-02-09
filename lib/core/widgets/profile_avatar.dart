import 'package:flutter/material.dart';
import 'package:park_janana/core/utils/profile_image_provider.dart';

/// A reusable avatar widget that resolves profile images from Firebase Storage.
///
/// Unlike using FutureBuilder directly, this widget:
/// - Caches the resolved image in state (no re-resolve on parent rebuilds)
/// - Shows the default profile image while loading (no gray circle)
/// - Only re-resolves when [storagePath] or [fallbackUrl] actually change
class ProfileAvatar extends StatefulWidget {
  final String? storagePath;
  final String? fallbackUrl;
  final double radius;
  final Color? backgroundColor;

  const ProfileAvatar({
    super.key,
    this.storagePath,
    this.fallbackUrl,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  ImageProvider _image = ProfileImageProvider.defaultImage;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    final image = await ProfileImageProvider.resolve(
      storagePath: widget.storagePath,
      fallbackUrl: widget.fallbackUrl,
    );
    if (mounted) {
      setState(() {
        _image = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: _image,
    );
  }
}
