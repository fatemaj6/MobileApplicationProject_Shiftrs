class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String role;           // 'caregiver', 'family', 'patient'
  final String? linkedPatientId; // for family members — links to patient uid
  final String? fcmToken;      // device push token

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.role = 'caregiver',
    this.linkedPatientId,
    this.fcmToken,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String id) {
    return UserProfile(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      role: json['role'] as String? ?? 'caregiver',
      linkedPatientId: json['linkedPatientId'] as String?,
      fcmToken: json['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'role': role,
      if (linkedPatientId != null) 'linkedPatientId': linkedPatientId,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? role,
    String? linkedPatientId,
    String? fcmToken,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      linkedPatientId: linkedPatientId ?? this.linkedPatientId,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}