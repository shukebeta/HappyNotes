/// Result wrapper for async operations with success/error handling
/// Used to implement optimistic updates with rollback capability
class OperationResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;

  OperationResult.success(this.data) : success = true, errorMessage = null;
  OperationResult.error(this.errorMessage) : success = false, data = null;

  // Convenience getters
  bool get isSuccess => success;
  bool get isError => !success;

  // Helper method to handle the result with callbacks
  void handle({
    required Function(T data) onSuccess,
    required Function(String error) onError,
  }) {
    if (isSuccess && data != null) {
      onSuccess(data as T);
    } else if (isError && errorMessage != null) {
      onError(errorMessage!);
    }
  }

  @override
  String toString() {
    return success
        ? 'OperationResult.success($data)'
        : 'OperationResult.error($errorMessage)';
  }
}