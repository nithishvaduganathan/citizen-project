import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/community_bloc.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/injection.dart';

/// Community page
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CommunityBloc>()..add(const CommunityLoadFeed()),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Community'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Feed'),
                Tab(text: 'Discover'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _FeedTab(),
              _DiscoverTab(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/community/create'),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state is CommunityLoading) {
          return const LoadingIndicator(message: 'Loading feed...');
        }

        if (state is CommunityPostsLoaded) {
          if (state.posts.isEmpty) {
            return EmptyStateView(
              icon: Icons.people_outline,
              title: 'No posts yet',
              subtitle: 'Follow users or create a post to see updates here',
              action: ElevatedButton.icon(
                onPressed: () => context.push('/community/create'),
                icon: const Icon(Icons.add),
                label: const Text('Create Post'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CommunityBloc>().add(const CommunityLoadFeed());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.posts.length,
              itemBuilder: (context, index) {
                return _PostCard(post: state.posts[index]);
              },
            ),
          );
        }

        if (state is CommunityError) {
          return ErrorView(
            message: state.message,
            onRetry: () {
              context.read<CommunityBloc>().add(const CommunityLoadFeed());
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _DiscoverTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<CommunityBloc>().add(const CommunityLoadPosts());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trending Topics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '#CivicIssues',
                    '#LocalGovernment',
                    '#RoadSafety',
                    '#CleanIndia',
                    '#SmartCity',
                  ]
                      .map((tag) => ActionChip(
                            label: Text(tag),
                            onPressed: () {
                              context.read<CommunityBloc>().add(
                                    CommunityLoadPosts(tag: tag.substring(1)),
                                  );
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Suggested Users',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const EmptyStateView(
                  icon: Icons.person_search,
                  title: 'Coming soon',
                  subtitle: 'User suggestions will appear here',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author header
            Row(
              children: [
                UserAvatar(
                  name: post['author_name'] as String? ?? 'User',
                  imageUrl: post['author_avatar'] as String?,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author_name'] as String? ?? 'User',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _formatDate(post['created_at'] as String?),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            Text(post['content'] as String? ?? ''),

            // Tags
            if (post['tags'] != null && (post['tags'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: (post['tags'] as List)
                    .map((tag) => Text(
                          '#$tag',
                          style: TextStyle(color: AppColors.primary),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    context.read<CommunityBloc>().add(
                          CommunityToggleLike(post['id'] as String),
                        );
                  },
                  icon: Icon(
                    (post['user_has_liked'] as bool? ?? false)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 20,
                  ),
                  label: Text('${post['like_count'] ?? 0}'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.comment_outlined, size: 20),
                  label: Text('${post['comment_count'] ?? 0}'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inMinutes}m ago';
      }
    } catch (e) {
      return '';
    }
  }
}
