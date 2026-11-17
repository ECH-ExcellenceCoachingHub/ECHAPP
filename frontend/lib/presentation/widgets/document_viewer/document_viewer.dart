import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/widgets/document_viewer/paged_pdf_viewer.dart';
import 'package:excellencecoachinghub/utils/screen_wakelock.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';

class DocumentViewer extends StatefulWidget {
  final String documentPath;
  final String title;
  final bool isPdf;
  final bool canDownload;

  const DocumentViewer({
    super.key,
    required this.documentPath,
    required this.title,
    this.isPdf = true,
    this.canDownload = false,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {

  // A document is read, not tapped, so keep the screen on while it is open
  final ScreenWakelock _wakelock = ScreenWakelock();

  @override
  void initState() {
    super.initState();
    _wakelock.acquire();
  }

  @override
  void dispose() {
    _wakelock.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.canDownload)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _handleDownload,
              tooltip: 'Download',
            ),
        ],
      ),
      body: _buildDocumentViewer(),
    );
  }

  Widget _buildDocumentViewer() {
    if (widget.isPdf) {
      return PagedPdfViewer.network(
        mediaProxyUrl(widget.documentPath),
        title: widget.title,
        onLoadFailed: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load PDF: $message'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    }
    return _buildTextDocument();
  }

  Widget _buildTextDocument() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Document Content',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: SelectableText(
                'Title: ${widget.title}\n\n'
                'Content path: ${widget.documentPath}\n\n'
                'This document is opened in restricted view mode. Downloading is disabled for security reasons.',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppTheme.blackColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDownload() {
    // Implementation for download if canDownload is true
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality for authorized documents')),
    );
  }
}
