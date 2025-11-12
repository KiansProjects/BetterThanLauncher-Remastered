import 'dart:io';
import 'package:flutter/material.dart';
import '../service/instance_manager.dart';
import '../themes/theme_manager.dart';

class InstanceListView extends StatelessWidget {
  final InstanceManager instanceManager;
  final void Function(String name) onStartInstance;
  final void Function(String name) onShowDetails; // Tile-Klick

  const InstanceListView({
    super.key,
    required this.instanceManager,
    required this.onStartInstance,
    required this.onShowDetails,
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
              style: TextStyle(
                color: theme.highlightText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;
        const double tileWidth = 180;
        final crossAxisCount = (screenWidth / tileWidth).floor().clamp(1, 6);

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: instanceList.length,
          itemBuilder: (context, i) {
            final instance = instanceList[i];
            final name = instance.path.split(Platform.pathSeparator).last;

            final iconPath = File("${instance.path}/icon.png");
            final imageProvider = iconPath.existsSync()
                ? FileImage(iconPath)
                : const AssetImage('assets/icons/instance_icon.png') as ImageProvider;

            return GestureDetector(
              onTap: () => onShowDetails(name),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center, // vertikal mittig
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Name links, mittig vertikal
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Play-Button rechts, mittig vertikal
                            IconButton(
                              icon: Icon(Icons.play_arrow, color: theme.primaryText, size: 20),
                              splashRadius: 20,
                              onPressed: () => onStartInstance(name),
                              tooltip: "Start Instance",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
