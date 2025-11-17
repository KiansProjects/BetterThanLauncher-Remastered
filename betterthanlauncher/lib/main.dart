import 'dart:async';
import 'dart:io';
import 'package:betterthanlauncher/screens/build_screen.dart';
import 'package:betterthanlauncher/screens/home_screen.dart';
import 'package:betterthanlauncher/service/authenticator.dart';
import 'package:betterthanlauncher/service/discord_presence_manager.dart';
import 'package:betterthanlauncher/service/instance_manager.dart';
import 'package:betterthanlauncher/service/library_manager.dart';
import 'package:betterthanlauncher/service/version_manager.dart';
import 'package:betterthanlauncher/themes/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

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
  final String prefix = '[Setup]';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSetup());
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<int?> getJavaVersion() async {
    try {
      final result = await Process.run('java', ['-version']);
      final output = (result.stderr as String).split('\n').first;

      final regex = RegExp(r'version "(\d+)(\.\d+)*');
      final match = regex.firstMatch(output);

      if (match != null) {
        return int.parse(match.group(1)!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String getJdk17Url() {
    if (Platform.isWindows) {
      return "https://www.oracle.com/java/technologies/downloads/#jdk17-windows";
    } else if (Platform.isMacOS) {
      return "https://www.oracle.com/java/technologies/downloads/#jdk17-mac";
    } else if (Platform.isLinux) {
      return "https://www.oracle.com/java/technologies/downloads/#jdk17-linux";
    }
    return "https://www.oracle.com/java/technologies/downloads/";
  }


  Future<void> openJdk17Page() async {
    final url = getJdk17Url();

    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', url]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
    }
  }

  Future<void> _runSetup() async {
    try {
      print('$prefix Checking internet connection...');
      if (!await hasInternetConnection()) {
        print('$prefix No Internet Connection: The launcher requires an internet connection to continue. Please check your connection and restart the launcher.');
        return;
      }
      print('$prefix Internet connection. Continuing setup...');

      print('$prefix Checking Java installation...');
      final javaVersion = await getJavaVersion();
      final url = getJdk17Url();

      if (javaVersion == null) {
        print('$prefix Java Not Found: Java 17 or higher is required. Click the button below to download it from Oracle.\n$url');
        await openJdk17Page();
        return;
      }

      if (javaVersion < 17) {
        print('$prefix Java Version Too Low: Detected Java version $javaVersion.\nJava 17 or higher is required.\n$url');
        await openJdk17Page();
        return;
      }

      print('$prefix Java OK ($javaVersion). Continuing setup...');

      final discordPresenceManager = DiscordPresenceManager(clientId: '1439679585133531136');
      discordPresenceManager.init();

      print('$prefix Setting up app folders...');
      final dirs = await setupAppFolders();
      print('$prefix Folders ready.');

      final launcherDir = dirs[0];
      final instancesDir = dirs[1];
      final librariesDir = dirs[2];
      final versionsDir = dirs[3];
      final scriptsDir = dirs[4];

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

      final versManager = VersionManager();
      await versManager.init(versionsDirPath: versionsDir.path);
      await versManager.setUpMinecraftBeta();
      await versManager.setUpBtaVersions();

      final authBytes = await rootBundle.load("assets/scripts/Authenticate.class");
      final authFile = File("${scriptsDir.path}/Authenticate.class");
      await authFile.writeAsBytes(
        authBytes.buffer.asUint8List(),
        flush: true,
      );

      final mergeBytes = await rootBundle.load("assets/scripts/JarMerger.class");
      final mergeFile = File("${scriptsDir.path}/JarMerger.class");
      await mergeFile.writeAsBytes(
        mergeBytes.buffer.asUint8List(),
        flush: true,
      );

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
      
      await auth.authenticateFlow();

      final instManager = InstanceManager();
      await instManager.init(
        instancesDirPath: instancesDir.path, 
        scriptsDirPath: scriptsDir.path, 
        authenticator: auth,
        discordPresenceManager: discordPresenceManager, 
        libraryManager: libManager, 
        versionManager: versManager,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => BetterThanLauncher(
            discordPresenceManager: discordPresenceManager,
            instanceManager: instManager,
            versionManager: versManager,
          )),
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
  final DiscordPresenceManager discordPresenceManager;
  final InstanceManager instanceManager;
  final VersionManager versionManager;

  const BetterThanLauncher({
    super.key,
    required this.discordPresenceManager,
    required this.instanceManager,
    required this.versionManager,
  });

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
          home: HomeScreen(discordPresenceManager: discordPresenceManager, instanceManager: instanceManager, versionManager: versionManager),
        );
      },
    );
  }
}
