import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:park_janana/core/constants/app_colors.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;

  /// Preferred display aspect ratio (width/height), derived from the upload
  /// thumbnail. When provided it overrides the value reported by the video
  /// controller, which on Android can be the raw pixel ratio *before* the
  /// video's rotation metadata is applied (causing portrait videos to play
  /// at landscape size).
  final double? expectedAspectRatio;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.expectedAspectRatio,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isFormatError = false; // true when device can't decode the codec

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController.initialize();

      // Prefer the caller-supplied aspect ratio (from the upload thumbnail,
      // which has correct orientation) over the controller's reported value,
      // which on Android may be the raw pixel ratio before rotation is applied.
      final effectiveAspectRatio = (widget.expectedAspectRatio != null &&
              widget.expectedAspectRatio! > 0)
          ? widget.expectedAspectRatio!
          : _videoPlayerController.value.aspectRatio;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        showControls: widget.showControls,
        aspectRatio: effectiveAspectRatio,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          final isFormat = _isFormatCompatibilityError(errorMessage);
          return _buildErrorWidget(isFormatError: isFormat);
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryBlue,
          handleColor: AppColors.primaryBlue,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.grey.shade600,
        ),
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isFormatError = _isFormatCompatibilityError(e.toString());
        });
      }
    }
  }

  /// Returns true when the error is a codec/format incompatibility (not a network error).
  bool _isFormatCompatibilityError(String errorMessage) {
    final msg = errorMessage.toLowerCase();
    return msg.contains('no_exceeds_capabilities') ||
        msg.contains('format_supported') ||
        msg.contains('dolby-vision') ||
        msg.contains('dolby_vision') ||
        msg.contains('exceeds_capabilities') ||
        msg.contains('codec') && msg.contains('error');
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Widget _buildErrorWidget({bool isFormatError = false}) {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isFormatError
                    ? Colors.orange.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFormatError
                    ? Icons.video_settings_rounded
                    : Icons.broken_image_outlined,
                color: isFormatError ? Colors.orange : Colors.red.shade300,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFormatError ? 'פורמט סרטון לא נתמך' : 'שגיאה בטעינת הסרטון',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFormatError
                  ? 'הסרטון מקודד בפורמט Dolby Vision / HEVC שלא נתמך\nבמכשיר זה. נסה להעלות סרטון ב-H.264 (MP4 רגיל).'
                  : 'אירעה שגיאה בהפעלת הסרטון.\nבדוק את החיבור ונסה שוב.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isFormatError) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                    _isFormatError = false;
                  });
                  _initializePlayer();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('נסה שוב'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: AppColors.greyDark,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'טוען סרטון...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget(isFormatError: _isFormatError);
    }

    if (!_isInitialized || _chewieController == null) {
      return _buildLoadingWidget();
    }

    // Use the same effective aspect ratio that was passed to ChewieController
    final ar = _chewieController!.aspectRatio ??
        _videoPlayerController.value.aspectRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double height = width / (ar > 0 ? ar : 16 / 9);

        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * (ar > 0 ? ar : 16 / 9);
        }

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Chewie(controller: _chewieController!),
          ),
        );
      },
    );
  }
}
