// lib/features/auth/data/auth_service.dart

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/auth_models.dart';

class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _teacherIdBucket = 'teacher-ids';

  // ------------------------------------------------------------------ state

  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ------------------------------------------------------------------ sign up

  /// Creates the account. The `data` map is written to
  /// `auth.users.raw_user_meta_data`, which the `handle_new_user` trigger
  /// reads to build the matching row in `public.profiles`.
  ///
  /// Role-specific arguments are ignored when they do not apply, so the
  /// caller can pass whatever the form collected.
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required UserRole role,
    required String firstName,
    required String lastName,
    String? middleName,
    // student + teacher
    String? schoolId,
    String? schoolNameRaw,
    // student
    String? studentNumber,
    String? gradeLevel,
    // teacher
    String? prcLicenseNo,
    String? employeeId,
    String? designation,
    String? subjectTaught,
  }) async {
    final metadata = <String, dynamic>{
      'role': role.dbValue,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      if (_notBlank(middleName)) 'middle_name': middleName!.trim(),
    };

    if (role == UserRole.student || role == UserRole.teacher) {
      if (_notBlank(schoolId)) metadata['school_id'] = schoolId;
      if (_notBlank(schoolNameRaw)) {
        metadata['school_name_raw'] = schoolNameRaw!.trim();
      }
    }

    if (role == UserRole.student) {
      if (_notBlank(studentNumber)) {
        metadata['student_number'] = studentNumber!.trim();
      }
      if (_notBlank(gradeLevel)) metadata['grade_level'] = gradeLevel!.trim();
    }

    if (role == UserRole.teacher) {
      if (_notBlank(prcLicenseNo)) {
        metadata['prc_license_no'] = prcLicenseNo!.trim();
      }
      if (_notBlank(employeeId)) metadata['employee_id'] = employeeId!.trim();
      if (_notBlank(designation)) metadata['designation'] = designation!.trim();
      if (_notBlank(subjectTaught)) {
        metadata['subject_taught'] = subjectTaught!.trim();
      }
    }

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: metadata,
      );

      // With "Confirm email" enabled, session is null until the user
      // clicks the link in their inbox.
      return SignUpResult(
        needsEmailConfirmation: response.session == null,
        role: role,
        userId: response.user?.id,
      );
    } on AuthException catch (e) {
      throw AuthFailure(_mapSignUpError(e));
    } catch (_) {
      throw const AuthFailure(
        'Could not create your account. Please check your connection and try again.',
      );
    }
  }

  // ------------------------------------------------------------------ sign in

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(_mapSignInError(e));
    } catch (_) {
      throw const AuthFailure(
        'Could not log you in. Please check your connection and try again.',
      );
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email.trim());
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  // ------------------------------------------------------------------ profile

  /// Reads the signed-in user's profile row. Returns null when there is no
  /// session, or when the trigger has not finished writing the row yet.
  Future<AppProfile?> fetchMyProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;

    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (row == null) return null;
      return AppProfile.fromMap(row);
    } on PostgrestException catch (e) {
      throw AuthFailure('Could not load your profile. ${e.message}');
    }
  }

  /// Updates the editable columns only. `role` and `teacher_status` are
  /// blocked at the database level, so attempting them here fails.
  Future<void> updateMyProfile(Map<String, dynamic> changes) async {
    final uid = currentUser?.id;
    if (uid == null) throw const AuthFailure('You are not signed in.');

    try {
      await _client.from('profiles').update(changes).eq('id', uid);
    } on PostgrestException catch (e) {
      throw AuthFailure('Could not save your changes. ${e.message}');
    }
  }

  // ------------------------------------------------- teacher verification

  /// Uploads a faculty ID into the private `teacher-ids` bucket and records
  /// the path against the pending verification row.
  ///
  /// Call this AFTER the teacher has confirmed their email and signed in —
  /// the storage policy keys on `auth.uid()`, so there must be a session.
  Future<void> uploadTeacherId(File image) async {
    final uid = currentUser?.id;
    if (uid == null) throw const AuthFailure('You are not signed in.');

    final ext = image.path.split('.').last.toLowerCase();
    final path = '$uid/faculty-id-${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await _client.storage
          .from(_teacherIdBucket)
          .upload(
            path,
            image,
            fileOptions: const FileOptions(upsert: false),
          );

      await _client
          .from('teacher_verifications')
          .update({'id_document_path': path, 'method': 'faculty_id'})
          .eq('profile_id', uid)
          .eq('status', 'pending');
    } on StorageException catch (e) {
      throw AuthFailure('Could not upload your ID. ${e.message}');
    } on PostgrestException catch (e) {
      throw AuthFailure('Could not record your submission. ${e.message}');
    }
  }

  /// Current verification state, for the "pending approval" banner.
  Future<VerificationStatus> fetchTeacherStatus() async {
    final profile = await fetchMyProfile();
    return profile?.teacherStatus ?? VerificationStatus.none;
  }

  // ------------------------------------------------------------------ helpers

  bool _notBlank(String? v) => v != null && v.trim().isNotEmpty;

  String _mapSignUpError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('already been registered') ||
        msg.contains('user already exists')) {
      return 'That email is already registered. Try logging in instead.';
    }
    if (msg.contains('password')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('invalid email') || msg.contains('email address')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'Could not create your account. ${e.message}';
  }

  String _mapSignInError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
      return 'Please confirm your email first. Check your inbox for the link.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'Could not log you in. ${e.message}';
  }
}