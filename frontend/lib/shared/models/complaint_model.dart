/// Complaint model
class Complaint {
  final String id;
  final String title;
  final String description;
  final ComplaintCategory category;
  final ComplaintLocation location;
  final List<ComplaintImage> images;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final List<AuthorityMention> mentionedAuthorities;
  final String? assignedTo;
  final String reporterId;
  final String reporterName;
  final int upvoteCount;
  final int commentCount;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final bool userHasUpvoted;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.images,
    required this.status,
    required this.priority,
    required this.mentionedAuthorities,
    this.assignedTo,
    required this.reporterId,
    required this.reporterName,
    required this.upvoteCount,
    required this.commentCount,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.userHasUpvoted = false,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: ComplaintCategory.fromString(json['category'] as String),
      location: ComplaintLocation.fromJson(json['location'] as Map<String, dynamic>),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ComplaintImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: ComplaintStatus.fromString(json['status'] as String),
      priority: ComplaintPriority.fromString(json['priority'] as String),
      mentionedAuthorities: (json['mentioned_authorities'] as List<dynamic>?)
              ?.map((e) => AuthorityMention.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      assignedTo: json['assigned_to'] as String?,
      reporterId: json['reporter_id'] as String,
      reporterName: json['reporter_name'] as String,
      upvoteCount: json['upvote_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      userHasUpvoted: json['user_has_upvoted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.value,
        'location': location.toJson(),
        'images': images.map((e) => e.toJson()).toList(),
        'status': status.value,
        'priority': priority.value,
        'mentioned_authorities': mentionedAuthorities.map((e) => e.toJson()).toList(),
        'assigned_to': assignedTo,
        'reporter_id': reporterId,
        'reporter_name': reporterName,
        'upvote_count': upvoteCount,
        'comment_count': commentCount,
        'is_public': isPublic,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
        'user_has_upvoted': userHasUpvoted,
      };
}

/// Complaint location model
class ComplaintLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? landmark;
  final String? city;
  final String? state;
  final String? pincode;

  ComplaintLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.landmark,
    this.city,
    this.state,
    this.pincode,
  });

  factory ComplaintLocation.fromJson(Map<String, dynamic> json) {
    return ComplaintLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      landmark: json['landmark'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'landmark': landmark,
        'city': city,
        'state': state,
        'pincode': pincode,
      };
}

/// Complaint image model
class ComplaintImage {
  final String url;
  final String? thumbnailUrl;
  final bool isPrimary;

  ComplaintImage({
    required this.url,
    this.thumbnailUrl,
    this.isPrimary = false,
  });

  factory ComplaintImage.fromJson(Map<String, dynamic> json) {
    return ComplaintImage(
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'thumbnail_url': thumbnailUrl,
        'is_primary': isPrimary,
      };
}

/// Authority mention model
class AuthorityMention {
  final String authorityType;
  final String? userId;

  AuthorityMention({
    required this.authorityType,
    this.userId,
  });

  factory AuthorityMention.fromJson(Map<String, dynamic> json) {
    return AuthorityMention(
      authorityType: json['authority_type'] as String,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'authority_type': authorityType,
        'user_id': userId,
      };
}

/// Complaint category enum
enum ComplaintCategory {
  waterLeakage('water_leakage', 'Water Leakage'),
  streetLight('street_light', 'Street Light'),
  garbage('garbage', 'Garbage'),
  lawAndOrder('law_and_order', 'Law & Order'),
  roadDamage('road_damage', 'Road Damage'),
  drainage('drainage', 'Drainage'),
  electricity('electricity', 'Electricity'),
  sanitation('sanitation', 'Sanitation'),
  noisePollution('noise_pollution', 'Noise Pollution'),
  other('other', 'Other');

  final String value;
  final String displayName;
  const ComplaintCategory(this.value, this.displayName);

  static ComplaintCategory fromString(String value) {
    return ComplaintCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ComplaintCategory.other,
    );
  }
}

/// Complaint status enum
enum ComplaintStatus {
  pending('pending', 'Pending'),
  acknowledged('acknowledged', 'Acknowledged'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved'),
  rejected('rejected', 'Rejected'),
  escalated('escalated', 'Escalated');

  final String value;
  final String displayName;
  const ComplaintStatus(this.value, this.displayName);

  static ComplaintStatus fromString(String value) {
    return ComplaintStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ComplaintStatus.pending,
    );
  }
}

/// Complaint priority enum
enum ComplaintPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  critical('critical', 'Critical');

  final String value;
  final String displayName;
  const ComplaintPriority(this.value, this.displayName);

  static ComplaintPriority fromString(String value) {
    return ComplaintPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ComplaintPriority.medium,
    );
  }
}
