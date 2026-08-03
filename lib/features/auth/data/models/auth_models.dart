// lib/features/auth/data/models/auth_models.dart

/// Mirrors the `user_role` enum in Postgres.
enum UserRole {
  commuter,
  student,
  teacher;

  String get dbValue => name;

  static UserRole fromDb(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.commuter,
    );
  }

  String get label => switch (this) {
    UserRole.commuter => 'Commuter',
    UserRole.student => 'Student',
    UserRole.teacher => 'Teacher',
  };

  String get description => switch (this) {
    UserRole.commuter => 'Browse transit routes, fares, and heritage sites.',
    UserRole.student => 'Join field trips organised by your teacher.',
    UserRole.teacher => 'Create and supervise class field trips.',
  };
}

/// Mirrors the `verification_status` enum in Postgres.
enum VerificationStatus {
  none,
  pending,
  approved,
  rejected;

  static VerificationStatus fromDb(String? value) {
    return VerificationStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => VerificationStatus.none,
    );
  }

  bool get isApproved => this == VerificationStatus.approved;
  bool get isPending => this == VerificationStatus.pending;
  bool get isRejected => this == VerificationStatus.rejected;
}

/// A row from `public.schools`.
class School {
  const School({
    required this.id,
    required this.name,
    this.externalCode,
    this.level,
    this.sector,
    this.municipality,
    this.province,
  });

  final String id;
  final String name;
  final String? externalCode;
  final String? level;
  final String? sector;
  final String? municipality;
  final String? province;

  /// "Malolos City · Public" — shown under the school name in the picker.
  String get subtitle {
    final parts = <String>[
      if (municipality != null && municipality!.isNotEmpty) municipality!,
      if (sector != null && sector!.isNotEmpty) sector!,
    ];
    return parts.join(' · ');
  }

  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
      externalCode: map['external_code'] as String?,
      level: map['level'] as String?,
      sector: map['sector'] as String?,
      municipality: map['municipality'] as String?,
      province: map['province'] as String?,
    );
  }
}

/// A row from `public.profiles`.
class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.teacherStatus,
    this.middleName,
    this.schoolId,
    this.schoolNameRaw,
    this.studentNumber,
    this.gradeLevel,
    this.prcLicenseNo,
    this.employeeId,
    this.designation,
    this.subjectTaught,
  });

  final String id;
  final String email;
  final UserRole role;
  final String firstName;
  final String? middleName;
  final String lastName;
  final VerificationStatus teacherStatus;

  final String? schoolId;
  final String? schoolNameRaw;
  final String? studentNumber;
  final String? gradeLevel;
  final String? prcLicenseNo;
  final String? employeeId;
  final String? designation;
  final String? subjectTaught;

  String get fullName => [
    firstName,
    if (middleName != null && middleName!.isNotEmpty) middleName!,
    lastName,
  ].join(' ');

  /// Only an approved teacher may create a field trip lobby.
  bool get canHostFieldTrip =>
      role == UserRole.teacher && teacherStatus.isApproved;

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    return AppProfile(
      id: map['id'] as String,
      email: (map['email'] ?? '') as String,
      role: UserRole.fromDb(map['role'] as String?),
      firstName: (map['first_name'] ?? '') as String,
      middleName: map['middle_name'] as String?,
      lastName: (map['last_name'] ?? '') as String,
      teacherStatus: VerificationStatus.fromDb(map['teacher_status'] as String?),
      schoolId: map['school_id'] as String?,
      schoolNameRaw: map['school_name_raw'] as String?,
      studentNumber: map['student_number'] as String?,
      gradeLevel: map['grade_level'] as String?,
      prcLicenseNo: map['prc_license_no'] as String?,
      employeeId: map['employee_id'] as String?,
      designation: map['designation'] as String?,
      subjectTaught: map['subject_taught'] as String?,
    );
  }
}

/// Outcome of a sign-up attempt, so the UI knows what to show next.
class SignUpResult {
  const SignUpResult({
    required this.needsEmailConfirmation,
    required this.role,
    this.userId,
  });

  final bool needsEmailConfirmation;
  final UserRole role;
  final String? userId;

  /// Teachers who did not sign up with a DepEd mailbox wait for an admin.
  bool get awaitsAdminApproval => role == UserRole.teacher;
}

/// Thrown by the services so the UI can show a clean message.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}