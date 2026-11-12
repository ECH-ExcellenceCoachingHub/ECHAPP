import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/video_progress_service.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/screen_wakelock.dart';
import 'package:excellencecoachinghub/models/lesson_video.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/video_checkpoints.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/video_playback_requests.dart';
import 'dart:io';
import 'dart:async';

class CustomVideoPlayer extends StatefulWidget {
  final String? videoId;
  final String? videoUrl;
  final mk.Player? externalPlayer;
  final String title;
  final String description;
  final bool showAppBar;
  final VoidCallback? onFullScreen;
  /// "Pause and think" questions of a generated lesson video (empty for normal videos).
  final List<VideoInteraction> interactions;
  /// Play/pause requests from the hosting screen (optional).
  final VideoPlaybackRequests? playbackRequests;

  const CustomVideoPlayer({
    super.key,
    this.videoId,
    this.videoUrl,
    this.externalPlayer,
    required this.title,
    required this.description,
    this.showAppBar = false,
    this.onFullScreen,
    this.interactions = const [],
    this.playbackRequests,
  }) : assert(videoUrl != null || externalPlayer != null);

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  // Media Kit (Desktop)
  mk.Player? _mkPlayer;
  mkv.VideoController? _mkVideoController;
  // Gives access to media_kit's built-in fullscreen (route + native window).
  final GlobalKey<mkv.VideoState> _mkVideoKey = GlobalKey<mkv.VideoState>();
  
  // Chewie / Video Player (Mobile/Android)
  VideoPlayerController? _vpController;
  ChewieController? _chewieController;
  
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isDataSaver = false;
  Timer? _bufferingTimer;
  int _bufferingSeconds = 0;
  bool _showSlowInternetError = false;
  bool _isOffline = false;
  StreamSubscription? _connectivitySubscription;
  // Desktop playback goes through mkv.Video, which keeps the screen awake by
  // itself, so this only covers the mobile/web (Chewie) path.
  final ScreenWakelock _wakelock = ScreenWakelock();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<StreamSubscription> _subscriptions = [];

  // ---- Desktop fallback chain -------------------------------------------
  // Some desktops can't render media_kit's GPU output (black/frozen video,
  // driver errors, hangs). When a stage fails the next one takes over:
  //   0 = media_kit, GPU rendering
  //   1 = media_kit, software rendering + software decoding
  //   2 = video_player / Chewie (where the platform implements it)
  //   3 = nothing left: offer to open the video in the system player/browser
  int _desktopStage = 0;
  static const int _lastDesktopStage = 3;
  // Bumped on every (re)initialisation so callbacks of a replaced player are ignored.
  int _attempt = 0;
  Timer? _watchdog;
  bool _firstFrameRendered = false;
  // Where to continue after switching player, so the student doesn't lose their place.
  Duration? _resumeOverride;
  static const Duration _loadTimeout = Duration(seconds: 25);

  bool get _isDesktopNative => !kIsWeb && !_isMobile;
  bool get _canFallBack => _isDesktopNative && widget.externalPlayer == null;
  bool get _usesVideoPlayer => _isMobile || kIsWeb || _desktopStage == 2;

  late final CheckpointTracker _checkpoints = CheckpointTracker(widget.interactions);
  VideoInteraction? _activeCheck;

