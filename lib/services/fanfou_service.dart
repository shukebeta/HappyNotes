import 'package:happy_notes/entities/fanfou_user_account.dart';
import 'package:happy_notes/services/fanfou_user_account_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'seq_logger.dart';

class FanfouService {
  final FanfouUserAccountService _fanfouUserAccountService;

  FanfouService({required FanfouUserAccountService fanfouUserAccountService})
      : _fanfouUserAccountService = fanfouUserAccountService;

  // Fanfou has no per-instance URL: a user links a single account. The backend
  // callback persists it, so we poll getAll until it appears. Bound the wait so
  // a cancelled/abandoned authorization doesn't hang the future forever.
  static const int _maxPollAttempts = 60;
  static const Duration _pollInterval = Duration(seconds: 2);

  Future<List<FanfouUserAccount>> authorize() async {
    final authorizeUrl = await _fanfouUserAccountService.requestToken();

    final authUri = Uri.parse(authorizeUrl);
    if (await canLaunchUrl(authUri)) {
      await launchUrl(authUri);
    } else {
      throw Exception('Could not launch $authorizeUrl');
    }
    return await _waitForAuthorization();
  }

  Future<List<FanfouUserAccount>> _waitForAuthorization() async {
    for (var attempt = 0; attempt < _maxPollAttempts; attempt++) {
      final userList = await _fanfouUserAccountService.getAll();
      if (userList.isNotEmpty) {
        return userList;
      }
      SeqLogger.info('Waiting for Fanfou authorization completion');
      await Future.delayed(_pollInterval);
    }
    throw Exception('Timed out waiting for Fanfou authorization');
  }
}
