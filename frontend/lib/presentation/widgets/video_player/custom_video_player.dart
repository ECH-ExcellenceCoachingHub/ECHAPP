import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/video_progress_service.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/screen_wakelock.dart';
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

  const CustomVideoPlayer({
    super.key,
    this.videoId,
    this.videoUrl,
    this.externalPlayer,
    required this.title,
    required this.description,
    this.showAppBar = false,
    this.onFullScreen,
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

  bool get _isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
    _initConnectivityListener();
    _initPlayer();
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
    setState(() {
      _errorMessage = null;
      _showSlowInternetError = false;
      _isInitialized = false;
    });

    _wakelock.release();
    _stopBufferingTimer();
    
    if (_isMobile || kIsWeb) {
      _initMobilePlayer();
    } else {
      _initMediaKit();
    }
  }

  void _initPlayer() {
    if (widget.videoUrl == null && widget.externalPlayer == null) {
      setState(() {
        _errorMessage = "Video source is missing (URL is null)";
        _isInitialized = true;
      });
      return;
    }

    if (_isMobile || kIsWeb) {
      _initMobilePlayer();
    } else {
      _initMediaKit();
    }
  }

  void _initMobilePlayer() async {
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
    
    // Retrieve saved progress
    Duration startAt = Duration.zero;
    if (widget.videoId != null) {
      startAt = await videoProgressService.getProgress(widget.videoId!);
    }

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
      await _vpController!.initialize();
      
      if (startAt > Duration.zero) {
        await _vpController!.seekTo(startAt);
      }

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

  void _mobilePlayerListener() {
    if (_vpController == null) return;
    
    if (_vpController!.value.hasError) {
      _wakelock.release();
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorMessage = "Playback Error: ${_vpController!.value.errorDescription}";
            });
          }
        });
      }
      return;
    }
    
    final position = _vpController!.value.position;

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
        if (mounted) {
          setState(() {
            _position = position;
            _duration = _vpController!.value.duration;
            _isPlaying = _vpController!.value.isPlaying;
            _isBuffering = _vpController!.value.isBuffering;
            
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
    // Retrieve saved progress
    Duration startAt = Duration.zero;
    if (widget.videoId != null) {
      startAt = await videoProgressService.getProgress(widget.videoId!);
    }

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
      
      final optimizedUrl = _getOptimizedUrl(widget.videoUrl!);
      
      _mkPlayer!.open(mk.Media(optimizedUrl)).then((_) {
        if (startAt > Duration.zero) {
          _mkPlayer!.seek(startAt);
        }
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to load video: $error";
            _isInitialized = true;
          });
        }
      });
    }

    _mkVideoController = mkv.VideoController(
      _mkPlayer!,
      configuration: const mkv.VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );
    _setupMediaKitSubscriptions();
  }

  void _setupMediaKitSubscriptions() {
    if (_mkPlayer == null) return;
    
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions = [
      _mkPlayer!.stream.buffering.listen((buffering) {
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isBuffering = buffering;
                if (_isBuffering && _isPlaying) {
                  _startBufferingTimer();
                } else {
                  _stopBufferingTimer();
                }
              });
            }
          });
        }
      }),
      _mkPlayer!.stream.playing.listen((playing) {
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isPlaying = playing;
                if (_isBuffering && _isPlaying) {
                  _startBufferingTimer();
                } else {
                  _stopBufferingTimer();
                }
              });
            }
          });
        }
      }),
      _mkPlayer!.stream.position.listen((position) {
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _position = position);
              if (widget.videoId != null && position.inSeconds % 5 == 0 && position.inSeconds > 0) {
                videoProgressService.saveProgress(widget.videoId!, position);
              }
            }
          });
        }
      }),
      _mkPlayer!.stream.duration.listen((duration) {
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _duration = duration;
                _isInitialized = true;
              });
            }
          });
        }
      }),
      _mkPlayer!.stream.error.listen((error) {
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _errorMessage = error.toString());
          });
        }
      }),
    ];
  }

  @override
  void dispose() {
    _wakelock.release();
    _connectivitySubscription?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    if (widget.externalPlayer == null) {
      _mkPlayer?.dispose();
    }
    _vpController?.removeListener(_mobilePlayerListener);
    _vpController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile || kIsWeb) {
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

    if (_chewieController == null || !_vpController!.value.isInitialized) {
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
                    onPressed: () {
                      _stopBufferingTimer();
                      if (_isMobile || kIsWeb) {
                        _initMobilePlayer();
                      } else {
                        _initMediaKit();
                      }
                    },
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
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isLargeDesktop = screenWidth > 1600;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: mkv.Video(
                key: _mkVideoKey,
                controller: _mkVideoController!,
                fit: BoxFit.contain,
                fill: Colors.black,
                width: isDesktop ? (isLargeDesktop ? 1200 : 900) : null,
                height: isDesktop ? (isLargeDesktop ? 675 : 506) : null,
              ),
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
            if (_showControls) _buildMediaKitControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaKitControls() {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
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
                      setState(() {
                        _isDataSaver = !_isDataSaver;
                        // Re-initialize player with new buffer size if using media_kit
                        if (!_isMobile && !kIsWeb && widget.externalPlayer == null) {
                          _initMediaKit();
                        }
                      });
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
                if (_isAndroid) {
                  _vpController!.setPlaybackSpeed(speed);
                } else {
                  _mkPlayer!.setRate(speed);
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
    if (_isMobile || kIsWeb) {
      _chewieController?.toggleFullScreen();
      return;
    }
    // Pushes a fullscreen route and puts the desktop window into native
    // fullscreen; Esc or the controls' button exits it.
    _mkVideoKey.currentState?.toggleFullscreen();
  }
}
