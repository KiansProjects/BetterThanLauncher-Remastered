import 'package:betterthanlauncher/service/instance_manager.dart';
import 'package:betterthanlauncher/service/version_manager.dart';
import 'package:betterthanlauncher/themes/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InstanceSettingsView extends StatefulWidget {
  final String instanceName;
  final InstanceManager instanceManager;
  final VersionManager versionManager;
  final VoidCallback? onSaved;

  const InstanceSettingsView({
    super.key,
    required this.instanceName,
    required this.instanceManager,
    required this.versionManager,
    this.onSaved,
  });

  @override
  State<InstanceSettingsView> createState() => _InstanceSettingsViewState();
}

class _InstanceSettingsViewState extends State<InstanceSettingsView> {
  Map<String, String> _config = {};
  bool _isLoading = true;
  bool _saving = false;

  late TextEditingController _jvmArgsController;
  double _ramValue = 2048;

  List<String> _availableVersions = [];
  String? _selectedVersion;

  @override
  void initState() {
    super.initState();
    _jvmArgsController = TextEditingController();
    _loadConfig();
    _loadVersions();
  }

  Future<void> _loadConfig() async {
    try {
      final cfg = await widget.instanceManager.getConfig(widget.instanceName);
      setState(() {
        _config = cfg;
        _ramValue = double.tryParse(cfg["ram"] ?? "2048") ?? 2048;
        _jvmArgsController.text = cfg["jvmArgs"] ?? "";
        _selectedVersion = cfg["version"];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Failed to load config: $e");
    }
  }

  Future<void> _loadVersions() async {
    try {
      final versions = await widget.versionManager.getVersions();
      final reversed = versions.reversed.toList();
      setState(() {
        _availableVersions = reversed;
        if (_selectedVersion == null && reversed.isNotEmpty) {
          _selectedVersion = reversed.first;
        }
      });
    } catch (e) {
      debugPrint("Failed to load versions: $e");
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _saving = true);

    final updatedConfig = Map<String, String>.from(_config);
    updatedConfig["ram"] = _ramValue.toInt().toString();
    updatedConfig["jvmArgs"] = _jvmArgsController.text.trim();
    if (_selectedVersion != null) updatedConfig["version"] = _selectedVersion!;

    try {
      final delay = Future.delayed(Duration(seconds: 1));

      await Future.wait([widget.instanceManager.saveConfig(widget.instanceName, updatedConfig), delay]);

      setState(() => _saving = false);

      if (widget.onSaved != null) widget.onSaved!();
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;

    if (_isLoading) {
      return Center(
        child: Text(
          "Loading settings...",
          style: TextStyle(color: theme.secondaryText),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVersionDropdown(theme),
        const SizedBox(height: 16),
        _buildRamSlider(theme),
        const SizedBox(height: 16),
        _buildJvmArgsEditor(label: "JVM Arguments", controller: _jvmArgsController),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: _buildSaveButton(theme),
        ),
      ],
    );
  }

  Widget _buildVersionDropdown(dynamic theme) {
    return DropdownButtonFormField<String>(
        value: _selectedVersion,
        dropdownColor: theme.cardBackground,
        items: _availableVersions
            .map(
              (v) => DropdownMenuItem(
                value: v,
                child: Text(
                  v,
                  style: TextStyle(color: theme.primaryText),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedVersion = v),
        decoration: InputDecoration(
          labelText: "Version",
          labelStyle: TextStyle(color: theme.secondaryText),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.borderColor, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.primaryText, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: theme.cardBackground,
        ),
    );
  }

  Widget _buildRamSlider(dynamic theme) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: "RAM (MB)",
        labelStyle: TextStyle(color: theme.secondaryText),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.borderColor, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.primaryText, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: theme.cardBackground,
        suffixText: "${_ramValue.toInt()} MB",
        suffixStyle: TextStyle(color: theme.primaryText),
      ),
      child: Slider(
        value: _ramValue,
        min: 512,
        max: 8192,
        divisions: 64,
        activeColor: theme.highlightText,
        onChanged: (v) => setState(() => _ramValue = v),
      ),
    );
  }

  Widget _buildJvmArgsEditor({
    required String label,
    required TextEditingController controller,
  }) {
    final theme = ThemeManager.currentTheme.value;

    return TextField(
      controller: controller,
      maxLines: null,
      readOnly: false,
      style: TextStyle(color: theme.primaryText),
      cursorColor: theme.primaryText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.secondaryText),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.borderColor, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.primaryText, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: theme.cardBackground,
      ),
      keyboardType: TextInputType.text,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\n')),
      ],
    );
  }

  Widget _buildSaveButton(dynamic theme) {
    return SizedBox(
      width: 100,
      height: 40,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveConfig,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(MaterialState.hovered)) return theme.buttonHover;
              if (states.contains(MaterialState.disabled)) return theme.buttonNormal.withOpacity(0.5);
              return theme.buttonNormal;
            },
          ),
          foregroundColor: MaterialStateProperty.all(theme.highlightText),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          padding: MaterialStateProperty.all(EdgeInsets.zero),
        ),
        child: _saving
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.highlightText,
                ),
              )
            : const Text("Save"),
      ),
    );
  }
}
