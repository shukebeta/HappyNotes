import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Util {
  static void showError(ScaffoldMessengerState scaffoldContext, String errorMessage) {
    scaffoldContext.showSnackBar(SnackBar(
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

  static void showInfo(ScaffoldMessengerState scaffoldContext, String message) {
    scaffoldContext.showSnackBar(SnackBar(
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
            decoration: InputDecoration(hintText: hintText),
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
  static String formatUnixTimestampToLocalDate(int unixTimestamp, String strFormat, String timeZone) {

    // Convert Unix timestamp (seconds since epoch) to TZDateTime
    final dateTime = DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);

    // Create a DateFormat for 'yyyyMMdd'
    final dateFormat = DateFormat(strFormat);

    // Format the TZDateTime object to a string
    final formattedDate = dateFormat.format(dateTime);

    return formattedDate;
  }

  static String getErrorMessage(dynamic apiResult) {
    return apiResult['errorCode'] + ': ' + apiResult['message'];
  }
}
