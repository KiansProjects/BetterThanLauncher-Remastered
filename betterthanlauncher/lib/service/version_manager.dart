import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class VersionManager {
  static final VersionManager _instance = VersionManager._internal();
  factory VersionManager() => _instance;
  VersionManager._internal();

  late Directory _versionsDir;

  final String prefix = '[VersionManager]';
  
  final betaUrl = 'https://launcher.mojang.com/v1/objects/43db9b498cb67058d2e12d394e6507722e71bb45/client.jar';
  final btaUrl = 'https://downloads.betterthanadventure.net/bta-client/release/';

  Future<void> init({required String versionsDirPath}) async {
    print('$prefix Initializing VersionManager...');

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

  Future<void> setUpMinecraftBeta() async {
    print('$prefix Downloading Minecraft Beta version...');
    await downloadJarToFolder(betaUrl, 'b1.7.3');
  }

  Future<void> setUpBtaVersions() async {
    print('$prefix Fetching Better Than Adventure (BTA) versions...');
    final response = await http.get(Uri.parse(btaUrl));

    if (response.statusCode != 200) {
      print('$prefix Failed to fetch BTA releases (HTTP ${response.statusCode})');
      throw Exception('Failed to fetch BTA releases.');
    }

    final body = response.body;
    final regex = RegExp(r'href="(v[^"/]+)/"');
    final matches = regex.allMatches(body);

    if (matches.isEmpty) {
      print('$prefix No BTA versions found at $btaUrl');
      return;
    }

    print('$prefix Found ${matches.length} BTA version(s). Starting download...');

    for (final match in matches) {
      final versionFolder = match.group(1)!;
      final targetDir = Directory(p.join(_versionsDir.path, versionFolder));
        if (!await targetDir.exists()) {
        print('$prefix Creating directory for version: $versionFolder');
        await targetDir.create(recursive: true);
      }
    }

    print('$prefix Finished downloading available BTA versions.');
  }

  Future<List<String>> getVersions() async {
    if (!await _versionsDir.exists()) {
      print('$prefix Versions directory not found: ${_versionsDir.path}');
      return [];
    }

    final entries = _versionsDir.listSync();
    final versions = <String>[];

    for (final entity in entries) {
      if (entity is Directory) {
        versions.add(p.basename(entity.path));
      }
    }

    versions.sort();
    return versions;
  }

  Future<String?> getVersion(String versionName) async {
    final dir = Directory(p.join(_versionsDir.path, versionName));
    final jarFile = File(p.join(dir.path, 'client.jar'));

    if (await jarFile.exists()) {
      return jarFile.path;
    } else {
      print('$prefix Version not found locally: $versionName');
      
      try {
        String url;
        if (versionName == 'b1.7.3') {
          url = betaUrl;
        } else if (versionName.startsWith('v')) {
          url = '$btaUrl$versionName/client.jar';
        } else {
          print('$prefix Unknown version: $versionName');
          return null;
        }

        final downloadedFile = await downloadJarToFolder(url, versionName);
        return downloadedFile.path;
      } catch (e) {
        print('$prefix Failed to download version $versionName: $e');
        return null;
      }
    }
  }
}
