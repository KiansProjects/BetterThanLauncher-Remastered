import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'themes/theme_manager.dart';
import 'screens/home_screen.dart';
import 'service/instance_manager.dart';
import 'service/library_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupAppFolders();
  await InstanceManager().init();

  final libManager = LibraryManager();
  await libManager.init();

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

  libManager.downloadLibrary(
    groupId: 'org.apache.logging.log4j',
    artifactId: 'log4j-api',
    version: '2.20.0'
  );

  libManager.downloadLibrary(
    groupId: 'org.apache.logging.log4j',
    artifactId: 'log4j-core',
    version: '2.20.0'
  );

  runApp(BetterThanLauncher());
}

// javac -cp "/home/kian/Dokumente/libraries/net/raphimc/MinecraftAuth/4.1.2/MinecraftAuth-4.1.2.jar:/home/kian/Dokumente/libraries/net/lenni0451/commons/httpclient/1.8.0/httpclient-1.8.0.jar:/home/kian/Dokumente/libraries/com/google/code/gson/gson/2.13.2/gson-2.13.2.jar:/home/kian/Dokumente/libraries/org/apache/logging/log4j/log4j-slf4j2-impl/2.20.0/log4j-slf4j2-impl-2.20.0.jar:/home/kian/Dokumente/libraries/org/slf4j/slf4j-api/2.0.17/slf4j-api-2.0.17.jar:/home/kian/Dokumente/libraries/org/apache/logging/log4j/log4j-api/2.20.0/log4j-api-2.20.0.jar:/home/kian/Dokumente/libraries/org/apache/logging/log4j/log4j-core/2.20.0/log4j-core-2.20.0.jar" Authenticate.java
// java -cp ".:/home/kian/Dokumente/libraries/net/raphimc/MinecraftAuth/4.1.2/MinecraftAuth-4.1.2.jar:/home/kian/Dokumente/libraries/net/lenni0451/commons/httpclient/1.8.0/httpclient-1.8.0.jar:/home/kian/Dokumente/libraries/com/google/code/gson/gson/2.13.2/gson-2.13.2.jar:/home/kian/Dokumente/libraries/org/apache/logging/log4j/log4j-slf4j2-impl/2.20.0/log4j-slf4j2-impl-2.20.0.jar:/home/kian/Dokumente/libraries/org/slf4j/slf4j-api/2.0.17/slf4j-api-2.0.17.jar:/home/kian/Dokumente/libraries/org/apache/logging/log4j/log4j-api/2.20.0/log4j-api-2.20.0.jar:/home/kian/Dokumente/libraries/org/apache/logging/log4j/log4j-core/2.20.0/log4j-core-2.20.0.jar" Authenticate

Future<void> setupAppFolders() async {
  final dir = await getApplicationDocumentsDirectory();

  final instancesDir = Directory('${dir.path}/instances');
  final librariesDir = Directory('${dir.path}/libraries');
  final versionsDir = Directory('${dir.path}/versions');
  final scriptsDir = Directory('${dir.path}/scripts');

  if (!await instancesDir.exists()) await instancesDir.create(recursive: true);
  if (!await librariesDir.exists()) await librariesDir.create(recursive: true);
  if (!await versionsDir.exists()) await versionsDir.create(recursive: true);
  if (!await scriptsDir.exists()) await scriptsDir.create(recursive: true);

  final scriptFile = File('${scriptsDir.path}/Authenticate.class');
  if (!await scriptFile.exists()) {
    final data = await rootBundle.load('assets/scripts/Authenticate.class');
    final bytes = data.buffer.asUint8List();
    await scriptFile.writeAsBytes(bytes);
  }
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
