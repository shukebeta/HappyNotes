import 'package:flutter/material.dart';
import 'package:happy_notes/entities/telegram_settings.dart';
import '../../dependency_injection.dart';
import 'telegram_sync_settings_controller.dart';
import '../../utils/util.dart'; // Import Util

class AddTelegramSetting extends StatefulWidget {
  final TelegramSettings? setting;
  const AddTelegramSetting({super.key, this.setting});

  @override
  AddTelegramSettingState createState() => AddTelegramSettingState();
}

class AddTelegramSettingState extends State<AddTelegramSetting> {
  final TextEditingController _channelIdController = TextEditingController();
  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _syncType = 3;
  bool _isLoading = false;
  final TelegramSyncSettingsController _settingsController = locator<TelegramSyncSettingsController>();

  @override
  void initState() {
    super.initState();
    if (widget.setting != null) {
      _tokenController.text = 'the same token as the last setting';
      _remarkController.text = widget.setting!.tokenRemark!;
    }
  }

  @override
  void dispose() {
    _channelIdController.dispose();
    _channelNameController.dispose();
    _tokenController.dispose();
    _remarkController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          errorMaxLines: 2,
        ),
        validator: validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            },
      ),
    );
  }

  Future<void> _saveSetting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _settingsController.addTelegramSetting(
        TelegramSettings(
          syncType: _syncType,
          syncValue: _syncType == 4 ? _tagController.text : '',
          channelId: _channelIdController.text.trim(),
          channelName: _channelNameController.text.trim(),
          tokenRemark: _remarkController.text.trim(),
          encryptedToken: _tokenController.text.trim(),
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Util.showError(
            ScaffoldMessenger.of(context), 'Failed to save settings: ${e.toString()}'); // Replaced showSnackBar
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sync Setting - Telegram'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sync Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Source Note',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        value: _syncType,
                        items: const [
                          DropdownMenuItem<int>(
                            value: 1,
                            child: Text('Public Notes'),
                          ),
                          DropdownMenuItem<int>(
                            value: 2,
                            child: Text('Private Notes'),
                          ),
                          DropdownMenuItem<int>(
                            value: 3,
                            child: Text('All Notes (Public + Private)'),
                          ),
                          DropdownMenuItem<int>(
                            value: 4,
                            child: Text('Notes with Specific Tag'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _syncType = value!),
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a source note type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_syncType == 4)
                        _buildInputField(
                          controller: _tagController,
                          label: 'Tag',
                          hint: 'Enter tag text, such as "memories"',
                          validator: (value) {
                            if (_syncType == 4 && (value == null || value.trim().isEmpty)) {
                              return 'Tag is required for tag-based sync';
                            }
                            return null;
                          },
                        ),
                      _buildInputField(
                        controller: _channelIdController,
                        label: 'Channel ID',
                        hint: 'Telegram channel ID',
                        keyboardType: TextInputType.text,
                      ),
                      _buildInputField(
                        controller: _channelNameController,
                        label: 'Channel Name',
                        hint: 'Channel name that helps you remember',
                        keyboardType: TextInputType.text,
                      ),
                      _buildInputField(
                        controller: _tokenController,
                        label: 'Telegram Bot Token',
                        hint: 'Your bot token',
                        obscureText: false,
                      ),
                      _buildInputField(
                        controller: _remarkController,
                        label: 'Token Remark',
                        hint: 'Add a description for this token',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _saveSetting,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Settings',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
