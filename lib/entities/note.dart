class Note {
  final int id;
  final String content;
  final bool isPrivate;
  final int createAt; // You can change the type to DateTime if needed

  Note({
    required this.id,
    required this.content,
    required this.isPrivate,
    required this.createAt,
  });
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      content: json['content'],
      isPrivate: json['isPrivate'],
      createAt: json['createAt'],
    );
  }
}
