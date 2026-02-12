enum FanfouSyncType {
  all(1, 'All'),
  publicOnly(2, 'Public only'),
  tagFanfouOnly(3, 'Tag #fanfou only');

  final int value;
  final String label;

  const FanfouSyncType(this.value, this.label);

  static FanfouSyncType fromInt(int value) {
    return FanfouSyncType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => FanfouSyncType.all,
    );
  }

  FanfouSyncType next() {
    switch (this) {
      case FanfouSyncType.all:
        return FanfouSyncType.publicOnly;
      case FanfouSyncType.publicOnly:
        return FanfouSyncType.tagFanfouOnly;
      case FanfouSyncType.tagFanfouOnly:
        return FanfouSyncType.all;
    }
  }
}
