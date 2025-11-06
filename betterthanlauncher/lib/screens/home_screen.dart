import 'dart:io';
import 'package:flutter/material.dart';
import '../components/round_icon_button.dart';
import '../components/top_left_border_painter.dart';
import '../themes/theme_manager.dart';
import '../service/instance_manager.dart';

class HomeScreen extends StatelessWidget {
  final InstanceManager instanceManager;

  const HomeScreen({
    super.key,
    required this.instanceManager,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;
    const double topBarHeight = 80;
    const double leftBarWidth = 80;

    return Scaffold(
      backgroundColor: theme.components,
      body: Stack(
        children: [
          // ─────────────────────────────────────────────
          // MAIN AREA – Instanzliste
          // ─────────────────────────────────────────────
          Positioned(
            top: topBarHeight,
            left: leftBarWidth,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              painter: TopLeftBorderPainter(
                backgroundColor: theme.background,
                borderColor: theme.components2,
                borderWidth: 1,
                radius: 20,
              ),
              child: ValueListenableBuilder(
                valueListenable: instanceManager.instances,
                builder: (context, instanceList, _) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: instanceList.isEmpty
                        ? Center(
                            child: Text(
                              "No Instances Found",
                              style: TextStyle(
                                color: theme.text2,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: instanceList.length,
                            itemBuilder: (context, i) {
                              final name = instanceList[i]
                                  .path
                                  .split(Platform.pathSeparator)
                                  .last;

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
                                      style: TextStyle(
                                        color: theme.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: Icon(Icons.play_arrow, color: theme.text),
                                    onTap: () => _startInstance(context, name),
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ),

          // ─────────────────────────────────────────────
          // TOP BAR
          // ─────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topBarHeight,
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.asset(
                    'assets/icons/title.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // ─────────────────────────────────────────────
          // LEFT SIDEBAR
          // ─────────────────────────────────────────────
          Positioned(
            top: topBarHeight,
            left: 0,
            width: leftBarWidth,
            bottom: 0,
            child: Container(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  RoundIconButton(
                    icon: Icon(Icons.home, color: theme.text2),
                    onPressed: () {},
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),

                  RoundIconButton(
                    icon: Icon(Icons.add, color: theme.text2),
                    onPressed: () async {
                      await instanceManager.createInstance(
                        "Instance_${DateTime.now().millisecondsSinceEpoch}",
                      );
                    },
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: theme.text, thickness: 1, height: 24),
                  ),

                  RoundIconButton(
                    icon: Icon(Icons.checkroom, color: theme.text2),
                    onPressed: () {},
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: theme.text, thickness: 1, height: 24),
                  ),

                  RoundIconButton(
                    icon: Icon(Icons.settings, color: theme.text2),
                    onPressed: () {},
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),

                  RoundIconButton(
                    icon: Icon(Icons.discord, color: theme.text2),
                    onPressed: () {},
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🔹 Instance Start Logik + Dialog
  // ─────────────────────────────────────────────
  Future<void> _startInstance(BuildContext context, String name) async {
    final theme = ThemeManager.currentTheme.value;
    final lastLine = ValueNotifier<String>("Starting instance '$name'...");

    // Fortschrittsdialog anzeigen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SizedBox(
          width: 300,
          child: ValueListenableBuilder<String>(
            valueListenable: lastLine,
            builder: (context, line, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: theme.text),
                  const SizedBox(height: 20),
                  Text(
                    line,
                    style: TextStyle(color: theme.text, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    try {
      final process = await instanceManager.startInstanceWithOutput(name);

      // stdout → UI
      process.stdout.transform(SystemEncoding().decoder).listen((line) {
        lastLine.value = line.trim();
      });

      // stderr → UI (rot markiert)
      process.stderr.transform(SystemEncoding().decoder).listen((line) {
        lastLine.value = "⚠️ ${line.trim()}";
      });

      final exitCode = await process.exitCode;
      Navigator.of(context).pop(); // Dialog schließen

      if (exitCode == 0) {
        _showSnack(context, "Instance '$name' exited successfully.");
      } else {
        _showSnack(context, "Instance crashed (code $exitCode)");
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showSnack(context, "Error starting instance: $e");
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
