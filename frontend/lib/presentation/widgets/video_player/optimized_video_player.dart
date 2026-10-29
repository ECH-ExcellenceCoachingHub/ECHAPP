import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:better_player_enhanced/better_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/video_progress_service.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/screen_wakelock.dart';
import 'package:excellencecoachinghub/models/lesson_video.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/video_checkpoints.dart';
import 'dart:async';

class OptimizedVideoPlayer extends StatefulWidget {
  final String? videoId;
  final String? videoUrl;
  final String title;
  final String description;
  final bool showAppBar;
  final VoidCallback? onFullScreen;
  final double? aspectRatio;
  /// "Pause and think" questions of a generated lesson video (empty for normal videos).
  final List<VideoInteraction> interactions;

  const OptimizedVideoPlayer({
    super.key,
    this.videoId,
    this.videoUrl,
    required this.title,
    required this.description,
    this.showAppBar = false,
    this.onFullScreen,
    this.aspectRatio,
    this.interactions = const [],
  }) : assert(videoUrl != null);

  @override
  State<OptimizedVideoPlayer> createState() => _OptimizedVideoPlayerState();
}

class _OptimizedVideoPlayerState extends State<OptimizedVideoPlayer> {
  BetterPlayerController? _betterPlayerController;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isOffline = false;
  StreamSubscription? _connectivitySubscription;
  bool _isDataSaver = false;
  final double _playbackSpeed = 1.0;
  bool _isSlowNetwork = false;
  final ScreenWakelock _wakelock = ScreenWakelock();
  late final CheckpointTracker _checkpoints = CheckpointTracker(widget.interactions);
  VideoInteraction? _activeCheck;

  void _handleCheckpoint(Duration position) {
    if (_activeCheck != null || _checkpoints.isEmpty) return;
    final it = _checkpoints.onPosition(position);
    if (it == null) return;
    _betterPlayerController?.pause();
    // Leave full screen so the question is visible on top of the inline player.
    if (_betterPlayerController?.isFullScreen == true) _betterPlayerController?.exitFullScreen();
    if (mounted) setState(() => _activeCheck = it);
  }

  Future<void> _continueAfterCheck() async {
    final it = _activeCheck;
    if (it == null) return;
    setState(() => _activeCheck = null);
    await _betterPlayerController?.seekTo(it.resumeAt);
    await _betterPlayerController?.play();
  }

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
    _initPlayer();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      final isNowOffline = results.isEmpty || results.contains(ConnectivityResult.none);
      
      // Detect slow network (mobile or limited connections)
      final isSlowConnection = results.contains(ConnectivityResult.mobile) || 
                                results.isEmpty;
      
      if (!isNowOffline && _isOffline) {
        // Back online, retry if there was an error
        if (_errorMessage != null) {
          _retryPlayback();
        }
      }
      
