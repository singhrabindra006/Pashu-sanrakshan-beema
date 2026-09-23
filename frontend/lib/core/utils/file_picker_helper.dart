import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../network/api_exceptions.dart';
import '../network/result.dart';

/// A file the user selected, ready to be handed to [ApiClient.multipart].
class PickedFileRef {
  const PickedFileRef({required this.path, required this.name, required this.sizeBytes});

  final String path;
  final String name;
  final int sizeBytes;

  bool get isPdf => p.extension(path).toLowerCase() == '.pdf';
  String get readableSize => sizeBytes < 1024 * 1024
      ? '${(sizeBytes / 1024).toStringAsFixed(0)} KB'
      : '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Camera/gallery/document pickers plus the size and extension checks that keep
/// the backend from rejecting the upload.
class FilePickerHelper {
  FilePickerHelper({ImagePicker? imagePicker}) : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<Result<PickedFileRef>> pickImage({required ImageSource source}) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        // Resize on device: a 12 MP camera shot would exceed the 5 MB limit.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return Result.failure(const CancelledException());
      final stored = await _persistLocalCopy(picked.path);
      return _validate(stored, AppConstants.imageExtensions, AppConstants.maxImageBytes);
    } on Exception catch (error) {
      return Result.failure(RequestException('Could not open the picker: $error'));
    }
  }

  /// Claim evidence: an image or a PDF.
  Future<Result<PickedFileRef>> pickEvidence() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.evidenceExtensions,
      );
      if (files.isEmpty) return Result.failure(const CancelledException());
      final path = files.single.path;
      if (path == null) return Result.failure(const CancelledException());
      final stored = await _persistLocalCopy(path);
      return _validate(stored, AppConstants.evidenceExtensions, AppConstants.maxEvidenceBytes);
    } on Exception catch (error) {
      return Result.failure(RequestException('Could not open the file picker: $error'));
    }
  }

  Future<Result<PickedFileRef>> _validate(String path, List<String> allowed, int maxBytes) async {
    final file = File(path);
    if (!await file.exists()) {
      return Result.failure(const RequestException('The selected file could not be read'));
    }

    final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
    if (!allowed.contains(extension)) {
      return Result.failure(RequestException('Only ${allowed.join(', ').toUpperCase()} files are allowed'));
    }

    final size = await file.length();
    if (size > maxBytes) {
      final limitMb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
      return Result.failure(RequestException('File is larger than $limitMb MB'));
    }

    return Result.success(PickedFileRef(path: path, name: p.basename(path), sizeBytes: size));
  }

  /// Copies the picker result into app storage so Google Photos / cloud
  /// placeholders cannot disappear before the upload starts.
  Future<String> _persistLocalCopy(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;
    final dir = await getTemporaryDirectory();
    var ext = p.extension(sourcePath).toLowerCase();
    if (ext.isEmpty || ext == '.bin' || ext == '.tmp') ext = '.jpg';
    final dest = p.join(dir.path, 'lims_${DateTime.now().millisecondsSinceEpoch}$ext');
    await source.copy(dest);
    return dest;
  }

  /// Camera / Gallery bottom sheet used by the avatar and animal photo pickers.
  static Future<ImageSource?> chooseImageSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
