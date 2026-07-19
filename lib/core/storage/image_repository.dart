import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// 图片存储仓库
///
/// 管理日记图片的存储和压缩。
class ImageRepository {
  static const _uuid = Uuid();

  /// 获取图片存储目录
  Future<Directory> _getImageDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  /// 保存图片并返回相对路径
  Future<String> saveImage(File imageFile) async {
    final imageDir = await _getImageDir();
    final fileName = '${_uuid.v4()}.jpg';
    final targetPath = '${imageDir.path}/$fileName';

    // 压缩图片
    final compressed = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 85,
      minWidth: 1024,
      minHeight: 1024,
    );

    if (compressed == null) {
      throw Exception('图片压缩失败');
    }

    // 删除原图
    if (imageFile.absolute.path != targetPath) {
      await imageFile.delete();
    }

    return fileName;
  }

  /// 获取图片完整路径
  Future<String> getImagePath(String fileName) async {
    final imageDir = await _getImageDir();
    return '${imageDir.path}/$fileName';
  }

  /// 删除图片
  Future<void> deleteImage(String fileName) async {
    final imagePath = await getImagePath(fileName);
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 获取所有图片文件
  Future<List<File>> getAllImages() async {
    final imageDir = await _getImageDir();
    if (!await imageDir.exists()) {
      return [];
    }
    return imageDir.listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.jpg'))
        .toList();
  }
}
