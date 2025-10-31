import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class InstanceManager {
  static final InstanceManager _instance = InstanceManager._internal();
  factory InstanceManager() => _instance;
  InstanceManager._internal();

  final ValueNotifier<List<Directory>> instances = ValueNotifier([]);

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final instancesDir = Directory('${dir.path}/instances');

    if (!await instancesDir.exists()) {
      await instancesDir.create(recursive: true);
    }

    instances.value = instancesDir
        .listSync()
        .whereType<Directory>()
        .toList();

    if (instances.value.isEmpty) {
      await createInstance("example_instance");
    }
  }

  Future<void> createInstance(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final newInstanceDir = Directory('${dir.path}/instances/$name');

    if (!await newInstanceDir.exists()) {
      await newInstanceDir.create(recursive: true);
    }

    instances.value = [...instances.value, newInstanceDir];
  }

  bool instanceExists(String name) =>
      instances.value.any((d) => d.path.split(Platform.pathSeparator).last == name);
}
