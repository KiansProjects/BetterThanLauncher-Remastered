import 'dart:io';
import 'package:betterthanlauncher/service/authenticator.dart';
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
  late Authenticator _authenticator;
  late LibraryManager _libraryManager;
  late VersionManager _versionManager;

  final String prefix = '[InstanceManager]';

  Future<void> init({
    required String instancesDirPath,
    required String scriptsDirPath,
    required Authenticator authenticator,
    required LibraryManager libraryManager,
    required VersionManager versionManager,
  }) async {
    _instancesRootDir = Directory(instancesDirPath);
    _scriptsDir = Directory(scriptsDirPath);

    _authenticator = authenticator;
    _libraryManager = libraryManager;
    _versionManager = versionManager;

    if (!await _instancesRootDir.exists()) {
      await _instancesRootDir.create(recursive: true);
      print('$prefix Instances root directory created at ${_instancesRootDir.path}');
    }

    final validDirs = <Directory>[];

    await for (final entity in _instancesRootDir.list()) {
      if (entity is Directory) {
        final clientJar = File(p.join(entity.path, 'client.jar'));
        if (await clientJar.exists()) {
          validDirs.add(entity);
        }
      }
    }

    instances.value = validDirs;

    if (instances.value.isEmpty) {
      await createInstance("example_instance");
    }
  }

  bool instanceExists(String name) =>
      instances.value.any((d) => p.basename(d.path) == name);

  Future<void> createInstance(String name) async {
    final newInstanceDir = Directory(p.join(_instancesRootDir.path, name));

    if (await newInstanceDir.exists()) {
      print('$prefix Instance $name already exists.');
      return;
    }

    print('$prefix Creating instance $name...');
    await newInstanceDir.create(recursive: true);

    final versions = await _versionManager.getVersions();
    final btaVersion = versions.lastWhere(
      (v) => v.startsWith('v'),
      orElse: () => throw Exception('No BTA versions found.'),
    );
    final btaJarPath = await _versionManager.getVersionPath(btaVersion);
    if (btaJarPath == null) throw Exception('BTA JAR not found.');

    final betaJarPath = await _versionManager.getVersionPath('b1.7.3');
    if (betaJarPath == null) throw Exception('Minecraft Beta JAR not found.');

    final mergedJarPath = p.join(newInstanceDir.path, 'client.jar');
    print('$prefix Merging JAR into $mergedJarPath');

    final result = await Process.run(
      'java',
      ['-cp', _scriptsDir.path, 'JarMerger', btaJarPath, betaJarPath, mergedJarPath],
    );

    if (result.exitCode != 0) {
      print('$prefix Jar merge failed:\n${result.stderr}');
    }

    print('$prefix Merged JAR created at $mergedJarPath');
    instances.value = [...instances.value, newInstanceDir];
  }

  Future<Process> startInstanceWithOutput(String name) async {
    final instanceDir = Directory(p.join(_instancesRootDir.path, name));
    if (!await instanceDir.exists()) {
      print("$prefix Instance '$name' does not exist.");
    }

    final clientJar = File(p.join(instanceDir.path, 'client.jar'));
    if (!await clientJar.exists()) {
      print("$prefix client.jar not found in instance '$name'.");
    }

    final lwjglModules = [
      'lwjgl',
      'lwjgl-freetype',
      'lwjgl-glfw',
      'lwjgl-jemalloc',
      'lwjgl-openal',
      'lwjgl-opengl',
      'lwjgl-stb',
    ];

    final os = Platform.isWindows ? 'windows' : Platform.isMacOS ? 'macos' : 'linux';

    List<String> nativeSuffixes;
    if (Platform.isLinux) {
      nativeSuffixes = ['natives-$os'];
    } else if (Platform.isMacOS) {
      nativeSuffixes = ['natives-$os', 'natives-$os-arm64'];
    } else if (Platform.isWindows) {
      nativeSuffixes = ['natives-$os', 'natives-$os-x86', 'natives-$os-arm64'];
    } else {
      throw UnsupportedError('Unsupported OS: $os');
    }

    final lwjglLibs = <String>[];
    for (final module in lwjglModules) {
      final jar = await _libraryManager.getLibraryPath(
        groupId: 'org.lwjgl',
        artifactId: module,
        version: '3.3.3',
      );
      lwjglLibs.add(jar);
      for (final suffix in nativeSuffixes) {
        final nativeJar = await _libraryManager.getLibraryPath(
          groupId: 'org.lwjgl',
          artifactId: module,
          suffix: suffix,
          version: '3.3.3',
        );
        lwjglLibs.add(nativeJar);
      }
    }

    final log4jModules = ['log4j-api', 'log4j-core', 'log4j-slf4j2-impl'];
    final log4jLibs = await Future.wait(log4jModules.map((m) => _libraryManager.getLibraryPath(
          groupId: 'org.apache.logging.log4j',
          artifactId: m,
          version: '2.20.0',
    )));

    final slf4jApi = await _libraryManager.getLibraryPath(
      groupId: 'org.slf4j',
      artifactId: 'slf4j-api',
      version: '2.0.7',
    );

    final separator = Platform.isWindows ? ';' : ':';
    final classpath = [
      clientJar.path,
      ...lwjglLibs,
      ...log4jLibs.whereType<String>(),
      slf4jApi,
    ].join(separator);

    final jvmArgs = [
      '-XX:+UseG1GC',
      '-Dsun.rmi.dgc.server.gcInterval=2147483646',
      '-XX:+UnlockExperimentalVMOptions',
      '-XX:G1NewSizePercent=20',
      '-XX:G1ReservePercent=20',
      '-XX:MaxGCPauseMillis=50',
      '-XX:G1HeapRegionSize=32M',
    ];

    final gameArgs = [
      '--username', _authenticator.playerName,
      if (_authenticator.accessToken != 'no-token') '--session', _authenticator.accessToken,
      '--gameDir', instanceDir.path,
      '--assetsDir', p.join(instanceDir.path, 'assets'),
      '--title', 'custom',
    ];

    final javaArgs = [
      ...jvmArgs,
      '-cp',
      classpath,
      'net.minecraft.client.Minecraft',
      ...gameArgs,
    ];

    print('$prefix Starting instance $name...');

    final process = await Process.start(
      'java',
      javaArgs,
      workingDirectory: instanceDir.path,
      mode: ProcessStartMode.normal,
    );

    return process;
  }

  String? getInstancePath(String name) {
    final instanceDir = instances.value.firstWhere(
      (d) => p.basename(d.path) == name
    );
    return instanceDir.path;
  }

  /// Deletes an instance by name and updates the instances list
  Future<void> deleteInstance(String name) async {
    final instanceDir = instances.value.firstWhere(
      (d) => p.basename(d.path) == name
    );

    try {
      await instanceDir.delete(recursive: true);
      instances.value = instances.value.where((d) => d != instanceDir).toList();
      print('$prefix Instance $name deleted successfully.');
    } catch (e) {
      print('$prefix Failed to delete instance $name: $e');
    }
  }
}
