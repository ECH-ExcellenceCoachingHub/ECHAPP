import 'dart:html' as html;
import 'package:http/http.dart' as http;

/// Downloads [url] and caches it as a blob URL for instant re-load on web.
///
/// Returns the blob URL, or null if caching failed (caller falls back to
/// network loading).
Future<String?> cachePdfAsBlob(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final blob = html.Blob([response.bodyBytes]);
      return html.Url.createObjectUrlFromBlob(blob);
    }
  } catch (_) {
    // Fall back to network loading.
  }
  return null;
}

/// Revokes a previously created blob URL to free memory.
void revokeBlobUrl(String? url) {
  if (url != null) {
    html.Url.revokeObjectUrl(url);
  }
}
