/// User model
class User {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final UserRole role;
  final UserProfile profile;
  final bool isActive;
  final bool isVerified;
  final String? authorityType;
  final bool authorityVerified;
  final int followersCount;
  final int followingCount;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    required this.role,
    required this.profile,
    required this.isActive,
    required this.isVerified,
    this.authorityType,
    this.authorityVerified = false,
    this.followersCount = 0,
    this.followingCount = 0,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      role: UserRole.fromString(json['role'] as String),
      profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      isActive: json['is_active'] as bool,
      isVerified: json['is_verified'] as bool,
      authorityType: json['authority_type'] as String?,
      authorityVerified: json['authority_verified'] as bool? ?? false,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'username': username,
        'role': role.value,
        'profile': profile.toJson(),
        'is_active': isActive,
        'is_verified': isVerified,
        'authority_type': authorityType,
        'authority_verified': authorityVerified,
        'followers_count': followersCount,
        'following_count': followingCount,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isAdmin => role == UserRole.admin;
  bool get isAuthority => role == UserRole.authority;
  bool get isCitizen => role == UserRole.citizen;
}

/// User profile model
class UserProfile {
  final String? phone;
  final String? bio;
  final String? avatarUrl;
  final String preferredLanguage;
  final Location? location;

  UserProfile({
    this.phone,
    this.bio,
    this.avatarUrl,
    this.preferredLanguage = 'en',
    this.location,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      location: json['location'] != null
          ? Location.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'bio': bio,
        'avatar_url': avatarUrl,
        'preferred_language': preferredLanguage,
        'location': location?.toJson(),
      };
}

/// Location model
class Location {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String country;
  final String? pincode;

  Location({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.country = 'India',
    this.pincode,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String? ?? 'India',
      pincode: json['pincode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
      };
}

/// User role enum
enum UserRole {
  citizen('citizen'),
  authority('authority'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.citizen,
    );
  }
}
