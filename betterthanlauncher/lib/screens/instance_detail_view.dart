import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../service/instance_manager.dart';
import '../themes/theme_manager.dart';
import '../widgets/app_card_decoration.dart';
import 'instance_output_view.dart';
import 'instance_settings_view.dart';

class InstanceDetailView extends StatefulWidget {
  final String instanceName;
  final InstanceManager instanceManager;
  final ValueNotifier<List<String>> logLines;
  final VoidCallback onClose;

  const InstanceDetailView({
    super.key,
    required this.instanceName,
    required this.instanceManager,
    required this.logLines,
    required this.onClose,
  });

  @override
  State<InstanceDetailView> createState() => _InstanceDetailViewState();
}

class _InstanceDetailViewState extends State<InstanceDetailView> {
  Process? _process;
  bool _isDeleting = false;

  Future<void> _startInstance() async {
    if (_process != null) return;
    widget.logLines.value = ["Starting instance ${widget.instanceName}...\n"];
    final p = await widget.instanceManager.startInstanceWithOutput(widget.instanceName);
    _process = p;

    p.stdout
        .transform(SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.trim().isEmpty) return;
      widget.logLines.value = [...widget.logLines.value, line];
    });

    p.stderr
        .transform(SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.trim().isEmpty) return;
      widget.logLines.value = [...widget.logLines.value, line];
    });

    p.exitCode.then((code) {
      widget.logLines.value = [...widget.logLines.value, "\nInstance exited with code $code\n"];
      setState(() => _process = null);
    });

    setState(() {});
  }

  Future<void> _stopInstance() async {
    if (_process == null) return;
    widget.logLines.value = [...widget.logLines.value, "\nStopping instance...\n"];
    _process!.kill(ProcessSignal.sigkill);
    setState(() => _process = null);
  }

  Future<void> _openFolder() async {
    final path = widget.instanceManager.getInstancePath(widget.instanceName);
    if (path == null) return;

    if (await Directory(path).exists()) {
      if (Platform.isWindows) {
        await Process.start('explorer', [path]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [path]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [path]);
      }
    }
  }

  Future<void> _deleteInstance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Instance"),
        content: const Text("Are you sure you want to delete this instance?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await widget.instanceManager.deleteInstance(widget.instanceName);
      widget.onClose();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting: $e")));
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;

    return DefaultTabController(
      length: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: appCardDecoration(theme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.instanceName,
                  style: TextStyle(
                    color: theme.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_process == null ? Icons.play_arrow : Icons.stop,
                    color: theme.highlightText),
                  onPressed: _process == null ? _startInstance : _stopInstance,
                ),
                IconButton(
                  icon: Icon(Icons.folder_open, color: theme.highlightText),
                  onPressed: _openFolder,
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: theme.errorText),
                  onPressed: _isDeleting ? null : _deleteInstance,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Divider(
              height: 2,
              thickness: 1,
              color: theme.primaryText,
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: 300,
              child: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: theme.highlightText.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: theme.highlightText,
                  unselectedLabelColor: theme.secondaryText,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    SizedBox(width: 80, height: 40, child: Center(child: Text("Content"))),
                    SizedBox(width: 80, height: 40, child: Center(child: Text("Console"))),
                    SizedBox(width: 80, height: 40, child: Center(child: Text("Settings"))),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: TabBarView(
                children: [
                  Center(child: Text("Main Area / Mods (WIP)")),
                  InstanceOutputView(logLines: widget.logLines),
                  InstanceSettingsView(instanceName: widget.instanceName),
                ],
              ),
            ),
          ],
        ),
      ),
    ); 
  }
}
