part of 'complaints_bloc.dart';

abstract class ComplaintsEvent extends Equatable {
  const ComplaintsEvent();

  @override
  List<Object?> get props => [];
}

class ComplaintsLoad extends ComplaintsEvent {
  final int page;
  final String? category;
  final String? status;

  const ComplaintsLoad({
    this.page = 1,
    this.category,
    this.status,
  });

  @override
  List<Object?> get props => [page, category, status];
}

class ComplaintsLoadNearby extends ComplaintsEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final int page;

  const ComplaintsLoadNearby({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
    this.page = 1,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm, page];
}

class ComplaintsLoadMy extends ComplaintsEvent {
  final int page;
  final String? status;

  const ComplaintsLoadMy({
    this.page = 1,
    this.status,
  });

  @override
  List<Object?> get props => [page, status];
}

class ComplaintsLoadDetail extends ComplaintsEvent {
  final String id;

  const ComplaintsLoadDetail(this.id);

  @override
  List<Object?> get props => [id];
}

class ComplaintsCreate extends ComplaintsEvent {
  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final String? address;
  final String? landmark;
  final String? city;
  final String? state;
  final String? pincode;
  final List<String>? mentionedAuthorities;
  final List<String>? imagePaths;

  const ComplaintsCreate({
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
    this.landmark,
    this.city,
    this.state,
    this.pincode,
    this.mentionedAuthorities,
    this.imagePaths,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        category,
        latitude,
        longitude,
        address,
        landmark,
        city,
        state,
        pincode,
        mentionedAuthorities,
        imagePaths,
      ];
}

class ComplaintsToggleUpvote extends ComplaintsEvent {
  final String id;

  const ComplaintsToggleUpvote(this.id);

  @override
  List<Object?> get props => [id];
}

class ComplaintsAddComment extends ComplaintsEvent {
  final String complaintId;
  final String content;

  const ComplaintsAddComment({
    required this.complaintId,
    required this.content,
  });

  @override
  List<Object?> get props => [complaintId, content];
}