  /// Pause and ask when playback reaches a check question.
  void _handleCheckpoint(Duration position) {
    if (_activeCheck != null || _checkpoints.isEmpty) return;
    final it = _checkpoints.onPosition(position);
    if (it == null) return;
    _mkPlayer?.pause();
    _vpController?.pause();
    // Listeners can fire mid-frame; update the UI after it, like the rest of this widget.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _activeCheck = it);
    });
  }

  /// After answering, continue from the answer reveal.
  Future<void> _continueAfterCheck() async {
    final it = _activeCheck;
    if (it == null) return;
    setState(() => _activeCheck = null);
    if (_mkPlayer != null) {
      await _mkPlayer!.seek(it.resumeAt);
      await _mkPlayer!.play();
    } else if (_vpController != null) {
      await _vpController!.seekTo(it.resumeAt);
      await _vpController!.play();
    }
  }

  Widget _checkOverlay() => Positioned.fill(
        child: VideoCheckOverlay(key: ValueKey('check-${_activeCheck!.id}'), interaction: _activeCheck!, onContinue: _continueAfterCheck),
      );

  bool get _isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  String _getOptimizedUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // Convert S3 URL to CloudFront URL and ensure HTTPS
    String processedUrl = url;
    if (processedUrl.contains('echcoahing.s3.amazonaws.com')) {
      processedUrl = processedUrl.replaceFirst('echcoahing.s3.amazonaws.com', 'd3ofk5ujo941v.cloudfront.net');
    }

    // On web, CloudFront/S3 media is fetched via XHR which is subject to CORS.
    // Route it through the backend media proxy to add the proper CORS headers.
    if (kIsWeb) {
      return mediaProxyUrl(processedUrl);
    }

    if (processedUrl.startsWith('http://')) {
      processedUrl = processedUrl.replaceFirst('http://', 'https://');
    }

    if (processedUrl.startsWith('https')) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows && !processedUrl.contains('type=.mp4') && !processedUrl.toLowerCase().contains('.mp4')) {
        return processedUrl.contains('?') ? '$processedUrl&type=.mp4' : '$processedUrl?type=.mp4';
      }
      return processedUrl;
    }
    // Handle local files
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return processedUrl.replaceAll('/', '\\');
    }
    return processedUrl;
  }

  @override
  void initState() {
    super.initState();
    widget.playbackRequests?.addListener(_onPlaybackRequest);
    _initConnectivityListener();
    _initPlayer();
  }

  @override
  void didUpdateWidget(CustomVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playbackRequests != widget.playbackRequests) {
      oldWidget.playbackRequests?.removeListener(_onPlaybackRequest);
      widget.playbackRequests?.addListener(_onPlaybackRequest);
    }
  }

  void _onPlaybackRequest() {
    // A check question owns playback until it is answered.
    if (_activeCheck != null) return;
    final play = widget.playbackRequests!.wantsPlay;
    if (_mkPlayer != null) {
      play ? _mkPlayer!.play() : _mkPlayer!.pause();
    } else if (_vpController?.value.isInitialized == true) {
      // Browsers may refuse to start playback; the play button still works then.
      (play ? _vpController!.play() : _vpController!.pause()).catchError((_) {});
    }
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isNowOffline = results.isEmpty || results.contains(ConnectivityResult.none);
      
      if (!isNowOffline && _isOffline) {
        // We were offline, now back online. Automatically try to resume if we have an error
        if (_errorMessage != null || _showSlowInternetError) {
          _retryPlayback();
        }
      }
      
      if (mounted) {
        setState(() {
          _isOffline = isNowOffline;
        });
      }
    });
  }

  void _retryPlayback() {
    if (_position > const Duration(seconds: 2)) _resumeOverride = _position;
    _disposePlayers();
    setState(() {
      _errorMessage = null;
      _showSlowInternetError = false;
      _isInitialized = false;
      _isBuffering = false;
      // Every option was exhausted: start the chain again from the top.
      if (_desktopStage >= _lastDesktopStage) _desktopStage = 0;
    });

    _wakelock.release();
    _stopBufferingTimer();
    _initPlayer();
  }

  void _initPlayer() {
    if (widget.videoUrl == null && widget.externalPlayer == null) {
      setState(() {
        _errorMessage = "Video source is missing (URL is null)";
        _isInitialized = true;
      });
      return;
    }

    if (_usesVideoPlayer) {
      _initMobilePlayer();
    } else {
      _initMediaKit();
    }
  }

  /// Releases whichever player is active (never an [CustomVideoPlayer.externalPlayer]).
  void _disposePlayers() {
    _attempt++;
    _watchdog?.cancel();
    _watchdog = null;
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions = [];
    if (widget.externalPlayer == null) _mkPlayer?.dispose();
    _mkPlayer = null;
    _mkVideoController = null;
    _vpController?.removeListener(_mobilePlayerListener);
    _chewieController?.dispose();
    _vpController?.dispose();
    _chewieController = null;
    _vpController = null;
    _firstFrameRendered = false;
  }

  /// The current desktop player failed: replace it with the next option
  /// automatically instead of leaving the student on an error screen.
  void _onDesktopFailure(String reason) {
    if (!mounted) return;
    if (!_canFallBack) {
      setState(() {
        _errorMessage = reason;
        _isInitialized = true;
      });
      return;
    }
    debugPrint('CustomVideoPlayer: stage $_desktopStage failed ($reason); switching player');
    if (_position > const Duration(seconds: 2)) _resumeOverride = _position;
    _disposePlayers();
    _wakelock.release();
    _stopBufferingTimer();
    setState(() {
      _desktopStage++;
      _errorMessage = null;
      _showSlowInternetError = false;
      _isBuffering = false;
      _isPlaying = false;
      // The last stage is a static screen; nothing to load.
      _isInitialized = _desktopStage >= _lastDesktopStage;
    });
    if (_desktopStage < _lastDesktopStage) _initPlayer();
  }

  Future<Duration> _startPosition() async {
    final override = _resumeOverride;
    if (override != null) return override;
    if (widget.videoId == null) return Duration.zero;
    return videoProgressService.getProgress(widget.videoId!);
  }

  void _initMobilePlayer() async {
    final attempt = ++_attempt;
    if (widget.videoUrl == null) {
      if (mounted) {
        setState(() {
          _errorMessage = "Video URL is null";
          _isInitialized = true;
        });
      }
      return;
    }

    final optimizedUrl = _getOptimizedUrl(widget.videoUrl);
    if (optimizedUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = "Video URL is empty";
          _isInitialized = true;
        });
      }
      return;
    }

    final isNetwork = optimizedUrl.startsWith('http') || kIsWeb;
    
    final startAt = await _startPosition();
    if (!mounted || attempt != _attempt) return;

    if (isNetwork) {
      _vpController = VideoPlayerController.networkUrl(Uri.parse(optimizedUrl));
    } else if (!kIsWeb) {
      _vpController = VideoPlayerController.file(File(optimizedUrl));
    } else {
      _errorMessage = "Local files are not supported on web";
      if (mounted) setState(() => _isInitialized = true);
      return;
    }

    try {
      await _vpController!.initialize().timeout(_loadTimeout);
      if (!mounted || attempt != _attempt) return;

      if (startAt > Duration.zero) {
        await _vpController!.seekTo(startAt);
      }
      _resumeOverride = null;

      _chewieController = ChewieController(
        videoPlayerController: _vpController!,
        aspectRatio: 16 / 9,
        autoPlay: false,
        looping: false,
        showControls: true,
        // Left at the default on purpose: with allowedScreenSleep: false Chewie
        // disables the wakelock when it leaves full screen, which would let the
        // screen sleep while the video keeps playing inline. _wakelock owns it.
        placeholder: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryGreen,
          handleColor: AppTheme.primaryGreen,
          backgroundColor: Colors.grey,
          bufferedColor: AppTheme.primaryGreen.withOpacity(0.3),
        ),
      );

      _vpController!.addListener(_mobilePlayerListener);
      if (widget.playbackRequests?.wantsPlay == true) _onPlaybackRequest();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (error) {
      if (!mounted || attempt != _attempt) return;
      // On desktop this is the compatibility stage (e.g. video_player has no
      // Windows implementation): move on rather than show an error.
      if (_isDesktopNative) {
        _onDesktopFailure('Failed to load video: $error');
        return;
      }
      setState(() {
        _errorMessage = "Failed to load video: $error";
        _isInitialized = true;
      });
    }
  }

  void _mobilePlayerListener() {
    if (_vpController == null) return;

    if (_vpController!.value.hasError) {
      _wakelock.release();
      if (_isDesktopNative) {
        final attempt = _attempt;
        final reason = 'Playback Error: ${_vpController!.value.errorDescription}';
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && attempt == _attempt) _onDesktopFailure(reason);
        });
        return;
      }
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorMessage = "Playback Error: ${_vpController?.value.errorDescription}";
            });
          }
        });
      }
      return;
    }
    
    final position = _vpController!.value.position;
    _handleCheckpoint(position);

    // Hold the screen awake for as long as the video is actually playing, so
    // watching a lesson is never cut short by the screen dimming or locking
    if (_vpController!.value.isPlaying) {
      _wakelock.acquire();
    } else {
      _wakelock.release();
    }

    // Save progress periodically (every 5 seconds)
    if (widget.videoId != null && position.inSeconds % 5 == 0 && position.inSeconds > 0) {
      videoProgressService.saveProgress(widget.videoId!, position);
    }

    if (mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final vp = _vpController;
        if (mounted && vp != null) {
          setState(() {
            _position = position;
            _duration = vp.value.duration;
            _isPlaying = vp.value.isPlaying;
            _isBuffering = vp.value.isBuffering;
            
            if (_isBuffering && _isPlaying) {
              _startBufferingTimer();
            } else {
              _stopBufferingTimer();
            }
          });
        }
      });
    }
  }

  void _startBufferingTimer() {
    if (_bufferingTimer != null) return;
    _bufferingSeconds = 0;
    _bufferingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _bufferingSeconds++;
      if (_bufferingSeconds > 10) { // More than 10 seconds of buffering
        if (mounted) {
          setState(() {
            _showSlowInternetError = true;
          });
        }
        _stopBufferingTimer();
      }
    });
  }

  void _stopBufferingTimer() {
    _bufferingTimer?.cancel();
    _bufferingTimer = null;
    _bufferingSeconds = 0;
    if (_showSlowInternetError && !_isBuffering) {
      if (mounted) {
        setState(() {
          _showSlowInternetError = false;
        });
      }
    }
  }

  void _initMediaKit() async {
    final attempt = ++_attempt;
    final startAt = await _startPosition();
    if (!mounted || attempt != _attempt) return;

    // Stage 1: skip the GPU entirely; slower but works on problem drivers.
    final software = _desktopStage >= 1;

    try {
      if (widget.externalPlayer != null) {
        _mkPlayer = widget.externalPlayer!;
        _isInitialized = true;
      } else {
        // Increased default buffer size to 64MB (from 8MB) for smoother playback on high-speed connections
        // If data saver is on, reduce to 16MB (previously 2MB)
        final int bufferSize = _isDataSaver ? 16 * 1024 * 1024 : 64 * 1024 * 1024;

        _mkPlayer = mk.Player(
          configuration: mk.PlayerConfiguration(
            bufferSize: bufferSize,
          ),
        );
      }

      _mkVideoController = mkv.VideoController(
        _mkPlayer!,
        configuration: mkv.VideoControllerConfiguration(
          enableHardwareAcceleration: !software,
          hwdec: software ? 'no' : null,
        ),
      );
    } catch (error) {
      // Native libraries / texture setup can fail outright on some machines.
      _onDesktopFailure('Player could not start: $error');
      return;
    }
    _setupMediaKitSubscriptions(attempt);

    if (widget.externalPlayer != null) return;

    _armWatchdog(attempt);
    final optimizedUrl = _getOptimizedUrl(widget.videoUrl!);

    _mkPlayer!.open(mk.Media(optimizedUrl)).then((_) async {
      if (!mounted || attempt != _attempt) return;
      if (startAt > Duration.zero) {
        await _mkPlayer?.seek(startAt);
      }
      _resumeOverride = null;
      if (mounted && attempt == _attempt) {
        setState(() {
          _isInitialized = true;
        });
      }
    }).catchError((error) {
      if (mounted && attempt == _attempt) {
        _onDesktopFailure('Failed to load video: $error');
      }
    });

    // A frame on screen proves this stage works; until then the watchdog runs.
    _mkVideoController!.waitUntilFirstFrameRendered.then((_) {
      if (!mounted || attempt != _attempt) return;
      _firstFrameRendered = true;
      _watchdog?.cancel();
    }).catchError((_) {});
  }

  /// Fails the current stage if no video frame appears in time — this
  /// catches black screens and silent hangs, not just reported errors.
  /// A slow or missing connection is left to the offline/slow overlays.
  void _armWatchdog(int attempt) {
    _watchdog?.cancel();
    _watchdog = Timer(_loadTimeout, () {
      if (!mounted || attempt != _attempt || _firstFrameRendered) return;
      if (_isOffline) {
        _armWatchdog(attempt); // wait for the connection to come back
        return;
      }
      final player = _mkPlayer;
      final decoded = (player?.state.width ?? 0) > 0;
      final stillLoading = player?.state.buffering ?? false;
      // Data is arriving but nothing renders → this renderer is broken.
      // Nothing decoded and not even buffering → the player is stuck.
      if (decoded || !stillLoading) {
        _onDesktopFailure(decoded
            ? 'Video decoded but nothing was displayed'
            : 'Video took too long to start');
      } else {
        _armWatchdog(attempt); // genuinely slow network: keep waiting
      }
    });
  }

  void _setupMediaKitSubscriptions(int attempt) {
    if (_mkPlayer == null) return;

    for (final s in _subscriptions) {
      s.cancel();
    }
    // Ignore events of a player that has already been replaced.
    void later(VoidCallback fn) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && attempt == _attempt) fn();
      });
    }
    _subscriptions = [
      _mkPlayer!.stream.buffering.listen((buffering) {
        later(() => setState(() {
              _isBuffering = buffering;
              if (_isBuffering && _isPlaying) {
                _startBufferingTimer();
              } else {
                _stopBufferingTimer();
              }
            }));
      }),
      _mkPlayer!.stream.playing.listen((playing) {
        later(() => setState(() {
              _isPlaying = playing;
              if (_isBuffering && _isPlaying) {
                _startBufferingTimer();
              } else {
                _stopBufferingTimer();
              }
            }));
      }),
      _mkPlayer!.stream.position.listen((position) {
        if (attempt != _attempt) return;
        _handleCheckpoint(position);
        later(() {
          setState(() => _position = position);
          if (widget.videoId != null && position.inSeconds % 5 == 0 && position.inSeconds > 0) {
            videoProgressService.saveProgress(widget.videoId!, position);
          }
        });
      }),
      _mkPlayer!.stream.duration.listen((duration) {
        later(() => setState(() {
              _duration = duration;
              _isInitialized = true;
            }));
      }),
      _mkPlayer!.stream.error.listen((error) {
        // Switch to the next player automatically; while offline the
        // offline overlay (and auto-retry on reconnect) handles it instead.
        later(() {
          if (_canFallBack && !_isOffline) {
            _onDesktopFailure(error.toString());
          } else {
            setState(() => _errorMessage = error.toString());
          }
        });
      }),
    ];
  }

  @override
  void dispose() {
    widget.playbackRequests?.removeListener(_onPlaybackRequest);
    _wakelock.release();
    _connectivitySubscription?.cancel();
    _bufferingTimer?.cancel();
    _disposePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktopNative && _desktopStage >= _lastDesktopStage) {
      return _buildOpenExternallyFallback();
    }
    if (_usesVideoPlayer) {
      return _buildMobilePlayer();
    }
    
    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.speed),
              onPressed: _showPlaybackSpeedDialog,
            ),
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: widget.onFullScreen ?? _toggleFullscreen,
            ),
          ],
        ),
        body: _buildMediaKitPlayer(),
      );
    }
    return _buildMediaKitPlayer();
  }

  Widget _buildMobilePlayer() {
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

    if (_chewieController == null || _vpController?.value.isInitialized != true) {
      return Container(
        color: Colors.black,
        height: ResponsiveBreakpoints.isDesktop(context) ? 400 : 200,
        child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),
          if (_showSlowInternetError)
            _buildSlowInternetOverlay(),
          if (_activeCheck != null) _checkOverlay(),
        ],
      ),
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

  /// Original (non-proxied) address of the video, for opening it outside the app.
  Uri? _externalVideoUri() {
    final url = widget.videoUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) {
      return Uri.tryParse(url
          .replaceFirst('echcoahing.s3.amazonaws.com', 'd3ofk5ujo941v.cloudfront.net')
          .replaceFirst('http://', 'https://'));
    }
    return Uri.file(url); // downloaded lesson: open in the default media player
  }

  Future<void> _openExternally() async {
    final uri = _externalVideoUri();
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the video outside the app.')),
      );
    }
  }

  /// Last resort when no in-app player works on this computer.
  Widget _buildOpenExternallyFallback() {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxHeight < 260 || constraints.maxWidth < 420;
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(compact ? 12 : 20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.ondemand_video_rounded, color: Colors.white70, size: compact ? 32 : 44),
                SizedBox(height: compact ? 8 : 14),
                Text(
                  "This video can't play inside the app on this computer",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: compact ? 14 : 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Open it in your browser or media player to keep watching.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: compact ? 12 : 13.5),
                ),
                SizedBox(height: compact ? 12 : 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openExternally,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Open video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _retryPlayback,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Try again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSlowInternetOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, color: Colors.amber, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Slow Connection Detected',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try lowering quality, using Data Saver, or check your internet. You can also download this lesson for offline viewing.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showSlowInternetError = false;
                      });
                    },
                    child: const Text('Dismiss', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _retryPlayback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaKitPlayer() {
    if (!_isInitialized || _mkVideoController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    // Size everything from the player's own box, not the screen: the
    // embedded (minimised) player on a wide desktop is still small.
    return LayoutBuilder(builder: (context, constraints) {
    final compact = constraints.maxWidth < 600 || constraints.maxHeight < 300;
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            // Fills the box; a fixed 900×506 here used to overflow and get
            // clipped inside the embedded player on desktop.
            mkv.Video(
              key: _mkVideoKey,
              controller: _mkVideoController!,
              fit: BoxFit.contain,
              fill: Colors.black,
            ),
            if (_isOffline && (widget.videoUrl?.startsWith('http') ?? false || kIsWeb))
              _buildErrorPlaceholder(
                icon: Icons.wifi_off_outlined,
                title: 'No Internet Connection',
                message: 'Please check your network settings and try again.',
                onRetry: _retryPlayback,
              ),
            if (_errorMessage != null && !(_isOffline && !(widget.videoUrl?.startsWith('http') ?? false)))
              _buildErrorPlaceholder(
                icon: Icons.error_outline,
                title: 'Playback Error',
                message: 'Something went wrong while playing this video.\n$_errorMessage',
                onRetry: _retryPlayback,
              ),
            if (_isBuffering && _errorMessage == null && !_showSlowInternetError)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            if (_showSlowInternetError)
              _buildSlowInternetOverlay(),
            if (_showControls) _buildMediaKitControls(compact),
            if (_activeCheck != null) _checkOverlay(),
          ],
        ),
      ),
    );
    });
  }

  Widget _buildMediaKitControls(bool isSmallScreen) {

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
        ),
      ),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(_formatDuration(_position), style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 10 : 12)),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: isSmallScreen ? 2 : 4,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: isSmallScreen ? 4 : 6),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: isSmallScreen ? 10 : 14),
                    activeTrackColor: AppTheme.primaryGreen,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.primaryGreen,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble()),
                    min: 0,
                    max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: (value) {
                      _mkPlayer!.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_formatDuration(_duration), style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 10 : 12)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isDataSaver ? Icons.data_usage : Icons.data_usage_outlined, 
                      color: _isDataSaver ? AppTheme.primaryGreen : Colors.white, 
                      size: isSmallScreen ? 20 : 24),
                    onPressed: () {
                      setState(() => _isDataSaver = !_isDataSaver);
                      // Re-initialize player with new buffer size if using media_kit
                      if (_isDesktopNative && widget.externalPlayer == null) {
                        if (_position > Duration.zero) _resumeOverride = _position;
                        _disposePlayers();
                        setState(() => _isInitialized = false);
                        _initMediaKit();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isDataSaver ? 'Data Saver On (Lower Buffer)' : 'Data Saver Off'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'Data Saver',
                  ),
                  IconButton(
                    icon: Icon(Icons.speed, color: Colors.white, size: isSmallScreen ? 20 : 24),
                    onPressed: _showPlaybackSpeedDialog,
                    tooltip: 'Playback Speed',
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: Icon(Icons.replay_10, color: Colors.white, size: isSmallScreen ? 24 : 30), onPressed: () => _mkPlayer!.seek(_position - const Duration(seconds: 10))),
                  SizedBox(width: isSmallScreen ? 15 : 30),
                  Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: AppTheme.primaryGreen, size: isSmallScreen ? 30 : 40),
                      onPressed: () => _mkPlayer!.playOrPause(),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 15 : 30),
                  IconButton(icon: Icon(Icons.forward_10, color: Colors.white, size: isSmallScreen ? 24 : 30), onPressed: () => _mkPlayer!.seek(_position + const Duration(seconds: 10))),
                ],
              ),
              IconButton(
                icon: Icon(Icons.fullscreen, color: Colors.white, size: isSmallScreen ? 20 : 24),
                onPressed: widget.onFullScreen ?? _toggleFullscreen,
                tooltip: 'Fullscreen',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return ListTile(
              title: Text('${speed}x'),
              selected: _playbackSpeed == speed,
              onTap: () {
                if (_vpController != null) {
                  _vpController!.setPlaybackSpeed(speed);
                } else {
                  _mkPlayer?.setRate(speed);
                }
                setState(() => _playbackSpeed = speed);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _toggleFullscreen() {
    if (widget.onFullScreen != null) {
      widget.onFullScreen!();
      return;
    }
    if (_usesVideoPlayer) {
      _chewieController?.toggleFullScreen();
      return;
    }
    // Pushes a fullscreen route and puts the desktop window into native
    // fullscreen; Esc or the controls' button exits it.
    _mkVideoKey.currentState?.toggleFullscreen();
  }
}
