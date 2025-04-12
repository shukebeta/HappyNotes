import '../utils/util.dart';
import 'user.dart'; // Assuming User class is defined in user.dart

class Note {
  final int id;
  final int userId;
  final String content;
  final bool isPrivate;
  final bool isLong;
  final bool isMarkdown;
  final int createdAt;
  final int? deletedAt;

  User? user;
  List<String>? tags;

  String get createdDate => Util.formatUnixTimestampToLocalDate(createdAt, 'yyyy-MM-dd');
  String get createdTime => Util.formatUnixTimestampToLocalDate(createdAt, 'HH:mm');

  String get formattedContent => content
      .replaceFirst(RegExp('\n{3,}'), '\n\n')
      .replaceFirst(RegExp(r'<!--\s*more\s*-->', caseSensitive: false), '');

  bool get isDeleted => deletedAt != null;

  String? get deletedDate => deletedAt != null 
    ? Util.formatUnixTimestampToLocalDate(deletedAt!, 'yyyy-MM-dd HH:mm') 
    : null;

  Note({
    required this.id,
    required this.userId,
    required this.content,
    required this.isPrivate,
    required this.isLong,
    required this.isMarkdown,
    required this.createdAt,
    this.deletedAt,
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
      deletedAt: json['deletedAt'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      tags: json['tags'] == '' || json['tags'] == null ? [] : json['tags'].split(' '),
    );
  }
}
