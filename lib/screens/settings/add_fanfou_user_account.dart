import 'package:flutter/material.dart';
import 'package:happy_notes/common/fanfou_sync_type.dart';
import '../../dependency_injection.dart';
import '../../services/fanfou_service.dart';
import '../../utils/util.dart';

class AddFanfouUserAccount extends StatefulWidget {
  const AddFanfouUserAccount({super.key});

  @override
  AddFanfouUserAccountState createState() => AddFanfouUserAccountState();
}

class AddFanfouUserAccountState extends State<AddFanfouUserAccount> {
  final _fanfouService = locator<FanfouService>();
  final _consumerKeyController = TextEditingController();
  final _consumerSecretController = TextEditingController();
  final _syncTypeValue = ValueNotifier<FanfouSyncType>(FanfouSyncType.all);
  bool _isLoading = false;

  @override
  void dispose() {
    _consumerKeyController.dispose();
    _consumerSecretController.dispose();
    _syncTypeValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fanfou Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _consumerKeyController,
              decoration: const InputDecoration(
                labelText: 'Consumer Key',
                hintText: 'Your Fanfou app Consumer Key',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _consumerSecretController,
              decoration: const InputDecoration(
                labelText: 'Consumer Secret',
                hintText: 'Your Fanfou app Consumer Secret',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<FanfouSyncType>(
              valueListenable: _syncTypeValue,
              builder: (context, snapshot, _) {
                final syncType = snapshot;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sync Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: FanfouSyncType.values.map((type) {
                        return ChoiceChip(
                          label: Text(type.label),
                          selected: syncType == type,
                          onSelected: (selected) {
                            if (selected) {
                              _syncTypeValue.value = type;
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      await _initializeAuthorization(context);
                    },
                    child: const Text('Authorize with Fanfou'),
                  ),
            const Spacer(),
            const Text(
              'Note: You need to create a Fanfou app at fanfou.com/apps to get your Consumer Key and Secret.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeAuthorization(BuildContext context) async {
    var scaffoldMessengerState = ScaffoldMessenger.of(context);
    var navigator = Navigator.of(context);
    try {
      final consumerKey = _consumerKeyController.text.trim();
      final consumerSecret = _consumerSecretController.text.trim();

      if (consumerKey.isEmpty || consumerSecret.isEmpty) {
        Util.showError(scaffoldMessengerState, 'Please enter both Consumer Key and Consumer Secret');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      await _fanfouService.authorize(
        consumerKey,
        consumerSecret,
        _syncTypeValue.value.value,
      );

      Util.showInfo(scaffoldMessengerState, 'Authorization successful');
      navigator.pop();
    } catch (e) {
      Util.showError(scaffoldMessengerState, 'Authorization failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
