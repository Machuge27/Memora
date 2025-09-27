import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showControls;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.showControls = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print('Initializing video: ${widget.videoUrl}');
      
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: {
          'User-Agent': 'Flutter Video Player',
        },
      );
      
      _controller.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller.value.isPlaying;
          });
        }
      });
      
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        if (widget.autoPlay) {
          await _controller.play();
          setState(() {
            _isPlaying = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF6C63FF),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller.value.hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text(
                'Failed to load video',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isInitialized = false;
                  });
                  _initializeVideo();
                },
                child: Text('Retry', style: TextStyle(color: Color(0xFF6C63FF))),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.showControls ? _toggleControls : null,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            
            // Play/Pause overlay
            if (_showControls && widget.showControls)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Center(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Progress bar
            if (_showControls && widget.showControls)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildProgressBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, VideoPlayerValue value, child) {
        final duration = value.duration;
        final position = value.position;
        
        if (duration.inMilliseconds == 0) {
          return const SizedBox();
        }
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF6C63FF),
                inactiveTrackColor: Colors.white.withOpacity(0.3),
                thumbColor: const Color(0xFF6C63FF),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 3,
              ),
              child: Slider(
                value: position.inMilliseconds.toDouble(),
                min: 0,
                max: duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  _controller.seekTo(Duration(milliseconds: value.toInt()));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}