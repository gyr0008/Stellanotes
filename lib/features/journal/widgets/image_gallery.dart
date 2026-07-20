import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../../core/storage/image_repository.dart';

/// 图片浏览器
///
/// 支持缩放、滑动浏览多张图片。
class ImageGallery extends StatefulWidget {
  final List<String> imageFileNames;
  final int initialIndex;

  const ImageGallery({
    super.key,
    required this.imageFileNames,
    this.initialIndex = 0,
  });

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  late PageController _pageController;
  late int _currentIndex;
  final ImageRepository _imageRepo = ImageRepository();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.imageFileNames.length}'),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: FileImageProvider(
              imageRepo: _imageRepo,
              fileName: widget.imageFileNames[index],
            ),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        itemCount: widget.imageFileNames.length,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

/// 异步文件图片加载器
class FileImageProvider extends ImageProvider<FileImageProvider> {
  final ImageRepository imageRepo;
  final String fileName;

  const FileImageProvider({
    required this.imageRepo,
    required this.fileName,
  });

  @override
  Future<FileImageProvider> obtainKey(ImageConfiguration configuration) async {
    return this;
  }

  @override
  ImageStreamCompleter loadImage(
    FileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadCodec(ImageDecoderCallback decode) async {
    final path = await imageRepo.getImagePath(fileName);
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Image file not found: $path');
    }
    final bytes = await file.readAsBytes();
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }
}
