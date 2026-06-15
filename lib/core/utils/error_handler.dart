class ErrorHandler {
  static String getReadableError(dynamic error) {
    // If it's already a clean string, return it
    final String errorString = error.toString().toLowerCase();

    // Mapping for common technical signatures
    if (errorString.contains('invalid login credentials') || 
        errorString.contains('invalid_credentials')) {
      return "Incorrect email or password. Please try again.";
    }

    if (errorString.contains('user already registered') || 
        errorString.contains('already exists')) {
      return "An account with this email already exists.";
    }

    if (errorString.contains('email not confirmed') || 
        errorString.contains('email_not_confirmed')) {
      return "Please verify your email address before signing in.";
    }

    if (errorString.contains('socketexception') || 
        errorString.contains('failed host lookup') || 
        errorString.contains('connection refused') ||
        errorString.contains('network_error')) {
      return "Unable to connect to our servers. Please check your internet connection and try again.";
    }

    if (errorString.contains('cancelled')) {
      return "Sign-in was cancelled.";
    }

    if (errorString.contains('password is too short')) {
      return "Your password must be at least 6 characters long.";
    }

    if (errorString.contains('invalid email')) {
      return "The email address provided is not valid.";
    }

    // Generic fallback for any other technical string
    if (errorString.contains('authapiexception') || 
        errorString.contains('exception') || 
        errorString.contains('error')) {
      return "An error occurred during authentication. Please try again.";
    }

    return "An unexpected error occurred. Please try again.";
  }
}
