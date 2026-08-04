import 'package:flutter_test/flutter_test.dart';
import 'package:happy_notes/entities/fanfou_user_account.dart';

void main() {
  group('FanfouUserAccount', () {
    test('fromJson maps all fields', () {
      final account = FanfouUserAccount.fromJson({
        'id': 7,
        'userId': 42,
        'syncType': 2,
        'status': 1,
        'fanfouUserId': 'happy_user',
        'statusText': 'Normal',
      });

      expect(account.id, 7);
      expect(account.userId, 42);
      expect(account.syncType, 2);
      expect(account.status, 1);
      expect(account.fanfouUserId, 'happy_user');
      expect(account.statusText, 'Normal');
    });

    test('syncTypeText reflects the sync rule', () {
      FanfouUserAccount withSyncType(int syncType) =>
          FanfouUserAccount(syncType: syncType, statusText: 'Normal');

      expect(withSyncType(1).syncTypeText, 'All');
      expect(withSyncType(2).syncTypeText, 'Public note only');
      expect(withSyncType(3).syncTypeText, 'Note with tag Fanfou only');
      expect(withSyncType(99).syncTypeText, 'Unknown');
    });

    test('isActive / isDisabled derive from statusText', () {
      expect(FanfouUserAccount(syncType: 1, statusText: 'Normal').isActive, isTrue);
      expect(FanfouUserAccount(syncType: 1, statusText: 'Normal').isDisabled, isFalse);

      expect(FanfouUserAccount(syncType: 1, statusText: 'Disabled').isDisabled, isTrue);
      expect(FanfouUserAccount(syncType: 1, statusText: 'Disabled').isActive, isFalse);

      // 'Inactive' substring counts as disabled, matching the Mastodon logic.
      expect(FanfouUserAccount(syncType: 1, statusText: 'Inactive').isDisabled, isTrue);
    });
  });
}
