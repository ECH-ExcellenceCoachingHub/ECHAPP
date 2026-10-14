import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

import 'video_api_service.dart';

/// Downloads a lesson video straight to the admin's computer.
///
/// Students download videos into the app's private storage for offline
/// playback (see `DownloadService`). Admins instead need the raw file on disk
/// (e.g. to reuse a lesson in other material), so this service streams the
/// video to a destination the admin picks with the standard OS save dialog.
class AdminVideoDownloadService {
  AdminVideoDownloadService({VideoApiService? videoApiService, Dio? dio})
      : _videoApiService = videoApiService ?? VideoApiService(),
        _dio = dio ?? Dio();

  final VideoApiService _videoApiService;
  final Dio _dio;

  static const List<String> _videoExtensions = [
    'mp4',
    'mov',
    'mkv',
    'webm',
    'avi',
    'wmv',
    'flv',
    'm4v',
    'mpeg',
    'mpg',
    '3gp',
    'ts',
  ];

  /// Streams the lesson's video to the admin's computer.
  ///
  /// Returns the path of the saved file, or `null` when the user dismissed the
  /// save dialog. Throws when the lesson has no video or the transfer fails.
  Future<String?> downloadLessonVideo({
    required String lessonId,
    required String suggestedName,
    CancelToken? cancelToken,
    void Function(int received, int? total)? onProgress,
  }) async {
    // 1. Ask the backend for an authorized URL of the lesson's video
    final url = await _videoApiService.getVideoStreamUrl(lessonId);
    final fileName = _resolveFileName(suggestedName, url);

    // 2. Web: hand the file to the browser's download manager
    if (kIsWeb) {
      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
      return fileName;
    }

    // 3. Desktop (where the admin dashboard runs): standard "Save As" dialog
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Lesson Video',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: _extensionsFor(fileName),
      );
      if (savePath == null) return null; // user cancelled

      final target = p.extension(savePath).isNotEmpty
          ? savePath
          : '$savePath.${p.extension(fileName)}';
      await _download(url, target, cancelToken, onProgress);
      return target;
    }

    // 4. Mobile: save to the device's downloads area and open it
    final directory = await _mobileDownloadDirectory();
    final target = p.join(directory.path, fileName);
    await _download(url, target, cancelToken, onProgress);
    await OpenFile.open(target);
    return target;
  }

  Future<void> _download(
    String url,
    String savePath,
    CancelToken? cancelToken,
    void Function(int received, int? total)? onProgress,
  ) async {
    try {
      await _dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
        options: Options(
          followRedirects: true,
          // Videos are large; dio's default receive timeout is far too short.
          receiveTimeout: const Duration(hours: 2),
        ),
      );
    } catch (_) {
      // Never leave a half-written file behind on failure or cancellation.
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  /// App-specific storage on Android (no extra permission needed) and the
  /// documents directory on iOS; the file is then opened via [OpenFile] so the
  /// admin can copy it wherever they need.
  Future<Directory> _mobileDownloadDirectory() async {
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
    }
    return getApplicationDocumentsDirectory();
  }

  /// Builds `<sanitized lesson title>.<video ext>`, preferring the extension
  /// already present in the source URL (S3 keys keep the original extension).
  String _resolveFileName(String suggestedName, String url) {
    final trimmed = suggestedName.trim();
    final base = trimmed.isEmpty ? 'lesson-video' : trimmed;

    var ext = _normalizedExtension(p.extension(base));
    if (!_videoExtensions.contains(ext)) {
      final urlExt = _normalizedExtension(
        p.extension(Uri.parse(url).path),
      );
      ext = _videoExtensions.contains(urlExt) ? urlExt : 'mp4';
    }

    final name = p.basenameWithoutExtension(
      base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_'),
    );
    return '$name.$ext';
  }

  List<String> _extensionsFor(String fileName) {
    final ext = _normalizedExtension(p.extension(fileName));
    if (ext.isNotEmpty && !_videoExtensions.contains(ext)) {
      return [..._videoExtensions, ext];
    }
    return _videoExtensions;
  }

  String _normalizedExtension(String ext) => ext.toLowerCase().replaceFirst('.', '');
}
