import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/data/services/gutenberg_service.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:excellencecoachinghub/utils/book_download.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/link.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:excellencecoachinghub/utils/screen_wakelock.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';
import 'package:excellencecoachinghub/presentation/widgets/document_viewer/paged_pdf_viewer.dart';
import 'package:excellencecoachinghub/utils/pdf_blob_cache.dart' as pdf_cache;

class BookReaderScreen extends ConsumerStatefulWidget {
  final dynamic book;

  const BookReaderScreen({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  final PageController _pageController = PageController();
  final int _currentPage = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  String _selectedFormat = 'text/plain';
  
  // TTS State
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool _isPaused = false;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  String _selectedVoice = '';
  List<String> _availableVoices = [];
  String _currentText = '';
  final int _currentWordIndex = 0;
  
  // PDF State
  final bool _isFullScreen = false;
  
  // Reading Progress
  final double _readingProgress = 0.0;

  // Local-first book loading
  String? _localFilePath;
  String? _blobUrl; // Web-only: cached PDF as blob URL for instant re-load
  bool _isPreloading = false;
  double _downloadProgress = 0.0;
  String? _preloadError;

  // Reading a page takes minutes without a single tap, which is exactly when
  // the screen would dim, so it stays awake for as long as the book is open
  final ScreenWakelock _wakelock = ScreenWakelock();

  @override
  void initState() {
    super.initState();
    _wakelock.acquire();
    _initTTS();
    
    // Check if this is an admin-uploaded book
    final isAdminBook = widget.book is! Book;

    if (!isAdminBook && widget.book is Book) {
      // Set default format preference for Gutenberg books
      final book = widget.book as Book;
      if (book.formats != null) {
        if (book.formats!.containsKey('text/html')) {
          _selectedFormat = 'text/html';
        } else if (book.formats!.containsKey('text/plain')) {
          _selectedFormat = 'text/plain';
        } else if (book.formats!.containsKey('application/pdf')) {
          _selectedFormat = 'application/pdf';
        } else {
          _selectedFormat = book.formats!.keys.first;
        }
      }
    }

    // Preload a local copy of the book so it opens instantly on re-open.
    _preloadLocalBook();
  }

  Future<void> _preloadLocalBook() async {
    final target = resolveBookDownload(widget.book);
    if (target == null) return;

    if (kIsWeb) {
      // On web, cache the PDF as a blob URL for instant re-load within a session.
      setState(() {
        _isPreloading = true;
        _downloadProgress = 0.0;
        _preloadError = null;
      });
      try {
        final blobUrl = await pdf_cache.cachePdfAsBlob(target.url);
        if (!mounted) return;
        if (blobUrl != null) {
          setState(() {
            _blobUrl = blobUrl;
            _isPreloading = false;
          });
        } else {
          setState(() {
            _isPreloading = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isPreloading = false;
          _preloadError = e.toString();
        });
      }
      return;
    }

    final downloadService = ref.read(downloadServiceProvider);
    final download = downloadService.getDownloadById(target.downloadId);

    // If already downloaded and file exists, use it directly.
    if (download != null &&
        download.status == DownloadStatus.completed &&
        download.localPath.isNotEmpty) {
      final file = File(download.localPath);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _localFilePath = download.localPath;
          });
        }
        return;
      }
    }

    // Otherwise start a background download so the next open is instant.
    setState(() {
      _isPreloading = true;
      _downloadProgress = 0.0;
      _preloadError = null;
    });

