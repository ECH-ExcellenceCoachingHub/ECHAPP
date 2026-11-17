import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/custom_video_player.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/optimized_video_player.dart';
import 'package:excellencecoachinghub/presentation/widgets/downloaded_material_viewer.dart';
import 'package:excellencecoachinghub/presentation/widgets/download_thumbnail.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:excellencecoachinghub/presentation/widgets/document_viewer/paged_pdf_viewer.dart';
import 'package:excellencecoachinghub/utils/screen_wakelock.dart';
import 'package:excellencecoachinghub/services/connectivity_service.dart';
import 'dart:io';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key, this.initialTab});

  /// Which tab to open on: 'materials' for notes/materials (including books
  /// saved from the Library), anything else for videos.
  final String? initialTab;

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

/// A labelled divider between the groups on a downloads tab.
class _SectionHeaderData {
  const _SectionHeaderData(this.label, this.icon, this.count, this.color);

  final String label;
  final IconData icon;
  final int count;
  final Color color;
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> with TickerProviderStateMixin {
  static const List<DownloadType> _videoTypes = [DownloadType.video];
  static const List<DownloadType> _materialTypes = [DownloadType.notes, DownloadType.material];

  String _searchQuery = '';
  DownloadStatus? _statusFilter;
  late TabController _tabController;
  late final DownloadService _downloadService;

  /// Disk usage shown in the stats bar. Measuring it touches every downloaded
  /// file, so it's only re-measured when the set of finished downloads changes
  /// — not on every progress tick.
  int _storageBytes = 0;
  String? _storageSignature;

  @override
  void initState() {
    super.initState();
    // Videos, Materials (notes are shown under Materials)
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'materials' ? 1 : 0,
    );

    _downloadService = ref.read(downloadServiceProvider);
    _downloadService.addListener(_onDownloadsChanged);
    _onDownloadsChanged();
  }

