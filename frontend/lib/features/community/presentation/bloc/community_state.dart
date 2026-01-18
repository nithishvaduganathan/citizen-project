part of 'community_bloc.dart';

abstract class CommunityState extends Equatable {
  const CommunityState();

  @override
  List<Object?> get props => [];
}

class CommunityInitial extends CommunityState {}

class CommunityLoading extends CommunityState {}

class CommunitySubmitting extends CommunityState {}

class CommunityPostCreated extends CommunityState {}

class CommunityPostsLoaded extends CommunityState {
  final List<Map<String, dynamic>> posts;
  final int total;
  final int page;

  const CommunityPostsLoaded({
    required this.posts,
    required this.total,
    required this.page,
  });

  @override
  List<Object?> get props => [posts, total, page];
}

class CommunityError extends CommunityState {
  final String message;

  const CommunityError(this.message);

  @override
  List<Object?> get props => [message];
}
