class AuthUser {
  final String id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;

  AuthUser({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        role: (json['role'] as String?) ?? 'USER',
        firstName: (json['firstName'] as String?) ?? '',
        lastName: (json['lastName'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'firstName': firstName,
        'lastName': lastName,
      };

  AuthUser copyWith({
    String? id,
    String? email,
    String? role,
    String? firstName,
    String? lastName,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}

class AuthTokens {
  final String accessToken;
  final int expiresIn;

  AuthTokens({required this.accessToken, required this.expiresIn});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        expiresIn: json['expiresIn'] as int,
      );
}

class AuthResponse {
  final AuthUser user;
  final AuthTokens tokens;

  AuthResponse({required this.user, required this.tokens});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      );
}

/// Represents an API error response from the backend
class ApiError {
  final int statusCode;
  final dynamic message; // Can be String or List<String>
  final String? error;

  ApiError({required this.statusCode, required this.message, this.error});

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        statusCode: json['statusCode'] as int,
        message: json['message'],
        error: json['error'] as String?,
      );

  /// Returns a user-friendly error message
  String get displayMessage {
    if (message is List) {
      return (message as List).join('\n');
    }
    return message.toString();
  }
}
