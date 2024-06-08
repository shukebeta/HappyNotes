class Note {
  final int id;
  final String content;
  final bool isPrivate;
  final bool isLong;
  final int createAt; // You can change the type to DateTime if needed
  String? createDate; // yyyy-MM-dd format
  String? createTime; // HH:mm format

  String get formattedContent => content
      .replaceFirst(RegExp('\n{3,}'), '\n\n')
      .replaceFirst(RegExp(r'<!--\s*more\s*-->', caseSensitive: false), '');

  Note({
    required this.id,
    required this.content,
    required this.isPrivate,
    required this.isLong,
    required this.createAt,
    this.createDate,
    this.createTime
  });
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      content: json['content'],
      isPrivate: json['isPrivate'],
      isLong: json['isLong'],
      createAt: json['createAt'],
    );
  }
}
