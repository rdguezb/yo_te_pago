class OdooException implements Exception {
  final String message;
  OdooException(this.message);

  @override
  String toString() => 'OdooException: $message';
}

class OdooNetworkException extends OdooException {
  OdooNetworkException(super.message);
}

class OdooApiException extends OdooException {
  OdooApiException(super.message);
}

class OdooSessionException extends OdooException {
  OdooSessionException(super.message);
}