  @override
  void dispose() {
    _downloadService.removeListener(_onDownloadsChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onDownloadsChanged() {
    final signature = _downloadService
        .getAllDownloads()
        .where((download) => download.status == DownloadStatus.completed)
        .map((download) => download.id)
        .join('|');
    if (signature == _storageSignature) return;
    _storageSignature = signature;
    _measureStorage(signature);
  }

  Future<void> _measureStorage(String signature) async {
    final bytes = await _downloadService.getTotalDownloadedSize();
    // A newer measurement may have started while this one was running.
    if (!mounted || signature != _storageSignature) return;
    setState(() => _storageBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = ref.watch(downloadServiceProvider);
    // Resolved once so the tab labels and the lists they open can never
    // disagree about how much is in there.
    final videos = _visibleDownloads(_videoTypes, downloadService);
    final materials = _visibleDownloads(_materialTypes, downloadService);
    final allDownloads = downloadService.getAllDownloads();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: context.canPop() ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ) : null,
        title: const Text('My Downloads'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.getTextColor(context),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.greyColor,
          indicatorColor: AppTheme.primaryGreen,
          tabs: [
            _buildTab('Videos', Icons.video_file, videos.length),
            _buildTab('Materials/Books', Icons.attach_file, materials.length),
          ],
        ),
        actions: [
          PopupMenuButton<DownloadStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) => setState(() => _statusFilter = status),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Status')),
              const PopupMenuItem(value: DownloadStatus.completed, child: Text('Completed')),
              const PopupMenuItem(value: DownloadStatus.downloading, child: Text('Downloading')),
              const PopupMenuItem(value: DownloadStatus.paused, child: Text('Paused')),
              const PopupMenuItem(value: DownloadStatus.failed, child: Text('Failed')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          ListenableBuilder(
            listenable: ConnectivityService.instance,
            builder: (context, _) => _buildOfflineNotice(context),
          ),
          _buildStatsBar(context, allDownloads),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search downloads...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.getCardColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (query) => setState(() => _searchQuery = query),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVideosList(videos, downloadService),
                _buildMaterialsList(materials, downloadService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when the offline guard redirected the user here, so the jump to
  /// Downloads doesn't look like a bug.
  Widget _buildOfflineNotice(BuildContext context) {
    final connectivity = ConnectivityService.instance;
    if (!connectivity.isOffline || connectivity.blockedLocation == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "You're offline. That page needs a connection, so here's what you "
              'already downloaded.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.getTextColor(context).withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Downloads of [types] that survive the current search and status filter.
  List<Download> _visibleDownloads(List<DownloadType> types, DownloadService downloadService) {
    final query = _searchQuery.toLowerCase();
    return types
        .expand((type) => downloadService.getDownloadsByType(type))
        .where((download) {
          final matchesSearch = query.isEmpty ||
              download.originalTitle.toLowerCase().contains(query) ||
              (download.lessonTitle?.toLowerCase().contains(query) ?? false);
          final matchesStatus = _statusFilter == null || download.status == _statusFilter;
          return matchesSearch && matchesStatus;
        })
        .toList();
  }

  /// Tab label carrying how much is inside, so it's obvious at a glance which
  /// tab has content without opening it.
  Tab _buildTab(String label, IconData icon, int count) {
    return Tab(
      icon: Icon(icon),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            _buildCountPill(count, AppTheme.primaryGreen),
          ],
        ],
      ),
    );
  }

  /// What's on this device, at a glance: how many of each kind of download and
  /// how much room they take up. Counts everything, not just what the current
  /// search matches, so the totals stay steady while filtering.
  Widget _buildStatsBar(BuildContext context, List<Download> all) {
    if (all.isEmpty) return const SizedBox.shrink();

    final videos = all.where((d) => d.type == DownloadType.video).length;
    final books = all.where((d) => d.isBook).length;
    final materials =
        all.where((d) => d.type != DownloadType.video && !d.isBook).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _buildStatChip(
            Icons.play_circle_fill,
            AppTheme.primaryGreen,
            '$videos',
            videos == 1 ? 'Video' : 'Videos',
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            Icons.menu_book_rounded,
            Colors.blue,
            '$books',
            books == 1 ? 'Book' : 'Books',
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            Icons.attach_file,
            AppTheme.accent,
            '$materials',
            materials == 1 ? 'Material' : 'Materials',
          ),
          if (_storageBytes > 0) ...[
            const SizedBox(width: 8),
            _buildStatChip(
              Icons.sd_storage_rounded,
              AppTheme.greyColor,
              _formatBytes(_storageBytes),
              'used',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                TextSpan(
                  text: ' $label',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB'];
    double size = bytes / 1024;
    int unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[unit]}';
  }

  Widget _buildCountPill(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildVideosList(List<Download> videos, DownloadService downloadService) {
    if (videos.isEmpty) return _buildEmptyState(DownloadType.video);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: videos.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSectionHeader(
            'Videos',
            Icons.play_circle_fill,
            videos.length,
            AppTheme.primaryGreen,
          );
        }
        return _buildDownloadItem(videos[index - 1], downloadService);
      },
    );
  }

  /// Books saved from the Library and materials attached to lessons both live
  /// on this tab, so each gets its own labelled, counted section instead of one
  /// undifferentiated list.
  Widget _buildMaterialsList(List<Download> materials, DownloadService downloadService) {
    if (materials.isEmpty) return _buildEmptyState(DownloadType.notes);

    final books = materials.where((download) => download.isBook).toList();
    final lessonMaterials = materials.where((download) => !download.isBook).toList();

    final rows = <Object>[];
    if (books.isNotEmpty) {
      rows.add(_SectionHeaderData('Books', Icons.menu_book_rounded, books.length, Colors.blue));
      rows.addAll(books);
    }
    if (lessonMaterials.isNotEmpty) {
      rows.add(_SectionHeaderData(
        'Course materials',
        Icons.attach_file,
        lessonMaterials.length,
        AppTheme.accent,
      ));
      rows.addAll(lessonMaterials);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row is _SectionHeaderData) {
          return _buildSectionHeader(row.label, row.icon, row.count, row.color);
        }
        return _buildDownloadItem(row as Download, downloadService);
      },
    );
  }

  Widget _buildSectionHeader(String label, IconData icon, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(width: 8),
          _buildCountPill(count, color),
        ],
      ),
    );
  }

  Widget _buildEmptyState([DownloadType? type]) {
    final bool isMaterials = type != null && type != DownloadType.video;
    final bool isFiltering = _searchQuery.isNotEmpty || _statusFilter != null;

    final String message;
    if (isFiltering) {
      message = 'Nothing matches here';
    } else if (isMaterials) {
      message = 'No materials or books yet';
    } else if (type != null) {
      message = 'No ${type.name} downloads found';
    } else {
      message = 'No downloads found';
    }

    final String subMessage;
    if (isFiltering) {
      subMessage = 'Try adjusting your search or filters';
    } else if (isMaterials) {
      subMessage = 'Download books from the Library, or lesson materials, to read them offline';
    } else if (type != null) {
      subMessage = 'Download ${type.name} to access them offline';
    } else {
      subMessage = 'Download videos to watch them offline';
    }

    final IconData icon = isFiltering
        ? Icons.search_off_rounded
        : (type != null
            ? (type == DownloadType.video ? Icons.video_file : Icons.attach_file)
            : Icons.download_outlined);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppTheme.greyColor.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(fontSize: 18, color: AppTheme.greyColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            subMessage,
            style: TextStyle(fontSize: 14, color: AppTheme.greyColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(Download download, DownloadService downloadService) {
    final bool isCompleted = download.status == DownloadStatus.completed;
    final bool isDownloading = download.status == DownloadStatus.downloading;
    final bool isPaused = download.status == DownloadStatus.paused;
    final bool isFailed = download.status == DownloadStatus.failed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: isCompleted ? () => _openContent(download) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Opacity(
                    // An unfinished download reads as pending rather than ready.
                    opacity: isCompleted ? 1 : 0.55,
                    child: DownloadThumbnail(download: download),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          download.originalTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (download.lessonTitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            download.lessonTitle!,
                            style: TextStyle(fontSize: 12, color: AppTheme.getSecondaryTextColor(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusBadge(download.status),
                            const SizedBox(width: 8),
                            Text(
                              _getTypeLabel(download),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getTypeColor(download),
                              ),
                            ),
                            if (isDownloading || isPaused || isFailed) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${(max(0, download.downloadProgress) * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w600, 
                                  color: isFailed ? Colors.red : AppTheme.greyColor
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildActions(download, downloadService),
                ],
              ),
              if (isDownloading || isPaused || isFailed) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: download.downloadProgress < 0 ? null : download.downloadProgress,
                    backgroundColor: (isFailed ? Colors.red : AppTheme.primaryGreen).withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaused ? AppTheme.greyColor : (isFailed ? Colors.red : AppTheme.primaryGreen),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DownloadStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case DownloadStatus.completed:
        color = AppTheme.primaryGreen;
        text = 'COMPLETED';
        break;
      case DownloadStatus.downloading:
        color = Colors.blue;
        text = 'DOWNLOADING';
        break;
      case DownloadStatus.paused:
        color = Colors.orange;
        text = 'PAUSED';
        break;
      case DownloadStatus.failed:
        color = Colors.red;
        text = 'FAILED';
        break;
      case DownloadStatus.pending:
        color = Colors.grey;
        text = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildActions(Download download, DownloadService downloadService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (download.status == DownloadStatus.downloading)
          IconButton(
            icon: const Icon(Icons.pause_circle_outline, color: Colors.blue),
            onPressed: () => downloadService.pauseDownload(download.id),
            tooltip: 'Pause',
          )
        else if (download.status == DownloadStatus.paused || download.status == DownloadStatus.failed)
          IconButton(
            icon: Icon(
              download.status == DownloadStatus.failed ? Icons.refresh : Icons.play_circle_outline,
              color: download.status == DownloadStatus.failed ? Colors.red : Colors.blue
            ),
            onPressed: () => downloadService.resumeDownload(download.id),
            tooltip: download.status == DownloadStatus.failed ? 'Retry' : 'Resume',
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.greyColor),
          onSelected: (value) {
            if (value == 'delete') _confirmDelete(download, downloadService);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmDelete(Download download, DownloadService downloadService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Are you sure you want to delete "${download.originalTitle}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              downloadService.deleteDownload(download.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// What the row calls itself. A saved book says BOOK rather than MATERIAL,
  /// which is what it happens to be stored as.
  String _getTypeLabel(Download download) {
    return download.isBook ? 'BOOK' : download.type.name.toUpperCase();
  }

  Color _getTypeColor(Download download) {
    if (download.isBook) return Colors.blue;
    switch (download.type) {
      case DownloadType.video:
        return AppTheme.primaryGreen;
      case DownloadType.notes:
        return Colors.blue;
      case DownloadType.material:
        return AppTheme.accent;
    }
  }

  void _openContent(Download download) {
    switch (download.type) {
      case DownloadType.video:
        _playVideo(download);
        break;
      case DownloadType.notes:
        _openNotes(download);
        break;
      case DownloadType.material:
        _openMaterial(download);
        break;
    }
  }

  void _openNotes(Download download) {
    // Lesson notes written in the app keep their text in `url` and have no file
    // on disk; everything else (PDFs, downloaded books) opens from local storage.
    if (download.localPath.isEmpty || !File(download.localPath).existsSync()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _buildNotesViewer(download),
        ),
      );
      return;
    }
    openDownloadedMaterial(context, download);
  }

  void _openMaterial(Download download) {
    openDownloadedMaterial(context, download);
  }

  Widget _buildNotesViewer(Download download) {
    return KeepScreenAwake(
      child: Scaffold(
        appBar: AppBar(
          title: Text(download.originalTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          padding: const EdgeInsets.all(16),
          child: download.url.toLowerCase().endsWith('.pdf') || download.localPath.toLowerCase().endsWith('.pdf')
              ? PagedPdfViewer.file(File(download.localPath), title: download.originalTitle)
              : SingleChildScrollView(
                  child: MarkdownBody(
                    data: download.url, // For text notes, URL contains the content
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      h2: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      p: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _playVideo(Download download) async {
    print('Playing downloaded video:');
    print('  localPath: ${download.localPath}');
    print('  fileName: ${download.fileName}');
    print('  lessonId: ${download.lessonId}');

    // Verify the file exists before trying to play
    final file = File(download.localPath);
    if (!await file.exists()) {
      print('File does not exist at: ${download.localPath}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video file not found. Please download again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check file size to ensure it's not empty
    final fileSize = await file.length();
    print('  File size: $fileSize bytes');
    if (fileSize == 0) {
      print('File is empty, cannot play');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video file is corrupted. Please download again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check file header to verify it's a valid MP4
    try {
      final bytes = await file.openRead(0, 12).first;
      if (bytes.length < 12) {
        print('File is too small to be a valid video');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video file is corrupted. Please download again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // MP4 files start with 'ftyp' (bytes: 66 74 79 70) at offset 4
      final isMp4 = bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70;
      print('  File header check: isMp4=$isMp4');
      print('  First 12 bytes: $bytes');

      if (!isMp4) {
        print('File is not a valid MP4 file');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video file is corrupted or invalid format. Please download again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (e) {
      print('Error reading file header: $e');
      // If header check fails, continue anyway - the file might still be valid
      print('Skipping header check, attempting to play video anyway');
    }

    // Check if file has .mp4 extension, if not add it
    String videoPath = download.localPath;
    if (!videoPath.toLowerCase().endsWith('.mp4')) {
      videoPath = '$videoPath.mp4';
      final fileWithExt = File(videoPath);
      if (!await fileWithExt.exists()) {
        print('File with .mp4 extension does not exist at: $videoPath');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video file not found. Please download again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // For Android, use raw path without file:// prefix (ExoPlayer needs raw path)
    // For iOS, use file:// prefix
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (videoPath.startsWith('file://')) {
        videoPath = videoPath.replaceFirst('file://', '');
      }
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      if (!videoPath.startsWith('file://')) {
        videoPath = 'file://$videoPath';
      }
    }

    print('  Final video path: $videoPath');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
// better_player has no web implementation; use video_player/chewie (CustomVideoPlayer) on browsers.
          if (kIsWeb) {
            return CustomVideoPlayer(
              videoId: download.lessonId,
              videoUrl: videoPath,
              title: download.originalTitle,
              description: 'Local video file',
              showAppBar: true,
            );
          } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
            return OptimizedVideoPlayer(
              videoId: download.lessonId,
              videoUrl: videoPath,
              title: download.originalTitle,
              description: 'Local video file',
              showAppBar: true,
            );
          } else {
            return CustomVideoPlayer(
              videoId: download.lessonId,
              videoUrl: videoPath,
              title: download.originalTitle,
              description: 'Local video file',
              showAppBar: true,
            );
          }
        },
      ),
    );
  }
}
