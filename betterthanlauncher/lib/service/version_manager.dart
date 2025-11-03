import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class VersionManager {
  static final VersionManager _instance = VersionManager._internal();
  factory VersionManager() => _instance;
  VersionManager._internal();

  late Directory _versionsDir;

  Future<void> init({required String versionsDirPath}) async {
    _versionsDir = Directory(versionsDirPath);
    if (!await _versionsDir.exists()) {
      await _versionsDir.create(recursive: true);
    }
  }

  Future<File> downloadJarToFolder(String url, String folderName) async {
    final targetDir = Directory(p.join(_versionsDir.path, folderName));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final outFile = File(p.join(targetDir.path, 'client.jar'));

    if (await outFile.exists()) {
      print('client.jar in $folderName already exists, skipping download.');
      return outFile;
    }

    print('Downloading client.jar for $folderName...');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download JAR: $url');
    }

    await outFile.writeAsBytes(response.bodyBytes);
    print('Downloaded client.jar to ${outFile.path}');
    return outFile;
  }

  Future<void> downloadMinecraftBeta() async {
    final url =
        'https://launcher.mojang.com/v1/objects/43db9b498cb67058d2e12d394e6507722e71bb45/client.jar';
    await downloadJarToFolder(url, 'b1.7.3');
  }

  Future<void> downloadBtaVersions() async {
    final releasesUrl = 'https://downloads.betterthanadventure.net/bta-client/release/';
    print('Fetching BTA versions...');
    final response = await http.get(Uri.parse(releasesUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch BTA releases.');
    }

    final body = response.body;

    final regex = RegExp(r'href="(v[^"/]+)/"');
    final matches = regex.allMatches(body);

    for (final match in matches) {
      final versionFolder = match.group(1)!;
      final jarUrl = '$releasesUrl$versionFolder/client.jar';
      try {
        await downloadJarToFolder(jarUrl, versionFolder);
      } catch (e) {
        print('Failed to download BTA version $versionFolder: $e');
      }
    }
  }

  Future<void> downloadAllVersions() async {
    await downloadMinecraftBeta();
    await downloadBtaVersions();
  }
}
