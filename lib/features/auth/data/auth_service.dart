import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

/// Wraps all Supabase Auth calls. Screens never call Supabase directly —
/// they call this service. Keeps auth logic in one testable place.
class AuthService {
  final SupabaseClient _client = SupabaseService.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String middleName, // pwedeng blangko — optional field
    required String lastName,
    required String role,
  }) async {
    // Compose the full name, skipping middleName if it's empty.
    final fullName = [firstName, middleName, lastName]
        .where((part) => part.trim().isNotEmpty)
        .join(' ');

    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'full_name': fullName,
        'role': role,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}