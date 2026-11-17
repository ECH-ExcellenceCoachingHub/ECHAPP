import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:excellencecoachinghub/config/app_theme.dart';

/// A slide-style PDF reader: one page at a time with Previous / Next controls,
/// a page counter that jumps to any page, and a progress bar — no scrolling.
///
/// Pages can also be turned by swiping, with the keyboard (← → PgUp PgDn
/// Space Home End), or with the arrow buttons over the page on wide screens.
class PagedPdfViewer extends StatefulWidget {
  /// Loads the PDF from a URL. Pass an already proxied URL on web.
  const PagedPdfViewer.network(
    String this.url, {
    super.key,
    this.initialPage = 1,
    this.title,
    this.accentColor,
    this.isDark,
    this.showFullScreenButton = true,
    this.showZoomControls = true,
    this.onLoadFailed,
  }) : file = null;

  /// Loads the PDF from a file on the device.
  const PagedPdfViewer.file(
    File this.file, {
    super.key,
    this.initialPage = 1,
    this.title,
    this.accentColor,
    this.isDark,
    this.showFullScreenButton = true,
    this.showZoomControls = true,
    this.onLoadFailed,
  }) : url = null;

  final String? url;
  final File? file;
  final int initialPage;

  /// Shown in the full-screen app bar.
  final String? title;
  final Color? accentColor;

  /// Overrides the theme brightness for the control bar.
  final bool? isDark;
  final bool showFullScreenButton;
  final bool showZoomControls;
  final void Function(String message)? onLoadFailed;

  @override
  State<PagedPdfViewer> createState() => _PagedPdfViewerState();
}

class _PagedPdfViewerState extends State<PagedPdfViewer> {
  final PdfViewerController _controller = PdfViewerController();
  final FocusNode _focusNode = FocusNode(debugLabel: 'PagedPdfViewer');

  late int _page = widget.initialPage;
  int _pageCount = 0;
  bool _loading = true;
  String? _error;
  double _zoom = 1.0;

  bool get _canGoBack => _page > 1;
  bool get _canGoForward => _pageCount > 0 && _page < _pageCount;

  Color get _accent => widget.accentColor ?? AppTheme.primaryGreen;
  bool get _dark => widget.isDark ?? Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _next() {
    if (_canGoForward) _controller.nextPage();
  }

  void _previous() {
    if (_canGoBack) _controller.previousPage();
  }

  void _goTo(int page) {
    if (_pageCount == 0) return;
    _controller.jumpToPage(page.clamp(1, _pageCount));
  }

