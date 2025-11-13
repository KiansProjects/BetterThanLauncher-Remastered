import 'dart:io';
import 'package:flutter/material.dart';
import 'instance_output_view.dart';
import '../service/instance_manager.dart';
import '../themes/theme_manager.dart';
import '../widgets/app_card_decoration.dart';

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
  bool _showConsole = false;
  bool _isDeleting = false;

  Process? _process;

  void _toggleView() => setState(() => _showConsole = !_showConsole);

  Future<void> _startInstance() async {
    if (_process != null) return;

    widget.logLines.value = ["Starting instance ${widget.instanceName}...\n"];

    final p = await widget.instanceManager.startInstanceWithOutput(widget.instanceName);
    _process = p;

    p.stdout.transform(SystemEncoding().decoder).listen((line) {
      widget.logLines.value = [...widget.logLines.value, line];
    });

    p.stderr.transform(SystemEncoding().decoder).listen((line) {
      widget.logLines.value = [...widget.logLines.value, line];
    });

    p.exitCode.then((code) {
      widget.logLines.value = [
        ...widget.logLines.value,
        "\nInstance exited with code $code\n"
      ];
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting: $e")),
      );
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.instanceName,
                  style: TextStyle(
                    color: theme.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              IconButton(
                icon: Icon(
                  _process == null ? Icons.play_arrow : Icons.stop,
                  color: theme.highlightText,
                ),
                tooltip: _process == null ? "Start Instance" : "Stop Instance",
                onPressed: _process == null ? _startInstance : _stopInstance,
              ),

              IconButton(
                icon: Icon(_showConsole ? Icons.view_in_ar : Icons.terminal, color: theme.highlightText),
                tooltip: _showConsole ? "Show Main Area" : "Show Console",
                onPressed: _toggleView,
              ),

              IconButton(
                icon: Icon(Icons.folder_open, color: theme.highlightText),
                tooltip: "Open Folder",
                onPressed: _openFolder,
              ),

              IconButton(
                icon: Icon(Icons.delete, color: theme.errorText),
                tooltip: "Delete Instance",
                onPressed: _isDeleting ? null : _deleteInstance,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _showConsole
                ? InstanceOutputView(logLines: widget.logLines)
                : Center(
                    child: Text(
                      "Main Area / Mods (WIP)",
                      style: TextStyle(color: theme.secondaryText),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
