/// Stub for non-web platforms: blob caching is not available.
Future<String?> cachePdfAsBlob(String url) async => null;

/// Stub for non-web platforms: no blob URLs to revoke.
void revokeBlobUrl(String? url) {}
