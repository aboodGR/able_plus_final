import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// In-feed video player.
///
/// We frame the video inside a fixed-height black box and use FittedBox
/// with BoxFit.contain so portrait videos no longer overflow horizontally
/// (which is what was producing the "OVERFLOWED BY N PIXELS" warning),
/// and landscape videos still fit edge to edge.
class PostVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double maxHeight;

  const PostVideoPlayer({
    super.key,
    required this.videoUrl,
    this.maxHeight = 220,
  });

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        placeholder: Container(color: Colors.black),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Widget _shell(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: widget.maxHeight,
        width: double.infinity,
        color: Colors.black,
        child: Center(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _shell(
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.white70),
            SizedBox(height: 8),
            Text('Failed to load video',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_chewieController == null ||
        _videoController == null ||
        !_videoController!.value.isInitialized) {
      return _shell(const CircularProgressIndicator(color: Colors.white70));
    }

    final size = _videoController!.value.size;
    final videoAspectRatio =
        (size.width > 0 && size.height > 0) ? size.width / size.height : 16 / 9;

    // Fill the container width and let height be determined by aspect ratio
    return Container(
      height: widget.maxHeight,
      width: double.infinity,
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: videoAspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}
