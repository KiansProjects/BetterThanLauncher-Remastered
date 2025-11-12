import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'themes/theme_manager.dart';
import 'screens/build_screen.dart';
import 'screens/home_screen.dart';
import 'service/authenticator.dart';
import 'service/instance_manager.dart';
import 'service/library_manager.dart';
import 'service/version_manager.dart';
import 'service/java_file_compiler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final lastLine = ValueNotifier<String>('');

  runZonedGuarded(() {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(lastLine: lastLine),
    ));
  }, (e, s) => print('Error: $e'), zoneSpecification: ZoneSpecification(
    print: (self, parent, zone, line) {
      lastLine.value = line;
      parent.print(zone, line);
    },
  ));

  final bytes = await rootBundle.load('assets/icons/app_icon.png');
  final tempDir = await getTemporaryDirectory();
  final tempIconPath = p.join(tempDir.path, 'app_icon.png');
  final file = File(tempIconPath);
  await file.writeAsBytes(bytes.buffer.asUint8List());

  await windowManager.setMinimumSize(const Size(1024, 640));
  await windowManager.setSize(const Size(1280, 720));
  await windowManager.center();
  await windowManager.setTitle('BetterThanLauncher');
  await windowManager.setIcon(tempIconPath);
  await windowManager.show();
}

class SplashScreen extends StatefulWidget {
  final ValueNotifier<String> lastLine;
  const SplashScreen({super.key, required this.lastLine});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String prefix = '[SplashScreen]';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSetup());
  }

  Future<void> _runSetup() async {
    try {
      print('$prefix Setting up app folders...');
      final dirs = await setupAppFolders();
      print('$prefix Folders ready.');

      final launcherDir = dirs[0];
      final instancesDir = dirs[1];
      final librariesDir = dirs[2];
      final versionsDir = dirs[3];
      final scriptsDir = dirs[4];

      print('$prefix Initializing LibraryManager...');
      final libManager = LibraryManager();
      await libManager.init(libDirPath: librariesDir.path);

      await libManager.downloadLibrary(
        groupId: 'net.raphimc',
        artifactId: 'MinecraftAuth',
        version: '4.1.2',
      );
      await libManager.downloadLibrary(
        groupId: 'net.lenni0451.commons',
        artifactId: 'httpclient',
        version: '1.8.0',
      );
      await libManager.downloadLibrary(
        groupId: 'com.google.code.gson',
        artifactId: 'gson',
        version: '2.13.2',
      );

      await libManager.downloadLibrary(
        groupId: 'org.slf4j',
        artifactId: 'slf4j-api',
        version: '2.0.17',
      );

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

    final lwjglModules = [
      'lwjgl',
      'lwjgl-freetype',
      'lwjgl-glfw',
      'lwjgl-jemalloc',
      'lwjgl-openal',
      'lwjgl-opengl',
      'lwjgl-stb',
    ];

    for (final module in lwjglModules) {
      await libManager.downloadLibrary(
        groupId: 'org.lwjgl',
        artifactId: module,
        version: '3.3.3',
      );

      for (final suffix in nativeSuffixes) {
        await libManager.downloadLibrary(
          groupId: 'org.lwjgl',
          artifactId: module,
          suffix: suffix,
          version: '3.3.3',
        );
      }
    }

      final log4jModules = [
        'log4j-api',
        'log4j-core',
        'log4j-slf4j2-impl',
      ];
      for (final module in log4jModules) {
        await libManager.downloadLibrary(
          groupId: 'org.apache.logging.log4j',
          artifactId: module,
          version: '2.20.0',
        );
      }

      await libManager.downloadLibrary(
        groupId: 'org.slf4j',
        artifactId: 'slf4j-api',
        version: '2.0.7',
      );

      print('$prefix Initializing VersionManager...');
      final versManager = VersionManager();
      await versManager.init(versionsDirPath: versionsDir.path);
      await versManager.downloadAllVersions();

      print('$prefix Initializing JavaFileCompiler...');
      final compiler = JavaFileCompiler();
      await compiler.init(scriptsDirPath: scriptsDir.path);

      compiler.addLibraryPaths([
        await libManager.getLibraryPath(groupId: 'net.raphimc', artifactId: 'MinecraftAuth', version: '4.1.2'),
        await libManager.getLibraryPath(groupId: 'net.lenni0451.commons', artifactId: 'httpclient', version: '1.8.0'),
        await libManager.getLibraryPath(groupId: 'com.google.code.gson', artifactId: 'gson', version: '2.13.2'),
      ]);

      await compiler.compileClass('Authenticate.java');
      await compiler.compileClass('JarMerger.java');

      print('$prefix Initializing Authenticator...');
      final auth = Authenticator();
      await auth.init(profileDirPath: launcherDir.path, scriptsDirPath: scriptsDir.path);

      auth.addLibraryPaths([
        await libManager.getLibraryPath(groupId: 'net.raphimc', artifactId: 'MinecraftAuth', version: '4.1.2'),
        await libManager.getLibraryPath(groupId: 'net.lenni0451.commons', artifactId: 'httpclient', version: '1.8.0'),
        await libManager.getLibraryPath(groupId: 'com.google.code.gson', artifactId: 'gson', version: '2.13.2'),
        await libManager.getLibraryPath(groupId: 'org.apache.logging.log4j', artifactId: 'log4j-slf4j2-impl', version: '2.20.0'),
        await libManager.getLibraryPath(groupId: 'org.slf4j', artifactId: 'slf4j-api', version: '2.0.17'),
        await libManager.getLibraryPath(groupId: 'org.apache.logging.log4j', artifactId: 'log4j-api', version: '2.20.0'),
        await libManager.getLibraryPath(groupId: 'org.apache.logging.log4j', artifactId: 'log4j-core', version: '2.20.0'),
      ]);

      print('$prefix Initializing InstanceManager...');
      final instManager = InstanceManager();
      await instManager.init(instancesDirPath: instancesDir.path, scriptsDirPath: scriptsDir.path, authenticator: auth, libraryManager: libManager, versionManager: versManager);

      await auth.authenticateFlow();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => BetterThanLauncher(instanceManager: instManager, versionManager: versManager,)),
        );
      }
    } catch (e) {
      print('$prefix Setup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BuildScreen(lastLine: widget.lastLine);
  }
}

