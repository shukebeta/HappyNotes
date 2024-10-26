import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';

import '../app_config.dart';

class Util {
  static void showError(ScaffoldMessengerState scaffoldMessengerState, String errorMessage) {
    scaffoldMessengerState.showSnackBar(SnackBar(
      content: Text(errorMessage),
      backgroundColor: Colors.orange,
    ));
  }

  static void showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void showInfo(ScaffoldMessengerState scaffoldMessengerState, String message) {
    scaffoldMessengerState.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.blue, // Optional: Set a different background color for info messages
    ));
  }

  static void showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<String?> showInputDialog(BuildContext context, String title, String hintText) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: !AppConfig.isIOSWeb,
            decoration: InputDecoration(hintText: hintText),
            onSubmitted: (value) {
              Navigator.of(context).pop(controller.text); // Submit on Enter
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  static String formatUnixTimestampToLocalDate(int unixTimestamp, String strFormat) {
    // Convert Unix timestamp (seconds since epoch) to TZDateTime
    final dateTime = DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);

    final dateFormat = DateFormat(strFormat);

    // Format the TZDateTime object to a string
    final formattedDate = dateFormat.format(dateTime);

    return formattedDate;
  }

  static String getErrorMessage(dynamic apiResult) {
    return '${apiResult['errorCode']}: ${apiResult['message']}';
  }

  static bool isPasteBoardSupported() {
    return kIsWeb ||
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }

  static bool isImageCompressionSupported() {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }

  static Future<Uint8List?> compressImage(
      Uint8List imageData,
      CompressFormat format, {
        int maxPixel = 3333,
      }) async {
    return await FlutterImageCompress.compressWithList(
      imageData,
      minWidth: maxPixel,
      minHeight: maxPixel,
      quality: 85,
      format: format,
    );
  }
}
