class CustomException implements Exception {
  final String message;
  CustomException(this.message); // Pass your message in constructor.

  @override
  String toString() {
    return message;
  }
}
