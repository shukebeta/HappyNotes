class Note {
  final int id;
  final String content;
  final bool isPrivate;
  final int createdAt; // You can change the type to DateTime if needed

  Note({
    required this.id,
    required this.content,
    required this.isPrivate,
    required this.createdAt,
  });
}
