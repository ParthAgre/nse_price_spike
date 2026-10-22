import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Keeps the latest downloaded bhavcopy zip, so the close of any instrument
/// (not only held ones) can be shown when adding a holding.
abstract interface class FileCache {
  Future<void> write(Uint8List bytes);
  Future<Uint8List?> read();
  Future<void> clear();
}

class DirectoryFileCache implements FileCache {
  static const fileName = 'latest_bhavcopy.zip';

  Future<File> _file() async {
    final dir = await getApplicationCacheDirectory();
    return File('${dir.path}${Platform.pathSeparator}$fileName');
  }

  @override
  Future<void> write(Uint8List bytes) async {
    final file = await _file();
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List?> read() async {
    final file = await _file();
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }
}

class MemoryFileCache implements FileCache {
  Uint8List? _bytes;

  @override
  Future<void> write(Uint8List bytes) async => _bytes = bytes;

  @override
  Future<Uint8List?> read() async => _bytes;

  @override
  Future<void> clear() async => _bytes = null;
}
