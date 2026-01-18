import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/community_repository.dart';

part 'community_event.dart';
part 'community_state.dart';

/// Community BLoC
class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _repository;

  CommunityBloc({required CommunityRepository repository})
      : _repository = repository,
        super(CommunityInitial()) {
    on<CommunityLoadPosts>(_onLoadPosts);
    on<CommunityLoadFeed>(_onLoadFeed);
    on<CommunityCreatePost>(_onCreatePost);
    on<CommunityToggleLike>(_onToggleLike);
    on<CommunityVotePoll>(_onVotePoll);
    on<CommunityFollowUser>(_onFollowUser);
    on<CommunityUnfollowUser>(_onUnfollowUser);
  }

  Future<void> _onLoadPosts(
    CommunityLoadPosts event,
    Emitter<CommunityState> emit,
  ) async {
    emit(CommunityLoading());
    try {
      final response = await _repository.getPosts(
        page: event.page,
        postType: event.postType,
        tag: event.tag,
      );
      emit(CommunityPostsLoaded(
        posts: (response['posts'] as List<dynamic>).cast<Map<String, dynamic>>(),
        total: response['total'] as int,
        page: response['page'] as int,
      ));
    } catch (e) {
      emit(CommunityError('Failed to load posts'));
    }
  }

  Future<void> _onLoadFeed(
    CommunityLoadFeed event,
    Emitter<CommunityState> emit,
  ) async {
    emit(CommunityLoading());
    try {
      final response = await _repository.getFeed(page: event.page);
      emit(CommunityPostsLoaded(
        posts: (response['posts'] as List<dynamic>).cast<Map<String, dynamic>>(),
        total: response['total'] as int,
        page: response['page'] as int,
      ));
    } catch (e) {
      emit(CommunityError('Failed to load feed'));
    }
  }

  Future<void> _onCreatePost(
    CommunityCreatePost event,
    Emitter<CommunityState> emit,
  ) async {
    emit(CommunitySubmitting());
    try {
      await _repository.createPost(
        content: event.content,
        postType: event.postType,
        visibility: event.visibility,
        tags: event.tags,
        mentions: event.mentions,
        pollOptions: event.pollOptions,
        pollDurationHours: event.pollDurationHours,
      );
      emit(CommunityPostCreated());
    } catch (e) {
      emit(CommunityError('Failed to create post'));
    }
  }

  Future<void> _onToggleLike(
    CommunityToggleLike event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _repository.toggleLike(event.postId);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _onVotePoll(
    CommunityVotePoll event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _repository.votePoll(event.postId, event.optionId);
    } catch (e) {
      emit(CommunityError('Failed to vote'));
    }
  }

  Future<void> _onFollowUser(
    CommunityFollowUser event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _repository.followUser(event.userId);
    } catch (e) {
      emit(CommunityError('Failed to follow user'));
    }
  }

  Future<void> _onUnfollowUser(
    CommunityUnfollowUser event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _repository.unfollowUser(event.userId);
    } catch (e) {
      emit(CommunityError('Failed to unfollow user'));
    }
  }
}