Future<List<Directory>> setupAppFolders() async {
  final exePath = Platform.resolvedExecutable;
  final exeDir = Directory(p.dirname(exePath));

  final launcherDir = Directory(p.join(exeDir.path, 'launcher'));
  final instancesDir = Directory(p.join(launcherDir.path, 'instances'));
  final librariesDir = Directory(p.join(launcherDir.path, 'libraries'));
  final versionsDir = Directory(p.join(launcherDir.path, 'versions'));
  final scriptsDir = Directory(p.join(launcherDir.path, 'scripts'));

  for (final dir in [instancesDir, librariesDir, versionsDir, scriptsDir]) {
    if (!await dir.exists()) await dir.create(recursive: true);
  }

  return [launcherDir, instancesDir, librariesDir, versionsDir, scriptsDir];
}

class BetterThanLauncher extends StatelessWidget {
  final InstanceManager instanceManager;
  final VersionManager versionManager;

  const BetterThanLauncher({
    super.key,
    required this.instanceManager,
    required this.versionManager,
  });

  Future<String> getJavaVersion() async {
    try {
      ProcessResult result = await Process.run('java', ['-version']);
      return result.stderr.toString().split('\n')[0];
    } catch (e) {
      return 'Java not found or an error occurred: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'BetterThanLauncher',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: theme.mainBackground,
            primaryColor: theme.buttonNormal,
            cardColor: theme.cardBackground,
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: theme.primaryText),
              bodyMedium: TextStyle(color: theme.highlightText),
            ),
          ),
          home: HomeScreen(instanceManager: instanceManager, versionManager: versionManager,),
        );
      },
    );
  }
}
