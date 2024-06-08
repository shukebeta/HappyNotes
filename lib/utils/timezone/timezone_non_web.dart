import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz_data;
Future<void> initializeTimeZone() async {
  if (!kIsWeb) {
    tz_data.initializeTimeZones();
  } else {
    throw UnsupportedError('This platform is not supported for timezone initialization');
  }
}