import 'dart:io';
import 'package:flutter/material.dart';
import '../themes/theme_manager.dart';
import '../service/instance_manager.dart';
import 'instance_output_view.dart';

class InstanceDetailView extends StatefulWidget {
  final String instanceName;
  final InstanceManager instanceManager;
  final ValueNotifier<String> output;
  final VoidCallback onClose;

  const InstanceDetailView({
    super.key,
    required this.instanceName,
    required this.instanceManager,
    required this.output,
    required this.onClose,
  });

  @override
  State<InstanceDetailView> createState() => _InstanceDetailViewState();
}

class _InstanceDetailViewState extends State<InstanceDetailView> {
  bool _showConsole = false;
  bool _isDeleting = false;

  void _toggleView() => setState(() => _showConsole = !_showConsole);

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
        SnackBar(
          content: Text("Error deleting instance: $e"),
          backgroundColor: ThemeManager.currentTheme.value.errorText,
        ),
      );
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  Future<void> _startInstance() async {
    widget.output.value = "Starting instance '${widget.instanceName}'...\n";

    try {
      final process = await widget.instanceManager.startInstanceWithOutput(widget.instanceName);

      process.stdout.transform(SystemEncoding().decoder).listen((line) {
        widget.output.value += line;
      });

      process.stderr.transform(SystemEncoding().decoder).listen((line) {
        widget.output.value += line;
      });

      final exitCode = await process.exitCode;
      widget.output.value += "\nInstance exited with code $exitCode\n";
    } catch (e) {
      widget.output.value += "\nError starting instance: $e\n";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor, width: 2),
      ),
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
                icon: Icon(Icons.folder_open, color: theme.highlightText),
                tooltip: "Open Folder",
                onPressed: _openFolder,
              ),
              IconButton(
                icon: Icon(
                  _showConsole ? Icons.view_in_ar : Icons.terminal,
                  color: theme.highlightText,
                ),
                tooltip: _showConsole ? "Show Main Area" : "Show Console",
                onPressed: _toggleView,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: theme.errorText),
                tooltip: "Delete Instance",
                onPressed: _isDeleting ? null : _deleteInstance,
              ),
              IconButton(
                icon: Icon(Icons.play_arrow, color: theme.highlightText),
                tooltip: "Start Instance",
                onPressed: _startInstance,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _showConsole
                ? SizedBox.expand(
                    child: InstanceOutputView(output: widget.output),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: theme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.borderColor, width: 2),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Text(
                        "Main Area / Mods (WIP)",
                        style: TextStyle(color: theme.secondaryText),
                      ),
                    ),
                  ),
          )
        ],
      ),
    );
  }
}
