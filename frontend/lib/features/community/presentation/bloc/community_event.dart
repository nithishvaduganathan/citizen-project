part of 'community_bloc.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class CommunityLoadPosts extends CommunityEvent {
  final int page;
  final String? postType;
  final String? tag;

  const CommunityLoadPosts({
    this.page = 1,
    this.postType,
    this.tag,
  });

  @override
  List<Object?> get props => [page, postType, tag];
}

class CommunityLoadFeed extends CommunityEvent {
  final int page;

  const CommunityLoadFeed({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class CommunityCreatePost extends CommunityEvent {
  final String content;
  final String postType;
  final String visibility;
  final List<String>? tags;
  final List<String>? mentions;
  final List<String>? pollOptions;
  final int? pollDurationHours;

  const CommunityCreatePost({
    required this.content,
    this.postType = 'update',
    this.visibility = 'public',
    this.tags,
    this.mentions,
    this.pollOptions,
    this.pollDurationHours,
  });

  @override
  List<Object?> get props => [
        content,
        postType,
        visibility,
        tags,
        mentions,
        pollOptions,
        pollDurationHours,
      ];
}

class CommunityToggleLike extends CommunityEvent {
  final String postId;

  const CommunityToggleLike(this.postId);

  @override
  List<Object?> get props => [postId];
}

class CommunityVotePoll extends CommunityEvent {
  final String postId;
  final String optionId;

  const CommunityVotePoll({
    required this.postId,
    required this.optionId,
  });

  @override
  List<Object?> get props => [postId, optionId];
}

class CommunityFollowUser extends CommunityEvent {
  final String userId;

  const CommunityFollowUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CommunityUnfollowUser extends CommunityEvent {
  final String userId;

  const CommunityUnfollowUser(this.userId);

  @override
  List<Object?> get props => [userId];
}
