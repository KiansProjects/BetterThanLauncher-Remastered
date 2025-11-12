import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class LibraryManager {
  static final LibraryManager _instance = LibraryManager._internal();
  factory LibraryManager() => _instance;
  LibraryManager._internal();

  late Directory _librariesDir;

  final String prefix = '[LibraryManager]';

  Future<void> init({required String libDirPath}) async {
    _librariesDir = Directory(libDirPath);

    if (!await _librariesDir.exists()) {
      print('$prefix Creating library directory: $libDirPath');
      await _librariesDir.create(recursive: true);
      print('$prefix Library directory created.');
    } else {
      print('$prefix Using existing library directory: $libDirPath');
    }
  }

  Future<File> downloadLibrary({
    required String groupId,
    required String artifactId,
    required String version,
    String? suffix,
    String baseUrl = 'https://repo1.maven.org/maven2',
  }) async {
    final groupPath = groupId.replaceAll('.', '/');
    final fileName = suffix != null
        ? '$artifactId-$version-$suffix.jar'
        : '$artifactId-$version.jar';
    final url = '$baseUrl/$groupPath/$artifactId/$version/$fileName';

    final libDir = Directory(p.join(_librariesDir.path, groupPath, artifactId, version));
    if (!await libDir.exists()) {
      print('$prefix Creating directory for $artifactId:$version');
      await libDir.create(recursive: true);
    }

    final outFile = File(p.join(libDir.path, fileName));

    if (await outFile.exists()) {
      print('$prefix Library already exists: $fileName');
      return outFile;
    }

    print('$prefix Downloading library: $artifactId:$version');
    print('$prefix From URL: $url');

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print('$prefix Failed to download library (HTTP ${response.statusCode})');
      throw Exception('$prefix Failed to download library: $url');
    }

    await outFile.writeAsBytes(response.bodyBytes);
    print('$prefix Download complete: ${outFile.path}');

    return outFile;
  }

  Future<bool> hasLibrary({
    required String groupId,
    required String artifactId,
    required String version,
    String? suffix,
  }) async {
    final groupPath = groupId.replaceAll('.', '/');
    final fileName = suffix != null
        ? '$artifactId-$version-$suffix.jar'
        : '$artifactId-$version.jar';
    final file = File(p.join(_librariesDir.path, groupPath, artifactId, version, fileName));

    final exists = await file.exists();
    print('$prefix Checking if library exists: $fileName → ${exists ? "YES" : "NO"}');
    return exists;
  }

  Future<File> getLibrary({
    required String groupId,
    required String artifactId,
    required String version,
    String? suffix,
  }) async {
    final groupPath = groupId.replaceAll('.', '/');
    final fileName = suffix != null
        ? '$artifactId-$version-$suffix.jar'
        : '$artifactId-$version.jar';
    final file = File(p.join(_librariesDir.path, groupPath, artifactId, version, fileName));

    if (!await file.exists()) {
      print('$prefix Library not found locally: $fileName');
    }

    return file;
  }

  Future<String> getLibraryPath({
    required String groupId,
    required String artifactId,
    required String version,
    String? suffix,
  }) async {
    final groupPath = groupId.replaceAll('.', '/');
    final fileName = suffix != null
        ? '$artifactId-$version-$suffix.jar'
        : '$artifactId-$version.jar';
    final file = File(p.join(_librariesDir.path, groupPath, artifactId, version, fileName));

    if (!await file.exists()) {
      print('$prefix Library not found locally: $fileName');
    }
    return file.path;
  }
}
