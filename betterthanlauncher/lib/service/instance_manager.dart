import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'version_manager.dart'; // dein vorheriger VersionManager

class InstanceManager {
  static final InstanceManager _instance = InstanceManager._internal();
  factory InstanceManager() => _instance;
  InstanceManager._internal();

  final ValueNotifier<List<Directory>> instances = ValueNotifier([]);
  late Directory _instancesRootDir;
  late Directory _scriptsDir;
  late VersionManager _versionManager;

  Future<void> init({
    required String instancesDirPath,
    required String scriptsDirPath,
    required String versionsDirPath,
  }) async {
    _instancesRootDir = Directory(instancesDirPath);
    _scriptsDir = Directory(scriptsDirPath);

    _versionManager = VersionManager();
    await _versionManager.init(versionsDirPath: versionsDirPath);

    if (!await _instancesRootDir.exists()) {
      await _instancesRootDir.create(recursive: true);
    }

    instances.value =
        _instancesRootDir.listSync().whereType<Directory>().toList();

    if (instances.value.isEmpty) {
      await createInstance("example_instance");
    }
  }

  bool instanceExists(String name) =>
      instances.value.any((d) => p.basename(d.path) == name);

  /// 🔹 Erstellt eine neue Instanz und merged automatisch BTA + Beta JARs
  Future<void> createInstance(String name) async {
    final newInstanceDir = Directory(p.join(_instancesRootDir.path, name));

    if (await newInstanceDir.exists()) {
      print("Instance $name already exists.");
      return;
    }

    await newInstanceDir.create(recursive: true);
    print("🔸 Creating instance $name...");

    // Stelle sicher, dass beide Versionen vorhanden sind
    await _versionManager.downloadMinecraftBeta();
    await _versionManager.downloadBtaVersions();

    // Hole die Pfade der JARs
    final betaJarPath = await _versionManager.getVersionPath('b1.7.3');
    if (betaJarPath == null) {
      throw Exception('Minecraft Beta JAR not found.');
    }

    // Suche die neueste BTA-Version
    final versions = await _versionManager.getVersions();
    final btaVersion = versions.lastWhere(
      (v) => v.startsWith('v'),
      orElse: () => throw Exception('No BTA versions found.'),
    );
    final btaJarPath = await _versionManager.getVersionPath(btaVersion);
    if (btaJarPath == null) {
      throw Exception('BTA JAR not found.');
    }

    // Ziel: merged client.jar in der neuen Instanz
    final mergedJarPath = p.join(newInstanceDir.path, 'client.jar');
    print('🧩 Merging $betaJarPath + $btaJarPath → $mergedJarPath');

    // ✅ KORREKTER PROCESS-AUFRUF
    final result = await Process.run(
      'java',
      ['-cp', _scriptsDir.path, 'JarMerger', betaJarPath, btaJarPath, mergedJarPath],
    );

    if (result.exitCode != 0) {
      print('Jar merge failed: ${result.stderr}');
      throw Exception('Failed to merge jars.');
    }

    print('Merged JAR created at $mergedJarPath');

    // Füge Instanz hinzu
    instances.value = [...instances.value, newInstanceDir];
  }
}

