import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../network/api_client.dart';
import '../../network/media_url.dart';
import '../../utils/extensions.dart';
import '../../../injection_container.dart';

/// Uploads are served from an authenticated endpoint, so the bearer token has to
/// travel with the image request. The header is memoised for a few minutes to
/// avoid asking Firebase for a token on every rebuild.
class AuthImageHeaders {
  const AuthImageHeaders._();

  static Map<String, String>? _cached;
  static DateTime? _fetchedAt;

  static Future<Map<String, String>> resolve() async {
    final now = DateTime.now();
    if (_cached != null && _fetchedAt != null && now.difference(_fetchedAt!) < const Duration(minutes: 5)) {
      return _cached!;
    }
    final headers = await sl<ApiClient>().authHeaders();
    _cached = headers;
    _fetchedAt = now;
    return headers;
  }

  /// Called on logout so the next user never reuses the previous token.
  static void invalidate() {
    _cached = null;
    _fetchedAt = null;
  }
}

/// Network image with auth headers, shimmer placeholder and a graceful fallback.
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.localFilePath,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  /// Shown instead of [url] while a freshly picked file is not uploaded yet.
  final String? localFilePath;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    if (localFilePath != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.file(File(localFilePath!), width: width, height: height, fit: fit),
      );
    }

    final imageUrl = resolveMediaUrl(url);
    if (imageUrl.isBlank) {
      return _Fallback(width: width, height: height, radius: radius, icon: fallbackIcon);
    }

    return ClipRRect(
      borderRadius: radius,
      child: FutureBuilder<Map<String, String>>(
        future: AuthImageHeaders.resolve(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _Fallback(width: width, height: height, radius: radius, icon: fallbackIcon, isLoading: true);
          }
          return CachedNetworkImage(
            imageUrl: imageUrl,
            cacheKey: imageUrl,
            httpHeaders: snapshot.data,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 180),
            placeholder: (_, __) => _Fallback(width: width, height: height, radius: radius, icon: fallbackIcon, isLoading: true),
            errorWidget: (_, __, ___) => _Fallback(width: width, height: height, radius: radius, icon: fallbackIcon),
          );
        },
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({this.width, this.height, required this.radius, required this.icon, this.isLoading = false});

  final double? width;
  final double? height;
  final BorderRadius radius;
  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: radius),
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, color: scheme.onSurfaceVariant, size: 28),
    );
  }
}

/// Circular avatar that falls back to the user's initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.imageUrl, required this.name, this.radius = 28, this.localFilePath});

  final String? imageUrl;
  final String name;
  final double radius;
  final String? localFilePath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = localFilePath != null || !(imageUrl ?? '').isBlank;

    if (!hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primaryContainer,
        child: Text(
          name.initials,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.7,
          ),
        ),
      );
    }

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: CachedImage(
        url: imageUrl,
        localFilePath: localFilePath,
        width: radius * 2,
        height: radius * 2,
        borderRadius: BorderRadius.circular(radius),
        fallbackIcon: Icons.person_outline,
      ),
    );
  }
}
