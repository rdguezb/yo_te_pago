class LocalStorageException implements Exception {

  final String message;
  final StackTrace? stackTrace;
  final dynamic innerException;
  final LocalStorageErrorType errorType;

  const LocalStorageException({
    required this.message,
    this.stackTrace,
    this.innerException,
    this.errorType = LocalStorageErrorType.generic,
  });

  factory LocalStorageException.databaseError({
    required String message,
    StackTrace? stackTrace,
    dynamic innerException,
  }) => LocalStorageException(
      message: message,
      stackTrace: stackTrace,
      innerException: innerException,
      errorType: LocalStorageErrorType.database
  );

  @override
  String toString() {
    var result = 'LocalStorageException [$errorType]: $message';
    if (innerException != null) {
      result += '\nCaused by: $innerException';
    }
    if (stackTrace != null) {
      result += '\n$stackTrace';
    }
    return result;
  }

}

enum LocalStorageErrorType {
  generic,
  database,
  notFound,
  validation,
  io,
  serialization
}