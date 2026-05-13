class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String id) {
    return UserProfile(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
