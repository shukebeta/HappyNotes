import 'package:timezone/browser.dart' as tz_web;

Future<void> initializeTimeZone() async {
  await tz_web.initializeTimeZone();
}