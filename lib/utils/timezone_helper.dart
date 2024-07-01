import 'package:intl/intl.dart';

class TimezoneHelper {
  // List of timezones with their names and UTC offsets
  static const List<Map<String, String>> timezones = [
    {'name': 'UTC', 'offset': '+00:00'},
    {'name': 'Pacific/Midway', 'offset': '-11:00'},
    {'name': 'Pacific/Honolulu', 'offset': '-10:00'},
    {'name': 'America/Anchorage', 'offset': '-09:00'},
    {'name': 'America/Los_Angeles', 'offset': '-08:00'},
    {'name': 'America/Denver', 'offset': '-07:00'},
    {'name': 'America/Chicago', 'offset': '-06:00'},
    {'name': 'America/New_York', 'offset': '-05:00'},
    {'name': 'America/Caracas', 'offset': '-04:30'},
    {'name': 'America/Santiago', 'offset': '-04:00'},
    {'name': 'America/St_Johns', 'offset': '-03:30'},
    {'name': 'America/Argentina/Buenos_Aires', 'offset': '-03:00'},
    {'name': 'Atlantic/Azores', 'offset': '-01:00'},
    {'name': 'Europe/London', 'offset': '+00:00'},
    {'name': 'Europe/Berlin', 'offset': '+01:00'},
    {'name': 'Africa/Cairo', 'offset': '+02:00'},
    {'name': 'Asia/Jerusalem', 'offset': '+02:00'},
    {'name': 'Asia/Baghdad', 'offset': '+03:00'},
    {'name': 'Asia/Tehran', 'offset': '+03:30'},
    {'name': 'Asia/Dubai', 'offset': '+04:00'},
    {'name': 'Asia/Kabul', 'offset': '+04:30'},
    {'name': 'Asia/Karachi', 'offset': '+05:00'},
    {'name': 'Asia/Kolkata', 'offset': '+05:30'},
    {'name': 'Asia/Kathmandu', 'offset': '+05:45'},
    {'name': 'Asia/Dhaka', 'offset': '+06:00'},
    {'name': 'Asia/Yangon', 'offset': '+06:30'},
    {'name': 'Asia/Bangkok', 'offset': '+07:00'},
    {'name': 'Asia/Shanghai', 'offset': '+08:00'},
    {'name': 'Asia/Tokyo', 'offset': '+09:00'},
    {'name': 'Australia/Darwin', 'offset': '+09:30'},
    {'name': 'Australia/Sydney', 'offset': '+10:00'},
    {'name': 'Pacific/Guam', 'offset': '+10:00'},
    {'name': 'Pacific/Noumea', 'offset': '+11:00'},
    {'name': 'Pacific/Auckland', 'offset': '+12:00'},
    {'name': 'Pacific/Fiji', 'offset': '+12:00'},
    {'name': 'Pacific/Chatham', 'offset': '+12:45'},
    {'name': 'Pacific/Tongatapu', 'offset': '+13:00'},
    {'name': 'Pacific/Kiritimati', 'offset': '+14:00'},
  ];

  // Formats the given DateTime to the specified timezone
  static String formatDateTime(DateTime dateTime, String timezone) {
    final offset = _getTimezoneOffset(timezone);
    final dateTimeWithOffset = dateTime.toUtc().add(offset);
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTimeWithOffset);
  }

  // Returns the offset Duration for a given timezone
  static Duration _getTimezoneOffset(String timezone) {
    final timezoneInfo = timezones.firstWhere(
          (tz) => tz['name'] == timezone,
      orElse: () => {'offset': '+00:00'},
    );
    final offsetString = timezoneInfo['offset']!;
    final offsetHours = int.parse(offsetString.substring(1, 3));
    final offsetMinutes = int.parse(offsetString.substring(4, 6));
    final offsetDuration = Duration(hours: offsetHours, minutes: offsetMinutes);

    return offsetString.startsWith('-')
        ? -offsetDuration
        : offsetDuration;
  }
}
