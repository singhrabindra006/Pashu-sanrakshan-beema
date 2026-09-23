import 'package:flutter/material.dart';

import '../../../../../core/widgets/media/cached_image.dart';

/// Avatar with the camera badge used on ProfilePage.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.onEdit,
    this.onView,
    this.isUploading = false,
    this.radius = 48,
  });

  final String name;
  final String? imageUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onView;
  final bool isUploading;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: radius * 2 + 8,
      height: radius * 2 + 8,
      child: Stack(
        children: [
          GestureDetector(
            onTap: onView,
            child: UserAvatar(imageUrl: imageUrl, name: name, radius: radius),
          ),
          if (isUploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: const Center(
                  child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.4)),
                ),
              ),
            ),
          if (onEdit != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isUploading ? null : onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(Icons.photo_camera_outlined, size: 16, color: scheme.onPrimary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
