import '../constants/api_endpoints.dart';

/// Turns a backend file URL into one the current device can actually reach.
///
/// The API may return `http://10.0.2.2:4000/...` (emulator) or a LAN address.
/// A physical phone on USB must use the same host as [ApiEndpoints.baseUrl]
/// (`127.0.0.1` via `adb reverse`). Relative paths are prefixed the same way.
String resolveMediaUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';

  final api = Uri.parse(ApiEndpoints.baseUrl);
  final origin = api.hasPort
      ? '${api.scheme}://${api.host}:${api.port}'
      : '${api.scheme}://${api.host}';

  final trimmed = url.trim();
  if (!trimmed.contains('://')) {
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$origin$path';
  }

  final incoming = Uri.tryParse(trimmed);
  if (incoming == null || incoming.host.isEmpty) return trimmed;

  if (!_isRewritableHost(incoming.host)) return trimmed;

  return incoming
      .replace(
        scheme: api.scheme,
        host: api.host,
        port: api.hasPort ? api.port : null,
      )
      .toString();
}

bool _isRewritableHost(String host) {
  final lower = host.toLowerCase();
  return lower == 'localhost' ||
      lower == '127.0.0.1' ||
      lower == '10.0.2.2' ||
      lower == '0.0.0.0' ||
      lower.endsWith('.local') ||
      lower.startsWith('192.168.') ||
      lower.startsWith('10.') ||
      lower.startsWith('172.');
}
