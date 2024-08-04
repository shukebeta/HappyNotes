import '../utils/util.dart';
import 'user.dart'; // Assuming User class is defined in user.dart

class Note {
  final int id;
  final int userId;
  final String content;
  final bool isPrivate;
  final bool isLong;
  final bool isMarkdown;
  final int createdAt; // You can change the type to DateTime if needed

  User? user; // Adding User property
  List<String>? tags;

  // yyyy-MM-dd format
  String get createdDate => Util.formatUnixTimestampToLocalDate(createdAt, 'yyyy-MM-dd');

  // HH:mm format
  String get createdTime => Util.formatUnixTimestampToLocalDate(createdAt, 'HH:mm');

  String get formattedContent => content
      .replaceFirst(RegExp('\n{3,}'), '\n\n')
      .replaceFirst(RegExp(r'<!--\s*more\s*-->', caseSensitive: false), '');

  Note({
    required this.id,
    required this.userId,
    required this.content,
    required this.isPrivate,
    required this.isLong,
    required this.isMarkdown,
    required this.createdAt,
    this.user,
    this.tags,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      isPrivate: json['isPrivate'],
      isLong: json['isLong'],
      isMarkdown: json['isMarkdown'],
      createdAt: json['createdAt'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      // Parsing User object from JSON
      tags: json['tags'] == '' || json['tags'] == null ? [] : json['tags'].split(' '),
    );
  }
}
