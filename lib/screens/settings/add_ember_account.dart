import 'package:flutter/material.dart';

import '../../dependency_injection.dart';
import '../../utils/util.dart';
import 'ember_sync_settings_controller.dart';

class AddEmberAccount extends StatefulWidget {
  const AddEmberAccount({super.key});

  @override
  State<AddEmberAccount> createState() => AddEmberAccountState();
}

class AddEmberAccountState extends State<AddEmberAccount> {
  final _formKey = GlobalKey<FormState>();
  final _emberUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final EmberSyncSettingsController _settingsController = locator<EmberSyncSettingsController>();
  bool _isSaving = false;

  @override
  void dispose() {
    _emberUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  String _normalizeUrl(String value) {
    var url = value.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ember URL is required';
    }
    final uri = Uri.tryParse(_normalizeUrl(value));
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a valid Ember URL';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final saved = await _settingsController.add(
      context,
      _normalizeUrl(_emberUrlController.text),
      _apiKeyController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) {
      Util.showInfo(messenger, 'Ember account added.');
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Ember Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _emberUrlController,
              decoration: const InputDecoration(
                labelText: 'Ember URL',
                hintText: 'https://ember.shukelabs.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              validator: _validateUrl,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'Ember API Key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ember API Key is required';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (!_isSaving) _save();
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