    try {
      await downloadService.downloadNotesOrMaterial(
        url: target.url,
        title: target.title,
        lessonId: target.lessonId,
        type: DownloadType.material,
        lessonTitle: target.author,
        sectionTitle: 'Library',
        fileExtension: target.fileExtension,
        thumbnailUrl: target.coverUrl,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress.clamp(0.0, 1.0);
            });
          }
        },
        onSuccess: () {
          if (!mounted) return;
          final saved = downloadService.getDownloadById(target.downloadId);
          if (saved != null && saved.localPath.isNotEmpty) {
            setState(() {
              _localFilePath = saved.localPath;
              _isPreloading = false;
            });
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isPreloading = false;
            _preloadError = error;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPreloading = false;
        _preloadError = e.toString();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void dispose() {
    _wakelock.release();
    _pageController.dispose();
    _searchController.dispose();
    _flutterTts.stop();
    pdf_cache.revokeBlobUrl(_blobUrl);
    super.dispose();
  }

  // TTS Initialization
  Future<void> _initTTS() async {
    try {
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      
      // Get available voices
      final voices = await _flutterTts.getVoices;
      if (voices != null && voices is List) {
        _availableVoices = List<String>.from(
          voices.map((v) => v is Map ? (v['name'] ?? '') : v.toString()),
        );
        if (_availableVoices.isNotEmpty) {
          _selectedVoice = _availableVoices.first;
          await _flutterTts.setVoice({"name": _selectedVoice});
        }
      }
      
      _flutterTts.setCompletionHandler(() {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
        });
      });
      
      _flutterTts.setErrorHandler((msg) {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
        });
      });
    } catch (e) {
      // TTS not supported on this platform
      debugPrint('TTS initialization failed: $e');
    }
  }

  // TTS Control Methods
  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    
    await _flutterTts.stop();
    setState(() {
      _currentText = text;
      _isPlaying = true;
      _isPaused = false;
    });
    
    await _flutterTts.speak(text);
  }

  Future<void> _pause() async {
    await _flutterTts.pause();
    setState(() {
      _isPaused = true;
    });
  }

  Future<void> _resume() async {
    await _flutterTts.speak(_currentText);
    setState(() {
      _isPaused = false;
    });
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentText = '';
    });
  }

  Future<void> _setSpeechRate(double rate) async {
    setState(() {
      _speechRate = rate;
    });
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> _setPitch(double pitch) async {
    setState(() {
      _pitch = pitch;
    });
    await _flutterTts.setPitch(pitch);
  }

  Future<void> _setVoice(String voice) async {
    setState(() {
      _selectedVoice = voice;
    });
    await _flutterTts.setVoice({"name": voice});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
      appBar: _isFullScreen ? null : _buildAppBar(context),
      body: Column(
        children: [
          if (_showSearch && !_isFullScreen) _buildSearchBar(context),
          Expanded(
            child: _buildContent(context),
          ),
          if (_isPlaying || _isPaused && !_isFullScreen) _buildTTSControls(context),
        ],
      ),
      floatingActionButton: null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isAdminBook = widget.book is! Book;
    final title = isAdminBook 
        ? (widget.book['title'] ?? 'Untitled')
        : widget.book.title;
    
    return AppBar(
      backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      elevation: 0,
      title: Text(
        title.length > 30 
            ? '${title.substring(0, 30)}...' 
            : title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.getTextColor(context),
        ),
      ),
      actions: [
        // TTS button - always visible
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.stop_circle : Icons.record_voice_over,
            color: _isPlaying ? Colors.red : AppTheme.getTextColor(context),
          ),
          onPressed: () {
            if (_isPlaying) {
              _stop();
            } else {
              _showTTSOptionDialog();
            }
          },
          tooltip: _isPlaying ? 'Stop Reading' : 'Voice Reader',
        ),
        IconButton(
          icon: const Icon(Icons.format_list_bulleted),
          color: AppTheme.getTextColor(context),
          onPressed: _showFormatSelection,
          tooltip: 'Format',
        ),
        IconButton(
          icon: Icon(
            _showSearch ? Icons.close : Icons.search,
            color: AppTheme.getTextColor(context),
          ),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
              }
            });
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: AppTheme.getTextColor(context),
          ),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            if (!isAdminBook) ...[
              const PopupMenuItem(
                value: 'format',
                child: Text('Change Format'),
              ),
              const PopupMenuItem(
                value: 'font_size',
                child: Text('Font Size'),
              ),
            ],
            const PopupMenuItem(
              value: 'theme',
              child: Text('Toggle Theme'),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Text('Download Book'),
            ),
            const PopupMenuItem(
              value: 'tts',
              child: Text('TTS Settings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: AppTheme.getTextColor(context),
        ),
        decoration: InputDecoration(
          hintText: 'Search in book...',
          hintStyle: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.getSecondaryTextColor(context),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isAdminBook = widget.book is! Book;

    // Show preload progress while downloading in the background.
    if (_isPreloading && _localFilePath == null) {
      return _buildPreloadWidget(context);
    }

    // Handle admin-uploaded books
    if (isAdminBook) {
      final pdfUrl = widget.book['pdfUrl'];
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        return _buildPDFViewer(context, pdfUrl);
      } else {
        return _buildNoContentWidget(context);
      }
    }

    // Handle Gutenberg books
    final book = widget.book as Book;
    if (book.formats == null || book.formats!.isEmpty) {
      return _buildNoContentWidget(context);
    }

    final formatUrl = book.formats![_selectedFormat];
    if (formatUrl == null || formatUrl.isEmpty) {
      return _buildNoContentWidget(context);
    }

    // For HTML and text formats, render inline in a WebView.
    if (_selectedFormat.startsWith('text/') || _selectedFormat.contains('html')) {
      return _buildWebView(context, formatUrl);
    }

    // For PDF, load from local file if available (instant), otherwise network.
    if (_selectedFormat.contains('pdf')) {
      return _buildPDFViewer(context, formatUrl, localFilePath: _localFilePath);
    }

    // For other formats, show download option
    return _buildDownloadWidget(context);
  }

  Widget _buildPreloadWidget(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          Text(
            'Preparing book for fast reading…',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          if (_preloadError != null) ...[
            const SizedBox(height: 12),
            Text(
              'Preload failed: $_preloadError',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFEF4444),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoContentWidget(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final iconSize = isWide ? 80.0 : 64.0;
        final titleSize = isWide ? 20.0 : 18.0;
        final bodySize = isWide ? 15.0 : 14.0;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                color: AppTheme.getSecondaryTextColor(context),
                size: iconSize,
              ),
              SizedBox(height: isWide ? 20 : 16),
              Text(
                'No readable content available',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              SizedBox(height: isWide ? 10 : 8),
              Text(
                'This book may not be available in a readable format',
                style: TextStyle(
                  fontSize: bodySize,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isWide ? 30 : 24),
              ElevatedButton(
                onPressed: _showFormatSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Another Format'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebView(BuildContext context, String url) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final padding = isWide ? 24.0 : 16.0;
        return Container(
          margin: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF374151) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(padding),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reading ${_getFormatDisplayName(_selectedFormat)} format',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showFormatSelection,
                      child: Text(
                        'Change',
                        style: TextStyle(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: _buildWebFallback(context, url),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebFallback(BuildContext context, String url) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.web_rounded,
            color: AppTheme.getSecondaryTextColor(context),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Web Content Viewer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This book is available in web format',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _launchUrl(url),
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open in Browser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String get _bookTitle {
    final book = widget.book;
    if (book is Book) return book.title;
    if (book is Map) return book['title']?.toString() ?? 'Book';
    return 'Book';
  }

  Widget _buildPDFViewer(BuildContext context, String url,
      {String? localFilePath, double? horizontalPadding}) {
    final padding = horizontalPadding ?? 16.0;
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF374151) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: kIsWeb
            ? (_blobUrl != null
                ? PagedPdfViewer.network(
                    _blobUrl!,
                    key: ValueKey(_blobUrl),
                    title: _bookTitle,
                    isDark: _isDarkMode,
                    accentColor: const Color(0xFF10B981),
                  )
                : PagedPdfViewer.network(
                    mediaProxyUrl(url),
                    key: ValueKey(url),
                    title: _bookTitle,
                    isDark: _isDarkMode,
                    accentColor: const Color(0xFF10B981),
                  ))
            : (localFilePath != null
                ? PagedPdfViewer.file(
                    File(localFilePath),
                    title: _bookTitle,
                    isDark: _isDarkMode,
                    accentColor: const Color(0xFF10B981),
                  )
                : PagedPdfViewer.network(
                    mediaProxyUrl(url),
                    key: ValueKey(url),
                    title: _bookTitle,
                    isDark: _isDarkMode,
                    accentColor: const Color(0xFF10B981),
                  )),
      ),
    );
  }

  Widget _buildDownloadWidget(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final iconSize = isWide ? 80.0 : 64.0;
        final titleSize = isWide ? 20.0 : 18.0;
        final bodySize = isWide ? 15.0 : 14.0;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.download_rounded,
                color: const Color(0xFF10B981),
                size: iconSize,
              ),
              SizedBox(height: isWide ? 20 : 16),
              Text(
                'Download Available',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              SizedBox(height: isWide ? 10 : 8),
              Text(
                'This book is available for download',
                style: TextStyle(
                  fontSize: bodySize,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
              SizedBox(height: isWide ? 30 : 24),
              ElevatedButton.icon(
                onPressed: _handleDownloadFromMenu,
                icon: const Icon(Icons.download),
                label: const Text('Download Book'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'format':
        _showFormatSelection();
        break;
      case 'font_size':
        _showFontSizeSelection();
        break;
      case 'theme':
        setState(() {
          _isDarkMode = !_isDarkMode;
        });
        break;
      case 'download':
        _handleDownloadFromMenu();
        break;
      case 'tts':
        _showTTSSettings();
        break;
    }
  }

  void _showFormatSelection() {
    if (widget.book is! Book) return;
    final book = widget.book as Book;
    if (book.formats == null || book.formats!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Format'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: book.formats!.length,
            itemBuilder: (context, index) {
              final entry = book.formats!.entries.elementAt(index);
              final format = entry.key;
              final isSelected = format == _selectedFormat;
              
              return ListTile(
                title: Text(_getFormatDisplayName(format)),
                subtitle: Text(format),
                trailing: isSelected 
                    ? const Icon(Icons.check, color: Color(0xFF10B981))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedFormat = format;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFontSizeSelection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: _fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 6,
              label: '${_fontSize.toInt()}',
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
            ),
            Text(
              'Preview: ${_fontSize.toInt()}px',
              style: TextStyle(fontSize: _fontSize),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _handleDownloadFromMenu() {
    final target = resolveBookDownload(widget.book);

    if (target == null) {
      String bookTitle = 'this book';
      if (widget.book is Book) {
        bookTitle = (widget.book as Book).title;
      } else if (widget.book is Map) {
        final bookMap = widget.book as Map;
        bookTitle = bookMap['title']?.toString() ??
                    bookMap['name']?.toString() ??
                    'this book';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No download URL available for $bookTitle'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    _downloadBook(target);
  }

  void _downloadBook(BookDownloadTarget target) async {
    try {
      final downloadService = DownloadService();

      // Show download started snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading "${target.title}"... Find it in Downloads › Materials.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Use DownloadService to download to app's internal storage
      await downloadService.downloadNotesOrMaterial(
        url: target.url,
        title: target.title,
        lessonId: target.lessonId,
        type: DownloadType.material,
        lessonTitle: target.author,
        sectionTitle: 'Library',
        fileExtension: target.fileExtension,
        thumbnailUrl: target.coverUrl,
        onProgress: (progress) {
          // Progress is handled internally by DownloadService
        },
        onSuccess: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${target.title}" downloaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Download failed: $error'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading book: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _launchUrl(String url) async {
    try {
      print('Attempting to launch URL: $url');
      final uri = Uri.parse(url);
      print('Parsed URI: $uri');
      
      // Try external browser first
      if (await canLaunchUrl(uri)) {
        print('canLaunchUrl returned true, attempting to launch...');
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication
        );
        print('Launch result: $launched');
        
        if (launched) {
          return; // Success!
        }
      }
      
      // Fallback: try in-app webview
      print('External browser failed, trying in-app webview...');
      _showInAppWebView(url);
      
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        _showErrorDialog(url, e.toString());
      }
    }
  }

  void _showInAppWebView(String url) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('External browser not available. Would you like to:'),
            const SizedBox(height: 16),
            Link(
              uri: Uri.parse(url),
              target: LinkTarget.blank,
              builder: (context, followLink) => ElevatedButton.icon(
                onPressed: followLink,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _copyUrlToClipboard(url);
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy URL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7280),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _copyUrlToClipboard(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL copied to clipboard!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
      Navigator.of(context).pop();
    } catch (e) {
      // Fallback to showing URL if clipboard fails
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Book URL'),
          content: SingleChildScrollView(
            child: SelectableText(url),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showErrorDialog(String url, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Open Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $error'),
            const SizedBox(height: 16),
            const Text('You can try opening the book manually:'),
            const SizedBox(height: 8),
            SelectableText(url),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getFormatDisplayName(String format) {
    switch (format) {
      case 'text/plain':
        return 'Plain Text';
      case 'text/html':
        return 'HTML';
      case 'application/pdf':
        return 'PDF';
      case 'application/epub+zip':
        return 'EPUB';
      case 'application/zip':
        return 'ZIP';
      default:
        return format.split('/').last.toUpperCase();
    }
  }

  // TTS Controls Panel
  Widget _buildTTSControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          top: BorderSide(
            color: _isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_isPlaying && !_isPaused)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _showTTSTextInputDialog(),
                  tooltip: 'Start Reading',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              if (_isPlaying)
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: _pause,
                  tooltip: 'Pause',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                  ),
                ),
              if (_isPaused)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _resume,
                  tooltip: 'Resume',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: _stop,
                tooltip: 'Stop',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showTTSSettings,
                tooltip: 'Settings',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Speed control
          Row(
            children: [
              const Icon(Icons.speed, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _speechRate,
                  min: 0.25,
                  max: 1.0,
                  divisions: 3,
                  label: '${(_speechRate * 2).toStringAsFixed(1)}x',
                  onChanged: _setSpeechRate,
                ),
              ),
              Text(
                '${(_speechRate * 2).toStringAsFixed(1)}x',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTTSTextInputDialog() {
    final isAdminBook = widget.book is! Book;
    final title = isAdminBook 
        ? (widget.book['title'] ?? 'Untitled')
        : widget.book.title;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text to Read'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter text to read aloud...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _currentText = value;
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _currentText = title;
                Navigator.pop(context);
                _speak(_currentText);
              },
              child: const Text('Read Book Title'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _speak(_currentText);
            },
            child: const Text('Read'),
          ),
        ],
      ),
    );
  }

  void _showTTSOptionDialog() {
    final isAdminBook = widget.book is! Book;
    
    if (isAdminBook) {
      final book = widget.book as Map<String, dynamic>;
      final textContent = book['textContent'] as String?;
      
      if (textContent != null && textContent.isNotEmpty) {
        // Text is available, start reading directly
        _speak(textContent);
      } else {
        // No text available, show paste option
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Voice Reader'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Text Not Available',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text('This book does not have extracted text available for reading.'),
                const SizedBox(height: 12),
                const Text('You can paste text from the PDF to have it read aloud.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showTTSTextInputDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Paste Text to Read'),
              ),
            ],
          ),
        );
      }
    } else {
      // For Gutenberg books, show the regular text input dialog
      _showTTSTextInputDialog();
    }
  }

  void _showTTSSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text-to-Speech Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voice selection
              const Text('Voice', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedVoice,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _availableVoices.map((voice) {
                  return DropdownMenuItem(
                    value: voice,
                    child: Text(
                      voice.length > 30 ? '${voice.substring(0, 30)}...' : voice,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _setVoice(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Speech rate
              const Text('Speech Rate', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Slider(
                value: _speechRate,
                min: 0.25,
                max: 1.0,
                divisions: 3,
                label: '${(_speechRate * 2).toStringAsFixed(1)}x',
                onChanged: _setSpeechRate,
              ),
              const SizedBox(height: 16),
              // Pitch
              const Text('Pitch', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Slider(
                value: _pitch,
                min: 0.5,
                max: 2.0,
                divisions: 3,
                label: _pitch.toStringAsFixed(1),
                onChanged: _setPitch,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
