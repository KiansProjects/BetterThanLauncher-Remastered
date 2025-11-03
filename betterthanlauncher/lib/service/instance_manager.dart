import 'dart:io';
import 'package:flutter/foundation.dart';

class InstanceManager {
  static final InstanceManager _instance = InstanceManager._internal();
  factory InstanceManager() => _instance;
  InstanceManager._internal();

  final ValueNotifier<List<Directory>> instances = ValueNotifier([]);
  late Directory _instancesRootDir;

  Future<void> init({required String instancesDirPath}) async {
    _instancesRootDir = Directory(instancesDirPath);

    if (!await _instancesRootDir.exists()) {
      await _instancesRootDir.create(recursive: true);
    }

    instances.value = _instancesRootDir
        .listSync()
        .whereType<Directory>()
        .toList();

    if (instances.value.isEmpty) {
      await createInstance("example_instance");
    }
  }

  Future<void> createInstance(String name) async {
    final newInstanceDir =
        Directory('${_instancesRootDir.path}${Platform.pathSeparator}$name');

    if (!await newInstanceDir.exists()) {
      await newInstanceDir.create(recursive: true);
    }

    instances.value = [...instances.value, newInstanceDir];
  }

  bool instanceExists(String name) =>
      instances.value.any((d) =>
          d.path.split(Platform.pathSeparator).last == name);
}
