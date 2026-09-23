import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/media_url.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../core/widgets/media/cached_image.dart';
import '../../../../../injection_container.dart';

/// Arguments passed through GoRouter's `extra`.
class FileViewerArgs {
  const FileViewerArgs({required this.url, this.title = 'Attachment', this.isPdf = false});

  final String url;
  final String title;
  final bool isPdf;
}

/// Full-screen viewer for animal photos, profile pictures and claim evidence.
/// Images are shown with pinch-zoom; PDFs are downloaded with the auth header
/// first, because the native PDF view cannot send headers itself.
class FileViewerPage extends StatefulWidget {
  const FileViewerPage({super.key, required this.args});

  final FileViewerArgs args;

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  String? _localPdfPath;
  String? _error;
  bool _isLoading = false;

  bool get _isPdf => widget.args.isPdf || widget.args.url.toLowerCase().endsWith('.pdf');

  @override
  void initState() {
    super.initState();
    if (_isPdf) _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final directory = await getTemporaryDirectory();
    final fileName = p.basename(Uri.parse(resolveMediaUrl(widget.args.url)).path);
    final savePath = p.join(directory.path, fileName.isEmpty ? 'evidence.pdf' : fileName);

    final result = await sl<ApiClient>().download(widget.args.url, savePath);
    if (!mounted) return;
    result.fold(
      (path) => setState(() {
        _localPdfPath = path;
        _isLoading = false;
      }),
      (error) => setState(() {
        _error = error.message;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.args.title),
        actions: [
          if (_isPdf)
            IconButton(
              tooltip: 'Reload',
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _downloadPdf,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return EmptyState.error(title: 'Could not open the file', message: _error, onAction: _downloadPdf);
    }
    if (_isLoading) {
      return const AppLoader(message: 'Downloading document...');
    }

    if (_isPdf) {
      final path = _localPdfPath;
      if (path == null || !File(path).existsSync()) {
        return EmptyState.error(title: 'Document unavailable', onAction: _downloadPdf);
      }
      return PDFView(
        filePath: path,
        enableSwipe: true,
        swipeHorizontal: false,
        fitPolicy: FitPolicy.BOTH,
        onError: (error) => setState(() => _error = error.toString()),
      );
    }

    return PhotoView.customChild(
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      child: CachedImage(
        url: widget.args.url,
        fit: BoxFit.contain,
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}
