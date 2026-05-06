import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:anxiety_anchor/audio/atmosphere_mixer.dart';

class SafePlaceGallery extends StatefulWidget {
  const SafePlaceGallery({super.key, this.showClose = true});

  final bool showClose;

  @override
  State<SafePlaceGallery> createState() => _SafePlaceGalleryState();
}

class _SafePlaceGalleryState extends State<SafePlaceGallery> {
  final PageController _pageController = PageController();
  VideoPlayerController? _videoController;
  Timer? _labelTimer;
  bool _showLabel = true;
  int _currentIndex = 0;
  String? _videoError;
  final List<_SafeVideo> _safeVideos = [
    _SafeVideo(
      label: 'Desert Oasis',
      assetPath: 'assets/videos/desert_oasis.mp4',
      thumbnailPath: 'assets/images/desert_oasis_thumbnail.png',
      atmosphereFile: 'wind.mp3',
    ),
    _SafeVideo(
      label: 'The Monastery',
      assetPath: 'assets/videos/monastery.mp4',
      thumbnailPath: 'assets/images/monastery_thumbnail.png',
      atmosphereFile: 'crickets.mp3',
    ),
    _SafeVideo(
      label: 'Mountain Bell',
      assetPath: 'assets/videos/mountain_bell.mp4',
      thumbnailPath: 'assets/images/mountain_bell_thumbnail.png',
      atmosphereFile: 'wind.mp3',
    ),
  ];
  @override
  void initState() {
    super.initState();
    if (_safeVideos.isNotEmpty) {
      _loadVista(_safeVideos.first.assetPath);
      _playAtmosphere(_safeVideos.first.atmosphereFile);
      _scheduleLabelFade();
    }
  }

  @override
  void dispose() {
    _labelTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _loadVista(_safeVideos[index].assetPath);
          _playAtmosphere(_safeVideos[index].atmosphereFile);
          _scheduleLabelFade();
        },
        itemCount: _safeVideos.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              SizedBox.expand(
                child: _buildVideoLayer(),
              ),
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showLabel ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: Center(
                    child: Text(
                      _safeVideos[_currentIndex].label.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 4.0,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 50,
                left: 20,
                child: Text(
                  'Safe Place',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              if (widget.showClose)
                Positioned(
                  top: 45,
                  right: 20,
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white30, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _playAtmosphere(String fileName) async {
    await AtmosphereMixer().playOnly(fileName, volume: 0.3);
  }

  void _scheduleLabelFade() {
    _labelTimer?.cancel();
    setState(() => _showLabel = true);
    _labelTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showLabel = false);
    });
  }

  Future<void> _loadVista(String videoName) async {
    _videoController?.dispose();
    _videoController = null;
    _videoError = null;
    if (mounted) {
      setState(() {});
    }

    try {
      final controller = VideoPlayerController.asset(
        videoName,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      await controller.setVolume(0.0);
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _videoController = controller);
    } catch (error) {
      debugPrint('Safe Place video error: $error');
      if (mounted) {
        setState(() => _videoError = error.toString());
      }
    }
  }

  Widget _buildVideoLayer() {
    final controller = _videoController;
    if (_videoError != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _safeVideos[_currentIndex].thumbnailPath,
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.35)),
          const Center(
            child: Text(
              'Video unavailable',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white24));
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _SafeVideo {
  const _SafeVideo({
    required this.label,
    required this.assetPath,
    required this.thumbnailPath,
    required this.atmosphereFile,
  });

  final String label;
  final String assetPath;
  final String thumbnailPath;
  final String atmosphereFile;
}
