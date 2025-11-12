import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class VersionManager {
  static final VersionManager _instance = VersionManager._internal();
  factory VersionManager() => _instance;
  VersionManager._internal();

  late Directory _versionsDir;

  final String prefix = '[VersionManager]';

  Future<void> init({required String versionsDirPath}) async {
    _versionsDir = Directory(versionsDirPath);

    if (!await _versionsDir.exists()) {
      print('$prefix Creating versions directory: $versionsDirPath');
      await _versionsDir.create(recursive: true);
      print('$prefix Versions directory created.');
    } else {
      print('$prefix Using existing versions directory: $versionsDirPath');
    }
  }

  Future<File> downloadJarToFolder(String url, String folderName) async {
    final targetDir = Directory(p.join(_versionsDir.path, folderName));

    if (!await targetDir.exists()) {
      print('$prefix Creating directory for version: $folderName');
      await targetDir.create(recursive: true);
    }

    final outFile = File(p.join(targetDir.path, 'client.jar'));

    if (await outFile.exists()) {
      print('$prefix Version already exists: $folderName/client.jar');
      return outFile;
    }

    print('$prefix Downloading client.jar for version: $folderName');
    print('$prefix From URL: $url');

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print('$prefix Failed to download client.jar (HTTP ${response.statusCode})');
    }

    await outFile.writeAsBytes(response.bodyBytes);
    print('$prefix Download complete: ${outFile.path}');
    return outFile;
  }

  Future<void> downloadMinecraftBeta() async {
    print('$prefix Downloading Minecraft Beta version...');
    final url = 'https://launcher.mojang.com/v1/objects/43db9b498cb67058d2e12d394e6507722e71bb45/client.jar';
    await downloadJarToFolder(url, 'b1.7.3');
  }

  Future<void> downloadBtaVersions() async {
    final releasesUrl = 'https://downloads.betterthanadventure.net/bta-client/release/';
    print('$prefix Fetching Better Than Adventure (BTA) versions...');
    final response = await http.get(Uri.parse(releasesUrl));

    if (response.statusCode != 200) {
      print('$prefix Failed to fetch BTA releases (HTTP ${response.statusCode})');
      throw Exception('Failed to fetch BTA releases.');
    }

    final body = response.body;
    final regex = RegExp(r'href="(v[^"/]+)/"');
    final matches = regex.allMatches(body);

    if (matches.isEmpty) {
      print('$prefix No BTA versions found at $releasesUrl');
      return;
    }

    print('$prefix Found ${matches.length} BTA version(s). Starting download...');

    for (final match in matches) {
      final versionFolder = match.group(1)!;
      final jarUrl = '$releasesUrl$versionFolder/client.jar';
      try {
        await downloadJarToFolder(jarUrl, versionFolder);
      } catch (e) {
        print('$prefix Failed to download BTA version $versionFolder: $e');
      }
    }

    print('$prefix Finished downloading available BTA versions.');
  }

  Future<void> downloadAllVersions() async {
    print('$prefix Starting full version download (Beta + BTA)...');
    await downloadMinecraftBeta();
    await downloadBtaVersions();
    print('$prefix All version downloads completed.');
  }

  Future<List<String>> getVersions() async {
    print('$prefix Listing available versions...');

    if (!await _versionsDir.exists()) {
      print('$prefix Versions directory not found: ${_versionsDir.path}');
      return [];
    }

    final entries = _versionsDir.listSync();
    final versions = <String>[];

    for (final entity in entries) {
      if (entity is Directory) {
        final jarFile = File(p.join(entity.path, 'client.jar'));
        if (await jarFile.exists()) {
          versions.add(p.basename(entity.path));
        }
      }
    }

    versions.sort();
    return versions;
  }

  Future<String?> getVersionPath(String versionName) async {
    final dir = Directory(p.join(_versionsDir.path, versionName));
    final jarFile = File(p.join(dir.path, 'client.jar'));

    final exists = await jarFile.exists();

    if (exists) {
      return jarFile.path;
    } else {
      print('$prefix Version not found locally: $versionName');
      return null;
    }
  }
}
