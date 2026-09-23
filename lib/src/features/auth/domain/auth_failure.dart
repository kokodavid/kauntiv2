enum AuthFailureKind {
  cancelled,
  configuration,
  unavailable,
  invalidCredentials,
  rejected,
  unexpected,
}

class AuthFailure {
  const AuthFailure(this.kind, this.message);

  final AuthFailureKind kind;
  final String message;
}
