import 'dart:io';
import 'package:flutter/material.dart';
import '../service/instance_manager.dart';
import '../themes/theme_manager.dart';

class InstanceListView extends StatelessWidget {
  final InstanceManager instanceManager;
  final void Function(String name) onStartInstance;

  const InstanceListView({
    super.key,
    required this.instanceManager,
    required this.onStartInstance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;

    return ValueListenableBuilder(
      valueListenable: instanceManager.instances,
      builder: (context, instanceList, _) {
        if (instanceList.isEmpty) {
          return Center(
            child: Text(
              "No Instances Found",
              style: TextStyle(color: theme.text2, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        return ListView.builder(
          itemCount: instanceList.length,
          itemBuilder: (context, i) {
            final name = instanceList[i].path.split(Platform.pathSeparator).last;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.components,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(
                    name,
                    style: TextStyle(color: theme.text, fontWeight: FontWeight.w600),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.play_arrow, color: theme.text),
                    onPressed: () => onStartInstance(name),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