      if (mounted) {
        setState(() {
          _isOffline = isNowOffline;
          _isSlowNetwork = isSlowConnection;
        });
        
        // Adjust playback quality based on network
        if (_betterPlayerController != null && !isNowOffline) {
          _adjustQualityForNetwork(isSlowConnection);
        }
      }
    });
  }
  
  void _adjustQualityForNetwork(bool isSlow) {
    // If slow network, prefer lower quality if available
    // This is a placeholder - better_player has quality selection built-in
    // The user can manually select quality, but we could auto-select on slow networks
    if (isSlow && _isDataSaver) {
      // Could implement auto-quality selection here
      // For now, data saver mode reduces volume which helps slightly
      _betterPlayerController?.setVolume(0.5);
    } else {
      _betterPlayerController?.setVolume(1.0);
    }
  }

  void _toggleDataSaver() {
    setState(() {
      _isDataSaver = !_isDataSaver;
    });
    _betterPlayerController?.setVolume(_isDataSaver ? 0.5 : 1.0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isDataSaver ? 'Data Saver On' : 'Data Saver Off'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  String _getOptimizedUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // Check if it's a local file path
    if (url.startsWith('/') || url.startsWith('file://')) {
      // It's a local file - return as-is for mobile, convert for Windows
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        return url.startsWith('file://') ? url.replaceFirst('file://', '').replaceAll('/', '\\') : url.replaceAll('/', '\\');
      }
      // For iOS, ensure file:// prefix
      if (!url.startsWith('file://') && defaultTargetPlatform == TargetPlatform.iOS) {
        return 'file://$url';
      }
      // For Android, use raw path without file:// prefix (ExoPlayer needs raw path)
      if (url.startsWith('file://') && defaultTargetPlatform == TargetPlatform.android) {
        return url.replaceFirst('file://', '');
      }
      return url;
    }

    // Convert S3 URL to CloudFront URL and ensure HTTPS
    String processedUrl = url;
    if (processedUrl.contains('echcoahing.s3.amazonaws.com')) {
      processedUrl = processedUrl.replaceFirst('echcoahing.s3.amazonaws.com', 'd3ofk5ujo941v.cloudfront.net');
    }

    if (processedUrl.startsWith('http://')) {
      processedUrl = processedUrl.replaceFirst('http://', 'https://');
    }

    // For HLS streaming, ensure .m3u8 extension for adaptive streaming
    if (processedUrl.startsWith('https') && !processedUrl.contains('.m3u8') && !processedUrl.contains('.mpd')) {
      // If it's a regular MP4, we'll still play it but better_player will handle it
      // For production, you should convert videos to HLS format
    }

    return processedUrl;
  }

  void _initPlayer() async {
    if (widget.videoUrl == null) {
      setState(() {
        _errorMessage = "Video source is missing (URL is null)";
        _isInitialized = true;
      });
      return;
    }

    final optimizedUrl = _getOptimizedUrl(widget.videoUrl);
    print('OptimizedVideoPlayer: Original URL: ${widget.videoUrl}');
    print('OptimizedVideoPlayer: Optimized URL: $optimizedUrl');

    if (optimizedUrl.isEmpty) {
      setState(() {
        _errorMessage = "Video URL is empty";
        _isInitialized = true;
      });
      return;
    }

    // Retrieve saved progress
    Duration startAt = Duration.zero;
    if (widget.videoId != null) {
      startAt = await videoProgressService.getProgress(widget.videoId!);
    }

    final isNetwork = optimizedUrl.startsWith('http') || kIsWeb;
    print('OptimizedVideoPlayer: isNetwork: $isNetwork');

    BetterPlayerConfiguration betterPlayerConfiguration = BetterPlayerConfiguration(
      autoPlay: false,
      looping: false,
      aspectRatio: widget.aspectRatio,
      fit: BoxFit.contain,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        enablePlayPause: true,
        enableMute: true,
        enableFullscreen: true,
        enableProgressBar: true,
        enableProgressText: true,
        enableSkips: true,
        enablePlaybackSpeed: true,
        enableQualities: true,
        controlBarColor: Colors.black54,
        progressBarPlayedColor: AppTheme.primaryGreen,
        progressBarHandleColor: AppTheme.primaryGreen,
        progressBarBufferedColor: AppTheme.primaryGreen.withOpacity(0.3),
        progressBarBackgroundColor: Colors.grey,
        iconsColor: Colors.white,
        overflowMenuCustomItems: widget.showAppBar
            ? const []
            : [
                BetterPlayerOverflowMenuItem(
                  Icons.data_usage_outlined,
                  'Data Saver',
                  () {
                    _toggleDataSaver();
                  },
                ),
              ],
      ),
      handleLifecycle: true,
      // Keeps the screen on in full screen. Inline playback is covered by
      // _wakelock below, which better_player does not handle on its own.
      allowedScreenSleep: false,
      errorBuilder: (context, errorMessage) {
        return _buildErrorPlaceholder(
          icon: Icons.error_outline,
          title: 'Playback Error',
          message: errorMessage ?? 'Something went wrong while playing this video.',
          onRetry: _retryPlayback,
        );
      },
      placeholder: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      ),
    );

    // Configure for adaptive streaming if using HLS/DASH
    BetterPlayerDataSource betterPlayerDataSource;
    if (isNetwork) {
      betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        optimizedUrl,
        notificationConfiguration: BetterPlayerNotificationConfiguration(
          showNotification: false,
        ),
        cacheConfiguration: BetterPlayerCacheConfiguration(
          useCache: true,
          preCacheSize: 20 * 1024 * 1024, // 20MB pre-cache (doubled for slow internet)
          maxCacheSize: 200 * 1024 * 1024, // 200MB max cache (doubled for more buffering)
          maxCacheFileSize: 100 * 1024 * 1024, // 100MB per file (doubled)
        ),
        bufferingConfiguration: BetterPlayerBufferingConfiguration(
          minBufferMs: 30000, // 30 seconds minimum buffer (increased for slow internet)
          maxBufferMs: 120000, // 120 seconds maximum buffer (2 minutes for very slow connections)
          bufferForPlaybackMs: 5000, // 5 seconds for playback start (increased for slow internet)
          bufferForPlaybackAfterRebufferMs: 10000, // 10 seconds after rebuffer (increased for stability)
        ),
      );
    } else if (!kIsWeb) {
      betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        optimizedUrl,
      );
    } else {
      setState(() {
        _errorMessage = "Local files are not supported on web";
        _isInitialized = true;
      });
      return;
    }

    try {
      _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
      await _betterPlayerController!.setupDataSource(betterPlayerDataSource);

      if (startAt > Duration.zero) {
        await _betterPlayerController!.seekTo(startAt);
      }

      // Listen to position changes for progress saving, and keep the screen
      // awake for as long as the video is actually playing
      _betterPlayerController!.addEventsListener((event) {
        switch (event.betterPlayerEventType) {
          case BetterPlayerEventType.progress:
            final position = _betterPlayerController!.videoPlayerController!.value.position;
            _handleCheckpoint(position);
            if (widget.videoId != null && position.inSeconds % 5 == 0 && position.inSeconds > 0) {
              videoProgressService.saveProgress(widget.videoId!, position);
            }
            break;
          case BetterPlayerEventType.play:
            _wakelock.acquire();
            break;
          case BetterPlayerEventType.pause:
          case BetterPlayerEventType.finished:
          case BetterPlayerEventType.exception:
            _wakelock.release();
            break;
          case BetterPlayerEventType.hideFullscreen:
            // better_player drops the wakelock whenever it leaves full screen,
            // even though playback continues inline, so put ours back.
            ScreenWakelock.reassert();
            break;
          default:
            break;
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load video: $error";
          _isInitialized = true;
        });
      }
    }
  }

  void _retryPlayback() {
    setState(() {
      _errorMessage = null;
      _isInitialized = false;
    });

    _wakelock.release();
    _betterPlayerController?.removeEventsListener((event) {});
    _betterPlayerController?.dispose();
    _betterPlayerController = null;
    
    _initPlayer();
  }

  @override
  void dispose() {
    _wakelock.release();
    _connectivitySubscription?.cancel();
    _betterPlayerController?.removeEventsListener((event) {});
    _betterPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNetworkVideo = widget.videoUrl != null && (widget.videoUrl!.startsWith('http') || kIsWeb);
    
    // Only show offline error for network videos
    if (_isOffline && isNetworkVideo) {
      return _buildErrorPlaceholder(
        icon: Icons.wifi_off_outlined,
        title: 'No Internet Connection',
        message: 'Please check your network settings and try again.',
        onRetry: _retryPlayback,
      );
    }

    if (_errorMessage != null) {
      return _buildErrorPlaceholder(
        icon: Icons.error_outline,
        title: 'Playback Error',
        message: 'Something went wrong while playing this video.\n$_errorMessage',
        onRetry: _retryPlayback,
      );
    }

    if (!_isInitialized || _betterPlayerController == null) {
      return Container(
        color: Colors.black,
        height: ResponsiveBreakpoints.isDesktop(context) ? 400 : 200,
        child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.data_usage),
              onPressed: () {
                setState(() {
                  _isDataSaver = !_isDataSaver;
                });
                _betterPlayerController?.setVolume(_isDataSaver ? 0.5 : 1.0);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isDataSaver ? 'Data Saver On' : 'Data Saver Off'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Data Saver',
            ),
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: widget.onFullScreen ?? () => _betterPlayerController?.toggleFullScreen(),
            ),
          ],
        ),
        body: _buildPlayer(),
      );
    }

    return _buildPlayer();
  }

  Widget _buildPlayer() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(children: [
        Positioned.fill(child: BetterPlayer(controller: _betterPlayerController!)),
        if (_activeCheck != null)
          Positioned.fill(
            child: VideoCheckOverlay(key: ValueKey('check-${_activeCheck!.id}'), interaction: _activeCheck!, onContinue: _continueAfterCheck),
          ),
      ]),
    );
  }

  Widget _buildErrorPlaceholder({
    required IconData icon,
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
