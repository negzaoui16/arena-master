import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import 'storage_service.dart';

class ApiService {
  // ── Change this to match your environment ──
  // Android emulator: http://10.0.2.2:3000
  // iOS simulator:    http://localhost:3000
  // Physical device:  http://<YOUR_IP>:3000
  static const String baseUrl = 'http://192.168.100.7:3000';

  final StorageService _storage = StorageService();

  // ─────────────────── AUTH ───────────────────

  /// Sign up a new user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );

    if (response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _storage.saveToken(authResponse.tokens.accessToken);
      await _storage.saveUser(authResponse.user);
      return authResponse;
    } else {
      throw _handleError(response);
    }
  }

  /// Sign in an existing user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _storage.saveToken(authResponse.tokens.accessToken);
      await _storage.saveUser(authResponse.user);
      return authResponse;
    } else {
      throw _handleError(response);
    }
  }

  /// Verify email with 6-digit code
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  /// Resend verification code
  Future<void> resendVerification({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  /// Get current user profile (protected)
  Future<AuthUser> getMe() async {
    final token = await _storage.getToken();
    if (token == null) throw ApiError(statusCode: 401, message: 'Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final user = AuthUser.fromJson(jsonDecode(response.body));
      await _storage.saveUser(user);
      return user;
    } else if (response.statusCode == 401) {
      await _storage.clearAll();
      throw ApiError(statusCode: 401, message: 'Session expired');
    } else {
      throw _handleError(response);
    }
  }

  /// Update user profile (protected)
  Future<AuthUser> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    final token = await _storage.getToken();
    if (token == null) throw ApiError(statusCode: 401, message: 'Not authenticated');

    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (email != null) body['email'] = email;

    final response = await http.patch(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final user = AuthUser.fromJson(jsonDecode(response.body));
      await _storage.saveUser(user);
      return user;
    } else if (response.statusCode == 401) {
      await _storage.clearAll();
      throw ApiError(statusCode: 401, message: 'Session expired');
    } else {
      throw _handleError(response);
    }
  }

  /// Sign out (clears local storage)
  Future<void> signOut() async {
    await _storage.clearAll();
  }

  // ─────────────────── HELPERS ───────────────────

  ApiError _handleError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return ApiError.fromJson(body);
    } catch (_) {
      return ApiError(
        statusCode: response.statusCode,
        message: 'An unexpected error occurred',
      );
    }
  }
}
