import 'dart:io';
import 'package:betterthanlauncher/service/authenticator.dart';
import 'package:betterthanlauncher/service/discord_presence_manager.dart';
import 'package:flutter/widgets.dart';
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
  late DiscordPresenceManager _discordPresenceManager;
  late LibraryManager _libraryManager;
  late VersionManager _versionManager;

  final String prefix = '[InstanceManager]';

  Future<void> init({
    required String instancesDirPath,
    required String scriptsDirPath,
    required Authenticator authenticator,
    required DiscordPresenceManager discordPresenceManager,
    required LibraryManager libraryManager,
    required VersionManager versionManager,
  }) async {
    print('$prefix Initializing InstanceManager...');

    _instancesRootDir = Directory(instancesDirPath);
    _scriptsDir = Directory(scriptsDirPath);
    _authenticator = authenticator;
    _discordPresenceManager = discordPresenceManager;
    _libraryManager = libraryManager;
    _versionManager = versionManager;

    if (!await _instancesRootDir.exists()) {
      await _instancesRootDir.create(recursive: true);
    }

    final validDirs = <Directory>[];

    await for (final entity in _instancesRootDir.list()) {
      if (entity is Directory) {
        final jar = File(p.join(entity.path, '.client.jar'));
        final config = File(p.join(entity.path, 'instance.conf'));

        final jarExists = await jar.exists();
        final configExists = await config.exists();

        if (jarExists && configExists) {
          validDirs.add(entity);
        } else if (jarExists || configExists) {
          await _repairInstance(entity);

          final newJar = await jar.exists();
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

  Future<Map<String, String>> _loadConfig(Directory instance) async {
    final file = File(p.join(instance.path, 'instance.conf'));
    if (!await file.exists()) return {};
    final lines = await file.readAsLines();
    final config = <String, String>{};
    
    for (final line in lines) {
      final index = line.indexOf('=');
      if (index == -1) continue;
      final key = line.substring(0, index).trim();
      final value = line.substring(index + 1).trim();
      config[key] = value;
    }
    
    return config;
  }

  Future<void> _createDefaultConfig(Directory instance, {required String version}) async {
    final configFile = File(p.join(instance.path, 'instance.conf'));
    await configFile.writeAsString(
      [
        'version=$version',
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

    final mergedJarPath = p.join(instance.path, '.client.jar');

    await Process.run(
      'java',
      ['-cp', _scriptsDir.path, 'JarMerger', btaJarPath!, betaJarPath!, mergedJarPath],
    );

    final jar = File(mergedJarPath);
    if (Platform.isWindows) {
      await _hideFileWindows(jar);
    }
  }

  Future<void> createInstance(String name) async {
    final dir = Directory(p.join(_instancesRootDir.path, name));
    if (await dir.exists()) return;

    await dir.create(recursive: true);

    final versions = await _versionManager.getVersions();
    final version = versions.last;

    await _createDefaultConfig(dir, version: version);
    await _mergeClientJar(dir);

    instances.value = [...instances.value, dir];
  }

  Future<void> _repairInstance(Directory instance) async {
    final hiddenJar = File(p.join(instance.path, '.client.jar'));
    final oldJar = File(p.join(instance.path, 'client.jar'));
    final config = File(p.join(instance.path, 'instance.conf'));

    final jarExists = await hiddenJar.exists() || await oldJar.exists();
    final configExists = await config.exists();

    if (!configExists && jarExists) {
      final versions = await _versionManager.getVersions();
      final version = versions.last;
      await _createDefaultConfig(instance, version: version);
    }

    if (!jarExists && configExists) {
      await _mergeClientJar(instance);
    }

    if (await oldJar.exists() && !(await hiddenJar.exists())) {
      await oldJar.rename(hiddenJar.path);
      if (Platform.isWindows) {
        await _hideFileWindows(hiddenJar);
      }
    }
  }

  Future<Process> startInstanceWithOutput(String name) async {
    final instanceDir = Directory(p.join(_instancesRootDir.path, name));
    if (!await instanceDir.exists()) throw Exception("Instance '$name' does not exist.");

    final clientJar = File(p.join(instanceDir.path, '.client.jar'));
    if (!await clientJar.exists()) throw Exception(".client.jar missing.");

    _discordPresenceManager.setPresence(
      details: 'Starting $name',
      largeImageKey: 'app_icon',
      smallImageKey: 'bta',
    );

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
      log4jModules.map((m) =>
          _libraryManager.getLibraryPath(
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

    final process = await Process.start(
      'java',
      args,
      workingDirectory: instanceDir.path,
      mode: ProcessStartMode.normal,
    );

    _discordPresenceManager.setPresence(
      details: 'Playing $name',
      largeImageKey: 'app_icon',
      smallImageKey: 'bta',
    );

    process.exitCode.then((_) {
      _discordPresenceManager.setPresence(
        details: 'Just chilling...',
      );
    });

    return process;
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

  Future<Map<String, String>> getConfig(String name) async {
    final instanceDir = instances.value.firstWhere(
        (d) => p.basename(d.path) == name,
        orElse: () => throw Exception("Instance '$name' does not exist."));
    return await _loadConfig(instanceDir);
  }

  Future<void> setConfigValue(String name, String key, String value) async {
    final config = await getConfig(name);
    config[key] = value;
    await saveConfig(name, config);
  }

  Future<void> saveConfig(String name, Map<String, String> config) async {
    final instanceDir = instances.value.firstWhere(
        (d) => p.basename(d.path) == name,
        orElse: () => throw Exception("Instance '$name' does not exist."));
    final configFile = File(p.join(instanceDir.path, 'instance.conf'));

    if (!config.containsKey('version') || config['version']!.isEmpty) {
      throw Exception("Config muss eine gültige Version enthalten.");
    }

    final lines = config.entries.map((e) => '${e.key}=${e.value}').toList();
    await configFile.writeAsString(lines.join('\n'));
  }

  ImageProvider getIcon(String name) {
    try {
      final instanceDir = instances.value.firstWhere(
        (d) => p.basename(d.path) == name,
      );

      final iconFile = File(p.join(instanceDir.path, 'icon.png'));
      if (iconFile.existsSync()) {
        return FileImage(iconFile);
      }
    } catch (_) { }

    return const AssetImage('assets/icons/instance_icon.png');
  }
}
