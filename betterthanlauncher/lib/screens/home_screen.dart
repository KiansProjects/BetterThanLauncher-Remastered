import 'dart:io';
import 'package:flutter/material.dart';
import '../components/round_icon_button.dart';
import '../components/top_left_border_painter.dart';
import '../themes/theme_manager.dart';
import '../service/instance_manager.dart';
import 'instance_list_view.dart';
import 'instance_output_view.dart';

class HomeScreen extends StatefulWidget {
  final InstanceManager instanceManager;

  const HomeScreen({super.key, required this.instanceManager});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ValueNotifier<String> _output = ValueNotifier<String>("");
  String? _activeInstance;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;
    const double topBarHeight = 80;
    const double leftBarWidth = 80;

    return Scaffold(
      backgroundColor: theme.components,
      body: Stack(
        children: [
          // MAIN AREA
          Positioned(
            top: topBarHeight,
            left: leftBarWidth,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              painter: TopLeftBorderPainter(
                backgroundColor: theme.background,
                borderColor: theme.components2,
                borderWidth: 2,
                radius: 20,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _activeInstance == null
                    ? InstanceListView(
                        instanceManager: widget.instanceManager,
                        onStartInstance: _startInstance,
                      )
                    : InstanceOutputView(
                        instanceName: _activeInstance!,
                        output: _output,
                        onClose: () => setState(() => _activeInstance = null),
                      ),
              ),
            ),
          ),

          // TOP BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topBarHeight,
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Image.asset('assets/icons/title.png', fit: BoxFit.contain),
              ),
            ),
          ),

          // LEFT SIDEBAR
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

                  // Home Button
                  RoundIconButton(
                    icon: Icon(Icons.home, color: theme.text2),
                    onPressed: () => setState(() => _activeInstance = null),
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),

                  // Add Button
                  RoundIconButton(
                    icon: Icon(Icons.add, color: theme.text2),
                    onPressed: () async {
                      await widget.instanceManager.createInstance(
                        "Instance_${DateTime.now().millisecondsSinceEpoch}",
                      );
                    },
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: theme.text, thickness: 1, height: 24),
                  ),

                  // Checkroom Button
                  RoundIconButton(
                    icon: Icon(Icons.checkroom, color: theme.text2),
                    onPressed: () {},
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: theme.text, thickness: 1, height: 24),
                  ),

                  // Settings Button
                  RoundIconButton(
                    icon: Icon(Icons.settings, color: theme.text2),
                    onPressed: () {},
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),

                  // Discord Button
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

  Future<void> _startInstance(String name) async {
    setState(() {
      _activeInstance = name;
      _output.value = "Starting instance '$name'...\n";
    });

    try {
      final process = await widget.instanceManager.startInstanceWithOutput(name);

      process.stdout.transform(SystemEncoding().decoder).listen((line) {
        _output.value += line;
      });

      process.stderr.transform(SystemEncoding().decoder).listen((line) {
        _output.value += line;
      });

      final exitCode = await process.exitCode;
      _output.value += "\nInstance exited with code $exitCode\n";
    } catch (e) {
      _output.value += "\nError starting instance: $e\n";
    }
  }
}
