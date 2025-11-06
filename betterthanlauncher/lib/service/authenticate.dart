import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as p;

class Authenticator {
  late Directory _scriptsDir;
  late Directory _profileDir;
  final String _jsonFileName = 'mc_profile.enc';
  final List<String> _libraryPaths = [];

  Future<void> init({
    required String scriptsDirPath,
    required String profileDirPath,
  }) async {
    _scriptsDir = Directory(scriptsDirPath);
    if (!await _scriptsDir.exists()) await _scriptsDir.create(recursive: true);

    _profileDir = Directory(profileDirPath);
    if (!await _profileDir.exists()) await _profileDir.create(recursive: true);
  }

  void addLibraryPath(String jarPath) => _libraryPaths.add(jarPath);
  void addLibraryPaths(List<String> jarPaths) => _libraryPaths.addAll(jarPaths);

  String _generateDeviceKey() {
    String deviceIdentifier = '';
    try {
      if (Platform.isWindows) {
        deviceIdentifier = Platform.environment['COMPUTERNAME'] ?? 'windows_default';
      } else if (Platform.isLinux || Platform.isMacOS) {
        deviceIdentifier = Platform.environment['HOSTNAME'] ?? 'unix_default';
      } else {
        deviceIdentifier = 'default_device_key';
      }
      deviceIdentifier += Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    } catch (_) {
      deviceIdentifier = 'fallback_device_key_1234567890';
    }

    if (deviceIdentifier.length >= 32) {
      return deviceIdentifier.substring(deviceIdentifier.length - 32);
    } else {
      return deviceIdentifier.padLeft(32, '0');
    }
  }

  Future<String?> runJavaAuthenticator() async {
    try {
      final classpath = [_scriptsDir.path, ..._libraryPaths].join(Platform.isWindows ? ';' : ':');
      final process = await Process.start('java', ['-cp', classpath, 'Authenticate'], workingDirectory: _scriptsDir.path);

      final output = await process.stdout.transform(utf8.decoder).join();
      final errorOutput = await process.stderr.transform(utf8.decoder).join();
      await process.exitCode;

      final lastLine = output.trim().split('\n').lastWhere((line) => line.isNotEmpty, orElse: () => 'ERROR');
      if (lastLine == 'ERROR') {
        print('Authentication failed: $errorOutput');
        return null;
      }

      await saveJson(lastLine);
      return lastLine;
    } catch (e) {
      print('Failed to run Java authenticator: $e');
      return null;
    }
  }

  Future<bool> runJavaWithJson(String json) async {
    try {
      final classpath = [_scriptsDir.path, ..._libraryPaths].join(Platform.isWindows ? ';' : ':');
      final process = await Process.start(
        'java', 
        ['-cp', classpath, 'Authenticate', json], 
        workingDirectory: _scriptsDir.path
      );

      final output = await process.stdout.transform(utf8.decoder).join();
      final errorOutput = await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      if (exitCode != 0 || output.contains('invalid')) {
        print('Profile validation failed: $errorOutput');
        return false;
      }

      print('Profile validation successful.');
      return true;
    } catch (e) {
      print('Failed to run Java authenticator with JSON: $e');
      return false;
    }
  }

  Future<void> saveJson(String json) async {
    final key = Key.fromUtf8(_generateDeviceKey());
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));

    final encrypted = encrypter.encrypt(json, iv: iv);
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);

    final file = File(p.join(_profileDir.path, _jsonFileName));
    await file.writeAsString(base64Encode(combined));
  }

  Future<String?> loadJson() async {
    try {
      final file = File(p.join(_profileDir.path, _jsonFileName));
      if (!await file.exists()) return null;

      final combined = base64Decode(await file.readAsString());
      final iv = IV(combined.sublist(0, 16));
      final ciphertext = combined.sublist(16);

      final key = Key.fromUtf8(_generateDeviceKey());
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
      return encrypter.decrypt(Encrypted(Uint8List.fromList(ciphertext)), iv: iv);
    } catch (e) {
      print('Failed to load JSON: $e');
      return null;
    }
  }

  Future<void> authenticateFlow() async {
    String? profileJson = await loadJson();

    if (profileJson != null) {
      print('Authenticating with existing profile JSON...');
      bool success = await runJavaWithJson(profileJson);
      if (!success) {
        print('Existing JSON invalid. Obtaining new profile JSON...');
        profileJson = await runJavaAuthenticator();
        if (profileJson != null) {
          await runJavaWithJson(profileJson);
        } else {
          print('Failed to obtain new profile JSON.');
        }
      }
    } else {
      print('No existing profile JSON. Running Java authenticator...');
      profileJson = await runJavaAuthenticator();
      if (profileJson != null) {
        await runJavaWithJson(profileJson);
      } else {
        print('Failed to obtain profile JSON.');
      }
    }
  }
}
