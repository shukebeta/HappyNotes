/// Interface for application logging
/// 
/// This abstraction allows for easy mocking in tests and different
/// implementations for different environments.
abstract class AppLoggerInterface {
  void i(String message);
  void d(String message);
  void e(String message);
  Future<void> initialize();
}