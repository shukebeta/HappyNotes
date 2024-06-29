import 'package:happy_notes/screens/account/user_session.dart';

import '../utils/util.dart';

class Note {
  final int id;
  final int userId;
  final String content;
  final bool isPrivate;
  final bool isLong;
  final int createAt; // You can change the type to DateTime if needed

  // yyyy-MM-dd format
  String get createDate {
    final timezone = UserSession().settings('timezone');
    return Util.formatUnixTimestampToLocalDate(createAt, 'yyyy-MM-dd', timezone);
  }
  // HH:mm formatDate
  String get createTime {
    final timezone = UserSession().settings('timezone');
    return Util.formatUnixTimestampToLocalDate(createAt, 'HH:mm', timezone);
  }

  String get formattedContent => content
      .replaceFirst(RegExp('\n{3,}'), '\n\n')
      .replaceFirst(RegExp(r'<!--\s*more\s*-->', caseSensitive: false), '');

  Note({
    required this.id,
    required this.userId,
    required this.content,
    required this.isPrivate,
    required this.isLong,
    required this.createAt,
  });
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      isPrivate: json['isPrivate'],
      isLong: json['isLong'],
      createAt: json['createAt'],
    );
  }
}