  void _setZoom(double value) {
    final zoom = value.clamp(1.0, 3.0);
    _controller.zoomLevel = zoom;
    setState(() => _zoom = zoom);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.space) {
      _next();
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.pageUp) {
      _previous();
    } else if (key == LogicalKeyboardKey.home) {
      _goTo(1);
    } else if (key == LogicalKeyboardKey.end) {
      _goTo(_pageCount);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _handleLoadFailed(PdfDocumentLoadFailedDetails details) {
    final message = details.description.isNotEmpty ? details.description : details.error;
    setState(() {
      _loading = false;
      _error = message;
    });
    widget.onLoadFailed?.call(message);
  }

  Widget _buildPdf() {
    void onLoaded(PdfDocumentLoadedDetails details) {
      setState(() {
        _loading = false;
        _error = null;
        _pageCount = details.document.pages.count;
        _page = _page.clamp(1, _pageCount);
      });
    }

    void onPageChanged(PdfPageChangedDetails details) {
      setState(() => _page = details.newPageNumber);
    }

    void onZoomChanged(PdfZoomDetails details) {
      setState(() => _zoom = details.newZoomLevel);
    }

    if (widget.file != null) {
      return SfPdfViewer.file(
        widget.file!,
        controller: _controller,
        initialPageNumber: widget.initialPage,
        pageLayoutMode: PdfPageLayoutMode.single,
        scrollDirection: PdfScrollDirection.horizontal,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        canShowPaginationDialog: false,
        pageSpacing: 0,
        onDocumentLoaded: onLoaded,
        onDocumentLoadFailed: _handleLoadFailed,
        onPageChanged: onPageChanged,
        onZoomLevelChanged: onZoomChanged,
      );
    }
    return SfPdfViewer.network(
      widget.url!,
      controller: _controller,
      initialPageNumber: widget.initialPage,
      pageLayoutMode: PdfPageLayoutMode.single,
      scrollDirection: PdfScrollDirection.horizontal,
      canShowScrollHead: false,
      canShowScrollStatus: false,
      canShowPaginationDialog: false,
      pageSpacing: 0,
      onDocumentLoaded: onLoaded,
      onDocumentLoadFailed: _handleLoadFailed,
      onPageChanged: onPageChanged,
      onZoomLevelChanged: onZoomChanged,
    );
  }

  Future<void> _openFullScreen() async {
    final returnedPage = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenPagedPdf(
          title: widget.title,
          accentColor: _accent,
          viewerBuilder: (onPage) => _PageReporter(
            onPage: onPage,
            child: widget.file != null
                ? PagedPdfViewer.file(
                    widget.file!,
                    initialPage: _page,
                    accentColor: _accent,
                    isDark: true,
                    showFullScreenButton: false,
                    showZoomControls: widget.showZoomControls,
                  )
                : PagedPdfViewer.network(
                    widget.url!,
                    initialPage: _page,
                    accentColor: _accent,
                    isDark: true,
                    showFullScreenButton: false,
                    showZoomControls: widget.showZoomControls,
                  ),
          ),
        ),
      ),
    );
    // Pick up where the reader left off in full screen.
    if (mounted && returnedPage != null && returnedPage != _page) {
      _goTo(returnedPage);
    }
  }

  Future<void> _showJumpDialog() async {
    if (_pageCount == 0) return;
    final controller = TextEditingController(text: '$_page');
    final target = await showDialog<int>(
      context: context,
      builder: (context) {
        void submit() {
          final value = int.tryParse(controller.text.trim());
          if (value != null) Navigator.of(context).pop(value);
        }

        return AlertDialog(
          title: const Text('Go to page'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '1 – $_pageCount',
              suffixText: 'of $_pageCount',
            ),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: submit,
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (target != null) _goTo(target);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    _PageReporter.of(context)?.call(_page);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 600;
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: _dark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                        child: _buildPdf(),
                      ),
                    ),
                    if (_loading) _buildLoading(),
                    if (_error != null) _buildError(),
                    if (wide && !_loading && _error == null) ...[
                      _SideArrow(
                        alignment: Alignment.centerLeft,
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Previous page',
                        onTap: _canGoBack ? _previous : null,
                      ),
                      _SideArrow(
                        alignment: Alignment.centerRight,
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'Next page',
                        onTap: _canGoForward ? _next : null,
                      ),
                    ],
                  ],
                ),
              ),
              _buildControlBar(wide),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Positioned.fill(
      child: ColoredBox(
        color: _dark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _accent),
              const SizedBox(height: 16),
              Text(
                'Loading document…',
                style: TextStyle(
                  fontSize: 14,
                  color: _dark ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Positioned.fill(
      child: ColoredBox(
        color: _dark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                const SizedBox(height: 12),
                Text(
                  'Could not load this PDF',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _dark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _dark ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar(bool wide) {
    final surface = _dark ? const Color(0xFF1F2937) : Colors.white;
    final border = _dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final text = _dark ? Colors.white : const Color(0xFF111827);
    final muted = _dark ? Colors.white60 : const Color(0xFF6B7280);
    final progress = _pageCount > 0 ? _page / _pageCount : 0.0;
    final ready = !_loading && _error == null;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: border,
                valueColor: AlwaysStoppedAnimation(_accent),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: wide ? 12 : 6, vertical: 8),
              child: Row(
                children: [
                  if (wide)
                    _BarIcon(
                      icon: Icons.first_page_rounded,
                      tooltip: 'First page',
                      color: muted,
                      onTap: ready && _canGoBack ? () => _goTo(1) : null,
                    ),
                  _NavButton(
                    label: 'Previous',
                    icon: Icons.arrow_back_rounded,
                    showLabel: wide,
                    filled: false,
                    accent: _accent,
                    foreground: text,
                    border: border,
                    onTap: ready && _canGoBack ? _previous : null,
                  ),
                  Expanded(
                    child: Center(
                      child: Tooltip(
                        message: 'Go to page',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: ready ? _showJumpDialog : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$_page',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: text,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _pageCount > 0 ? ' / $_pageCount' : '',
                                    style: TextStyle(color: muted),
                                  ),
                                ],
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.showZoomControls && wide) ...[
                    _BarIcon(
                      icon: Icons.zoom_out_rounded,
                      tooltip: 'Zoom out',
                      color: muted,
                      onTap: ready && _zoom > 1.0 ? () => _setZoom(_zoom - 0.25) : null,
                    ),
                    _BarIcon(
                      icon: Icons.zoom_in_rounded,
                      tooltip: 'Zoom in',
                      color: muted,
                      onTap: ready && _zoom < 3.0 ? () => _setZoom(_zoom + 0.25) : null,
                    ),
                  ],
                  if (widget.showFullScreenButton)
                    _BarIcon(
                      icon: Icons.fullscreen_rounded,
                      tooltip: 'Full screen',
                      color: muted,
                      onTap: ready ? _openFullScreen : null,
                    ),
                  _NavButton(
                    label: 'Next',
                    icon: Icons.arrow_forward_rounded,
                    showLabel: true,
                    filled: true,
                    trailingIcon: true,
                    accent: _accent,
                    foreground: text,
                    border: border,
                    onTap: ready && _canGoForward ? _next : null,
                  ),
                  if (wide)
                    _BarIcon(
                      icon: Icons.last_page_rounded,
                      tooltip: 'Last page',
                      color: muted,
                      onTap: ready && _canGoForward ? () => _goTo(_pageCount) : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.showLabel,
    required this.filled,
    required this.accent,
    required this.foreground,
    required this.border,
    required this.onTap,
    this.trailingIcon = false,
  });

  final String label;
  final IconData icon;
  final bool showLabel;
  final bool filled;
  final bool trailingIcon;
  final Color accent;
  final Color foreground;
  final Color border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final iconWidget = Icon(icon, size: 18);
    final children = <Widget>[
      if (!trailingIcon) iconWidget,
      if (showLabel) ...[
        if (!trailingIcon) const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        if (trailingIcon) const SizedBox(width: 6),
      ],
      if (trailingIcon) iconWidget,
    ];
    final padding = EdgeInsets.symmetric(horizontal: showLabel ? 16 : 12, vertical: 10);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

    final button = filled
        ? FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: accent.withValues(alpha: 0.3),
              disabledForegroundColor: Colors.white70,
              padding: padding,
              minimumSize: const Size(44, 40),
              shape: shape,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          )
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: foreground,
              disabledForegroundColor: foreground.withValues(alpha: 0.3),
              side: BorderSide(color: enabled ? border : border.withValues(alpha: 0.5)),
              padding: padding,
              minimumSize: const Size(44, 40),
              shape: shape,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          );

    return Tooltip(message: '$label page', child: button);
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      color: color,
      disabledColor: color.withValues(alpha: 0.3),
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}

/// Large translucent arrow over the page edge, like a slide deck.
class _SideArrow extends StatelessWidget {
  const _SideArrow({
    required this.alignment,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final Alignment alignment;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: AnimatedOpacity(
          opacity: onTap == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: onTap == null,
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Tooltip(
                  message: tooltip,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lets the full-screen route know which page the reader is on, so the inline
/// viewer can resume there once full screen closes.
class _PageReporter extends InheritedWidget {
  const _PageReporter({required this.onPage, required super.child});

  final ValueChanged<int> onPage;

  static ValueChanged<int>? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PageReporter>()?.onPage;

  @override
  bool updateShouldNotify(_PageReporter oldWidget) => false;
}

class _FullScreenPagedPdf extends StatefulWidget {
  const _FullScreenPagedPdf({
    required this.title,
    required this.accentColor,
    required this.viewerBuilder,
  });

  final String? title;
  final Color accentColor;
  final Widget Function(ValueChanged<int> onPage) viewerBuilder;

  @override
  State<_FullScreenPagedPdf> createState() => _FullScreenPagedPdfState();
}

class _FullScreenPagedPdfState extends State<_FullScreenPagedPdf> {
  int _page = 1;
  late final Widget _viewer = widget.viewerBuilder((page) => _page = page);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_page);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF111827),
        appBar: AppBar(
          backgroundColor: const Color(0xFF111827),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.title ?? 'Document',
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.fullscreen_exit_rounded),
            tooltip: 'Exit full screen',
            onPressed: () => Navigator.of(context).pop(_page),
          ),
        ),
        body: _viewer,
      ),
    );
  }
}
