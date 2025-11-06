import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'library_manager.dart';
import 'version_manager.dart';

class InstanceManager {
  static final InstanceManager _instance = InstanceManager._internal();
  factory InstanceManager() => _instance;
  InstanceManager._internal();

  final ValueNotifier<List<Directory>> instances = ValueNotifier([]);
  late Directory _instancesRootDir;
  late Directory _scriptsDir;
  late LibraryManager _libraryManager;
  late VersionManager _versionManager;

  Future<void> init({
    required String instancesDirPath,
    required String scriptsDirPath,
    required LibraryManager libraryManager,
    required VersionManager versionManager,
  }) async {
    _instancesRootDir = Directory(instancesDirPath);
    _scriptsDir = Directory(scriptsDirPath);

    _libraryManager = libraryManager;
    _versionManager = versionManager;

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

  Future<void> createInstance(String name) async {
    final newInstanceDir = Directory(p.join(_instancesRootDir.path, name));

    if (await newInstanceDir.exists()) {
      print("Instance $name already exists.");
      return;
    }

    await newInstanceDir.create(recursive: true);
    print("🔸 Creating instance $name...");

    await _versionManager.downloadMinecraftBeta();
    await _versionManager.downloadBtaVersions();

    final betaJarPath = await _versionManager.getVersionPath('b1.7.3');
    if (betaJarPath == null) {
      throw Exception('Minecraft Beta JAR not found.');
    }

    final versions = await _versionManager.getVersions();
    final btaVersion = versions.lastWhere(
      (v) => v.startsWith('v'),
      orElse: () => throw Exception('No BTA versions found.'),
    );
    final btaJarPath = await _versionManager.getVersionPath(btaVersion);
    if (btaJarPath == null) {
      throw Exception('BTA JAR not found.');
    }

    final mergedJarPath = p.join(newInstanceDir.path, 'client.jar');
    print('Merging $betaJarPath + $btaJarPath → $mergedJarPath');

    final result = await Process.run(
      'java',
      ['-cp', _scriptsDir.path, 'JarMerger', betaJarPath, btaJarPath, mergedJarPath],
    );

    if (result.exitCode != 0) {
      print('Jar merge failed: ${result.stderr}');
      throw Exception('Failed to merge jars.');
    }

    print('Merged JAR created at $mergedJarPath');

    instances.value = [...instances.value, newInstanceDir];
  }

  Future<Process> startInstanceWithOutput(String name) async {
    final instanceDir = Directory(p.join(_instancesRootDir.path, name));
    if (!await instanceDir.exists()) {
      throw Exception("Instance '$name' does not exist.");
    }

    final clientJar = File(p.join(instanceDir.path, 'client.jar'));
    if (!await clientJar.exists()) {
      throw Exception("client.jar not found in instance '$name'.");
    }

    final minecraftAuthLib = await _libraryManager.getLibraryPath(
      groupId: 'net.raphimc',
      artifactId: 'MinecraftAuth',
      version: '4.1.2',
    );

    final process = await Process.start(
      'java',
      [
        '-cp',
        '${clientJar.path}${Platform.isWindows ? ";" : ":"}$minecraftAuthLib',
        'net.minecraft.client.Minecraft',
        '--username', 'Player123',
      ],
      workingDirectory: instanceDir.path,
      mode: ProcessStartMode.normal,
    );

    return process;
  }
}
