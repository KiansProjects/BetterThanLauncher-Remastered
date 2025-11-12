import 'dart:io';
import 'package:flutter/material.dart';
import '../components/round_icon_button.dart';
import '../components/top_left_border_painter.dart';
import '../themes/theme_manager.dart';
import '../service/instance_manager.dart';
import '../service/version_manager.dart';
import 'instance_creation_view.dart';
import 'instance_list_view.dart';
import 'instance_detail_view.dart';

class HomeScreen extends StatefulWidget {
  final InstanceManager instanceManager;
  final VersionManager versionManager;

  const HomeScreen({super.key, required this.instanceManager, required this.versionManager});

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
      backgroundColor: theme.cardBackground,
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
                backgroundColor: theme.mainBackground,
                borderColor: theme.borderColor,
                borderWidth: 2,
                radius: 20,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildMainArea(),
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
            child: _buildSidebar(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMainArea() {
    if (_activeInstance == null) {
      return InstanceListView(
        instanceManager: widget.instanceManager,
        onStartInstance: _startInstance,
        onShowDetails: (name) => setState(() => _activeInstance = name),
      );
    } else if (_activeInstance == "create") {
      return InstanceCreationView(
        instanceManager: widget.instanceManager,
        versionManager: widget.versionManager,
        onCancel: () => setState(() => _activeInstance = null),
        onCreated: () => setState(() => _activeInstance = null),
      );
    } else {
      return InstanceDetailView(
        instanceName: _activeInstance!,
        instanceManager: widget.instanceManager,
        output: _output,
        onClose: () => setState(() => _activeInstance = null),
      );
    }
  }

  Widget _buildSidebar(theme) {
    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          RoundIconButton(
            icon: Icon(Icons.home, color: theme.highlightText),
            onPressed: () => setState(() => _activeInstance = null),
            normalColor: theme.buttonNormal,
            hoverColor: theme.buttonHover,
            tooltip: "Home",
            tooltipBackgroundColor: theme.borderColor,
            tooltipTextColor: theme.primaryText,
          ),

          RoundIconButton(
            icon: Icon(Icons.add, color: theme.highlightText),
            onPressed: () => setState(() => _activeInstance = "create"),
            normalColor: theme.buttonNormal,
            hoverColor: theme.buttonHover,
            tooltip: "Create new instance",
            tooltipBackgroundColor: theme.borderColor,
            tooltipTextColor: theme.primaryText,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: theme.primaryText, thickness: 1, height: 24),
          ),

          RoundIconButton(
            icon: Icon(Icons.checkroom, color: theme.highlightText),
            onPressed: () {},
            normalColor: theme.buttonNormal,
            hoverColor: theme.buttonHover,
            tooltip: "Coming soon",
            tooltipBackgroundColor: theme.borderColor,
            tooltipTextColor: theme.primaryText,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: theme.primaryText, thickness: 1, height: 24),
          ),

          RoundIconButton(
            icon: Icon(Icons.settings, color: theme.highlightText),
            onPressed: () {},
            normalColor: theme.buttonNormal,
            hoverColor: theme.buttonHover,
            tooltip: "Settings",
            tooltipBackgroundColor: theme.borderColor,
            tooltipTextColor: theme.primaryText,
          ),

          RoundIconButton(
            icon: Icon(Icons.discord, color: theme.highlightText),
            onPressed: () {},
            normalColor: theme.buttonNormal,
            hoverColor: theme.buttonHover,
            tooltip: "Join our Discord",
            tooltipBackgroundColor: theme.borderColor,
            tooltipTextColor: theme.primaryText,
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
