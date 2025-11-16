import 'package:flutter/material.dart';
import '../themes/theme_manager.dart';
import '../service/instance_manager.dart';
import '../service/version_manager.dart';
import '../widgets/app_card_decoration.dart';

class InstanceCreationView extends StatefulWidget {
  final InstanceManager instanceManager;
  final VersionManager versionManager;
  final VoidCallback onCancel;
  final VoidCallback onCreated;

  const InstanceCreationView({
    super.key,
    required this.instanceManager,
    required this.versionManager,
    required this.onCancel,
    required this.onCreated,
  });

  @override
  State<InstanceCreationView> createState() => _InstanceCreationViewState();
}

class _InstanceCreationViewState extends State<InstanceCreationView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedVersion;
  bool _isLoading = false;
  List<String> _availableVersions = [];

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    try {
      final versions = await widget.versionManager.getVersions();
      final reversed = versions.reversed.toList();
      setState(() {
        _availableVersions = reversed;
        _selectedVersion = reversed.isNotEmpty ? reversed.first : null;
      });
    } catch (e) {
      debugPrint("Failed to load versions: $e");
    }
  }

  Future<void> _createInstance() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      await widget.instanceManager.createInstance(name);
      widget.onCreated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error creating instance: $e"),
          backgroundColor: ThemeManager.currentTheme.value.errorText,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Create New Instance",
            style: TextStyle(
              color: theme.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  maxLength: 32,
                  style: TextStyle(color: theme.primaryText),
                  cursorColor: theme.primaryText,
                  decoration: InputDecoration(
                    labelText: "Instance Name",
                    labelStyle: TextStyle(color: theme.secondaryText),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.borderColor, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primaryText, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.errorText, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.errorText, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: theme.cardBackground,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a name";
                    }
                    if (widget.instanceManager.instanceExists(value.trim())) {
                      return "Instance already exists";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                if (_availableVersions.isNotEmpty)
                  DropdownButtonFormField<String>(
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
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "Loading versions...",
                        style: TextStyle(color: theme.secondaryText),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildRoundButton(
                label: "Cancel",
                onPressed: _isLoading ? null : widget.onCancel,
                theme: theme,
              ),
              const SizedBox(width: 10),
              _buildRoundButton(
                label: "Create",
                onPressed: _isLoading ? null : _createInstance,
                theme: theme,
                isLoading: _isLoading,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRoundButton({
    required String label,
    required VoidCallback? onPressed,
    required dynamic theme,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: 100,
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
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
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          padding: MaterialStateProperty.all(EdgeInsets.zero),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.highlightText,
                ),
              )
            : Text(label),
      ),
    );
  }
}
