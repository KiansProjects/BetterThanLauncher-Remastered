import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class JavaFileCompiler {
  late Directory _scriptsDir;
  final List<String> _libraryPaths = [];

  final String prefix = '[JavaCompiler]';

  Future<void> init({required String scriptsDirPath}) async {
    print('$prefix Initializing JavaFileCompiler...');
    
    _scriptsDir = Directory(scriptsDirPath);
    if (!await _scriptsDir.exists()) {
      await _scriptsDir.create(recursive: true);
      print('$prefix Scripts directory created at ${_scriptsDir.path}');
    }
  }

  void addLibraryPath(String jarPath) => _libraryPaths.add(jarPath);
  void addLibraryPaths(List<String> jarPaths) => _libraryPaths.addAll(jarPaths);

  Future<void> compileClass(String javaFileName) async {
    final javaFile = File(p.join(_scriptsDir.path, javaFileName));

    try {
      final data = await rootBundle.load('assets/scripts/$javaFileName');
      final bytes = data.buffer.asUint8List();
      await javaFile.writeAsBytes(bytes);
    } catch (e) {
      print('$prefix Error: $javaFileName not found in assets.');
    }

    String? classpath;
    if (_libraryPaths.isNotEmpty) {
      classpath = _libraryPaths.join(Platform.isWindows ? ';' : ':');
    }

    final args = <String>[];
    if (classpath != null) {
      args.addAll(['-cp', classpath]);
    }
    args.add(javaFile.path);

    final result = await Process.run('javac', args);

    if (result.exitCode != 0) {
      print('$prefix Java compilation failed for $javaFileName:\n${result.stderr}');
    } else {
      print('$prefix Successfully compiled $javaFileName');
    }

    if (await javaFile.exists()) {
      await javaFile.delete();
    }
  }
}
