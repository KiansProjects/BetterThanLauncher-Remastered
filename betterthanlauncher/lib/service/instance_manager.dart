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
    }

    final validDirs = <Directory>[];

    await for (final entity in _instancesRootDir.list()) {
      if (entity is Directory) {
        final jar = File(p.join(entity.path, 'client.jar'));
        final hiddenJar = File(p.join(entity.path, '.client.jar'));
        final config = File(p.join(entity.path, 'instance.conf'));

        final jarExists = await jar.exists() || await hiddenJar.exists();
        final configExists = await config.exists();

        if (jarExists && configExists) {
          validDirs.add(entity);
        } else if (jarExists || configExists) {
          await _repairInstance(entity);
          final newJar = await jar.exists() || await hiddenJar.exists();
          final newConfig = await config.exists();
          if (newJar && newConfig) validDirs.add(entity);
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

  Future<void> _hideFileWindows(File file) async {
    await Process.run('attrib', ['+h', file.path]);
  }

  Future<File> _hideFileUnix(File file) async {
    final newPath = p.join(file.parent.path, '.client.jar');
    return await file.rename(newPath);
  }

  Future<Map<String, String>> _loadConfig(Directory instance) async {
    final file = File(p.join(instance.path, 'instance.conf'));
    if (!await file.exists()) return {};
    final lines = await file.readAsLines();
    final config = <String, String>{};
    for (final line in lines) {
      if (line.contains('=')) {
        final parts = line.split('=');
        config[parts[0].trim()] = parts[1].trim();
      }
    }
    return config;
  }

  Future<void> _createDefaultConfig(Directory instance, {String? version}) async {
    final configFile = File(p.join(instance.path, 'instance.conf'));
    await configFile.writeAsString(
      [
        'version=${version ?? "unknown"}',
        'ram=2048',
        'jvmArgs=-XX:+UseG1GC '
            '-XX:+UnlockExperimentalVMOptions '
            '-Dsun.rmi.dgc.server.gcInterval=2147483646 '
            '-XX:G1NewSizePercent=20 '
            '-XX:G1ReservePercent=20 '
            '-XX:MaxGCPauseMillis=50 '
            '-XX:G1HeapRegionSize=32M',
      ].join('\n'),
    );
  }

  Future<void> _mergeClientJar(Directory instance) async {
    final versions = await _versionManager.getVersions();
    final btaVersion = versions.lastWhere((v) => v.startsWith('v'));
    final btaJarPath = await _versionManager.getVersionPath(btaVersion);
    final betaJarPath = await _versionManager.getVersionPath('b1.7.3');

    final mergedJarPath = p.join(instance.path, 'client.jar');

    await Process.run(
      'java',
      ['-cp', _scriptsDir.path, 'JarMerger', btaJarPath!, betaJarPath!, mergedJarPath],
    );

    final jar = File(mergedJarPath);
    if (Platform.isWindows) {
      await _hideFileWindows(jar);
    } else {
      await _hideFileUnix(jar);
    }
  }

  Future<void> createInstance(String name) async {
    final dir = Directory(p.join(_instancesRootDir.path, name));
    if (await dir.exists()) return;
    await dir.create(recursive: true);
    await _createDefaultConfig(dir);
    await _mergeClientJar(dir);
    instances.value = [...instances.value, dir];
  }

  Future<void> _repairInstance(Directory instance) async {
    final jar = File(p.join(instance.path, 'client.jar'));
    final hiddenJar = File(p.join(instance.path, '.client.jar'));
    final config = File(p.join(instance.path, 'instance.conf'));

    final jarExists = await jar.exists() || await hiddenJar.exists();
    final configExists = await config.exists();

    if (!configExists && jarExists) {
      final versions = await _versionManager.getVersions();
      final version = versions.isNotEmpty ? versions.last : "unknown";
      await _createDefaultConfig(instance, version: version);
    }

    if (!jarExists && configExists) {
      await _mergeClientJar(instance);
    }

    if (await jar.exists()) {
      if (Platform.isWindows) {
        await _hideFileWindows(jar);
      } else {
        await _hideFileUnix(jar);
      }
    }
  }

  Future<Process> startInstanceWithOutput(String name) async {
    final instanceDir = Directory(p.join(_instancesRootDir.path, name));
    if (!await instanceDir.exists()) throw Exception("Instance '$name' does not exist.");

    File? clientJar;
    final normal = File(p.join(instanceDir.path, 'client.jar'));
    final hidden = File(p.join(instanceDir.path, '.client.jar'));

    if (await normal.exists()) clientJar = normal;
    if (await hidden.exists()) clientJar = hidden;
    if (clientJar == null) throw Exception("client.jar missing.");

    final config = await _loadConfig(instanceDir);
    final ram = config['ram'] ?? '2048';
    final configJvmArgs = config['jvmArgs']?.split(' ') ?? [];

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
    } else {
      nativeSuffixes = ['natives-$os', 'natives-$os-x86', 'natives-$os-arm64'];
    }

    final lwjglLibs = <String>[];
    for (final module in lwjglModules) {
      final jarPath = await _libraryManager.getLibraryPath(
        groupId: 'org.lwjgl',
        artifactId: module,
        version: '3.3.3',
      );
      lwjglLibs.add(jarPath);
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

    final log4jModules = [
      'log4j-api',
      'log4j-core',
      'log4j-slf4j2-impl'
    ];

    final log4jLibs = await Future.wait(
      log4jModules.map((m) => _libraryManager.getLibraryPath(
            groupId: 'org.apache.logging.log4j',
            artifactId: m,
            version: '2.20.0',
          )),
    );

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
      '-Xmx${ram}m',
      '-Xms${ram}m',
      ...configJvmArgs,
    ];

    final gameArgs = [
      '--username', _authenticator.playerName,
      '--uuid', _authenticator.playerUuid,
      if (_authenticator.accessToken != 'no-token')
        '--session', _authenticator.accessToken,
      '--gameDir', instanceDir.path,
      '--assetsDir', p.join(instanceDir.path, 'assets'),
    ];

    final args = [
      ...jvmArgs,
      '-cp',
      classpath,
      'net.minecraft.client.Minecraft',
      ...gameArgs,
    ];

    return await Process.start(
      'java',
      args,
      workingDirectory: instanceDir.path,
      mode: ProcessStartMode.normal,
    );
  }

  String? getInstancePath(String name) {
    final instanceDir = instances.value.firstWhere(
        (d) => p.basename(d.path) == name);
    return instanceDir.path;
  }

  Future<void> deleteInstance(String name) async {
    final instanceDir =
        instances.value.firstWhere((d) => p.basename(d.path) == name);
    await instanceDir.delete(recursive: true);
    instances.value =
        instances.value.where((d) => d != instanceDir).toList();
  }
}
