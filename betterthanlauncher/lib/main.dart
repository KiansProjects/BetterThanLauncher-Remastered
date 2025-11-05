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
import 'service/authenticate.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSetup());
  }

  Future<void> _runSetup() async {
    try {
      print('Setting up app folders...');
      final dirs = await setupAppFolders();
      print('Folders ready.');

      final launcherDir = dirs[0];
      final instancesDir = dirs[1];
      final librariesDir = dirs[2];
      final versionsDir = dirs[3];
      final scriptsDir = dirs[4];

      print('Initializing InstanceManager...');
      final instManager = InstanceManager();
      await instManager.init(instancesDirPath: instancesDir.path);

      print('Initializing LibraryManager...');
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
        groupId: 'org.apache.logging.log4j',
        artifactId: 'log4j-slf4j2-impl',
        version: '2.20.0',
      );
      await libManager.downloadLibrary(
        groupId: 'org.slf4j',
        artifactId: 'slf4j-api',
        version: '2.0.17',
      );
      await libManager.downloadLibrary(
        groupId: 'org.apache.logging.log4j',
        artifactId: 'log4j-api',
        version: '2.20.0',
      );
      await libManager.downloadLibrary(
        groupId: 'org.apache.logging.log4j',
        artifactId: 'log4j-core',
        version: '2.20.0',
      );

      print('Library downloads complete.');

      final versManager = VersionManager();
      await versManager.init(versionsDirPath: versionsDir.path);
      await versManager.downloadAllVersions();
      print('Versions downloaded.');

      final compiler = JavaFileCompiler();
      await compiler.init(scriptsDirPath: scriptsDir.path);

      compiler.addLibraryPaths([
        await libManager.getLibraryPath(groupId: 'net.raphimc', artifactId: 'MinecraftAuth', version: '4.1.2'),
        await libManager.getLibraryPath(groupId: 'net.lenni0451.commons', artifactId: 'httpclient', version: '1.8.0'),
        await libManager.getLibraryPath(groupId: 'com.google.code.gson', artifactId: 'gson', version: '2.13.2'),
      ]);

      await compiler.compileClass('Authenticate.java');
      await compiler.compileClass('JarMerger.java');
      print('Java compilation done.');

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
      print('Authentication complete.');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BetterThanLauncher()),
        );
      }
    } catch (e) {
      print('Setup failed: $e');
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
  const BetterThanLauncher({super.key});

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
          title: 'Flutter App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: theme.background,
            primaryColor: theme.components4,
            cardColor: theme.components,
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: theme.text),
              bodyMedium: TextStyle(color: theme.text2),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }  
}
