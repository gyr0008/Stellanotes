import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../../core/storage/storage_providers.dart';
import '../../core/storage/entry_repository.dart';
import '../../core/storage/todo_repository.dart';
import '../../core/storage/image_repository.dart';
import 'package:drift/drift.dart';
import 'package:stargazer/core/storage/database.dart';

/// 数据备份服务
///
/// 支持本地备份和恢复，可选加密。
class BackupService {
  final EntryRepository _entryRepo;
  final TodoRepository _todoRepo;
  final ImageRepository _imageRepo;

  BackupService({
    required EntryRepository entryRepo,
    required TodoRepository todoRepo,
    required ImageRepository imageRepo,
  })  : _entryRepo = entryRepo,
        _todoRepo = todoRepo,
        _imageRepo = imageRepo;

  /// 创建备份
  Future<File> createBackup({String? password}) async {
    final tempDir = await getTemporaryDirectory();
    final backupDir = Directory('${tempDir.path}/stargazer_backup_${DateTime.now().millisecondsSinceEpoch}');
    await backupDir.create(recursive: true);

    try {
      // 1. 导出日记数据
      final entries = await _entryRepo.getAllEntries();
      final entriesJson = entries.map((e) => {
        'id': e.id,
        'title': e.title,
        'content': e.content,
        'mood': e.mood,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
      }).toList();
      File('${backupDir.path}/entries.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(entriesJson),
      );

      // 2. 导出待办数据
      final todos = await _todoRepo.getAllTodos();
      final todosJson = todos.map((t) => {
        'id': t.id,
        'title': t.title,
        'done': t.done,
        'priority': t.priority,
        'createdAt': t.createdAt.toIso8601String(),
        'completedAt': t.completedAt?.toIso8601String(),
      }).toList();
      File('${backupDir.path}/todos.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(todosJson),
      );

      // 3. 复制图片文件
      final images = await _imageRepo.getAllImages();
      final imagesDir = Directory('${backupDir.path}/images');
      await imagesDir.create();
      for (final image in images) {
        await image.copy('${imagesDir.path}/${image.path.split('/').last}');
      }

      // 4. 创建 ZIP 压缩包
      final archive = Archive();
      archive.addFile(ArchiveFile('entries.json', 0, File('${backupDir.path}/entries.json').readAsBytesSync()));
      archive.addFile(ArchiveFile('todos.json', 0, File('${backupDir.path}/todos.json').readAsBytesSync()));
      
      for (final image in images) {
        final fileName = image.path.split('/').last;
        archive.addFile(ArchiveFile('images/$fileName', 0, image.readAsBytesSync()));
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw Exception('创建备份失败');
      }

      // 5. 可选加密
      final zipFile = File('${tempDir.path}/stargazer_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
      await zipFile.writeAsBytes(zipData);

      if (password != null && password.isNotEmpty) {
        final encrypted = await _encryptFile(zipFile, password);
        await zipFile.delete();
        return encrypted;
      }

      return zipFile;
    } finally {
      // 清理临时目录
      await backupDir.delete(recursive: true);
    }
  }

  /// 恢复备份
  Future<void> restoreBackup(File backupFile, {String? password}) async {
    final tempDir = await getTemporaryDirectory();
    final restoreDir = Directory('${tempDir.path}/stargazer_restore_${DateTime.now().millisecondsSinceEpoch}');
    await restoreDir.create(recursive: true);

    try {
      // 1. 解密（如果需要）
      File zipFile = backupFile;
      if (password != null && password.isNotEmpty) {
        zipFile = await _decryptFile(backupFile, password);
      }

      // 2. 解压 ZIP
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = '${restoreDir.path}/${file.name}';
        if (file.isFile) {
          final outFile = File(filename);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filename).create(recursive: true);
        }
      }

      // 3. 导入日记数据
      final entriesFile = File('${restoreDir.path}/entries.json');
      if (await entriesFile.exists()) {
        final entriesJson = jsonDecode(await entriesFile.readAsString()) as List;
        for (final entryJson in entriesJson) {
          final map = entryJson as Map<String, dynamic>;
          await _entryRepo.createEntry(EntriesCompanion(
            id: Value(map['id'] as int),
            title: Value(map['title'] as String),
            content: Value(map['content'] as String),
            mood: map['mood'] != null ? Value(map['mood'] as String) : const Value(null),
            createdAt: Value(DateTime.parse(map['createdAt'] as String)),
            updatedAt: Value(DateTime.parse(map['updatedAt'] as String)),
          ));
        }
      }

      // 4. 导入待办数据
      final todosFile = File('${restoreDir.path}/todos.json');
      if (await todosFile.exists()) {
        final todosJson = jsonDecode(await todosFile.readAsString()) as List;
        for (final todoJson in todosJson) {
          final map = todoJson as Map<String, dynamic>;
          await _todoRepo.createTodo(TodosCompanion(
            id: Value(map['id'] as int),
            title: Value(map['title'] as String),
            done: Value(map['done'] as bool),
            priority: Value(map['priority'] as int),
            createdAt: Value(DateTime.parse(map['createdAt'] as String)),
            completedAt: map['completedAt'] != null 
                ? Value(DateTime.parse(map['completedAt'] as String)) 
                : const Value(null),
          ));
        }
      }

      // 5. 恢复图片文件
      final imagesDir = Directory('${restoreDir.path}/images');
      if (await imagesDir.exists()) {
        final images = await imagesDir.list().toList();
        for (final image in images) {
          if (image is File) {
            await _imageRepo.saveImage(image);
          }
        }
      }
    } finally {
      // 清理临时目录
      await restoreDir.delete(recursive: true);
    }
  }

  /// 加密文件
  Future<File> _encryptFile(File file, String password) async {
    final key = encrypt.Key.fromUtf8(password.padRight(32, '0').substring(0, 32));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final bytes = await file.readAsBytes();
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    final encryptedFile = File('${file.path}.enc');
    await encryptedFile.writeAsBytes(encrypted.bytes);
    return encryptedFile;
  }

  /// 解密文件
  Future<File> _decryptFile(File file, String password) async {
    final key = encrypt.Key.fromUtf8(password.padRight(32, '0').substring(0, 32));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final bytes = await file.readAsBytes();
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(bytes), iv: iv);

    final decryptedFile = File('${file.path}.dec');
    await decryptedFile.writeAsBytes(decrypted);
    return decryptedFile;
  }
}
