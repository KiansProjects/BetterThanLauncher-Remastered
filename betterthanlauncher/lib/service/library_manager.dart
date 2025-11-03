import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class LibraryManager {
  static final LibraryManager _instance = LibraryManager._internal();
  factory LibraryManager() => _instance;
  LibraryManager._internal();

  late Directory _librariesDir;

  Future<void> init({required String libDirPath}) async {
    _librariesDir = Directory(libDirPath);

    if (!await _librariesDir.exists()) {
      await _librariesDir.create(recursive: true);
    }
  }

  Future<File> downloadLibrary({
    required String groupId,
    required String artifactId,
    required String version,
    String baseUrl = 'https://repo1.maven.org/maven2',
  }) async {
    final groupPath = groupId.replaceAll('.', '/');
    final fileName = '$artifactId-$version.jar';

    final url = '$baseUrl/$groupPath/$artifactId/$version/$fileName';

    final libDir = Directory(p.join(_librariesDir.path, groupPath, artifactId, version));
    if (!await libDir.exists()) {
      await libDir.create(recursive: true);
    }

    final outFile = File(p.join(libDir.path, fileName));

    if (await outFile.exists()) {
      return outFile;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download library: $url');
    }

    await outFile.writeAsBytes(response.bodyBytes);
    return outFile;
  }

  Future<bool> hasLibrary({
    required String groupId,
    required String artifactId,
    required String version,
  }) async {
    final groupPath = groupId.replaceAll('.', '/');
    final fileName = '$artifactId-$version.jar';
    final file = File(p.join(_librariesDir.path, groupPath, artifactId, version, fileName));
    return file.exists();
  }

  Future<File> getLibrary({
    required String groupId,
    required String artifactId,
    required String version,
  }) async {
    final groupPath = groupId.replaceAll('.', '/');
    final fileName = '$artifactId-$version.jar';
    final file = File(p.join(_librariesDir.path, groupPath, artifactId, version, fileName));

    if (!await file.exists()) {
      throw Exception('Library not found locally.');
    }
    return file;
  }

  Future<String> getLibraryPath({
    required String groupId,
    required String artifactId,
    required String version,
  }) async {
    final groupPath = groupId.replaceAll('.', '/');
    final fileName = '$artifactId-$version.jar';
    final file = File(p.join(_librariesDir.path, groupPath, artifactId, version, fileName));

    if (!await file.exists()) {
      throw Exception('Library not found locally. You may need to download it first.');
    }

    return file.path;
  }
}
