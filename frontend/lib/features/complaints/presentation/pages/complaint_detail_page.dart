import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/complaints_bloc.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/models/complaint_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/injection.dart';

/// Complaint detail page
class ComplaintDetailPage extends StatelessWidget {
  final String complaintId;

  const ComplaintDetailPage({
    super.key,
    required this.complaintId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ComplaintsBloc>()..add(ComplaintsLoadDetail(complaintId)),
      child: Scaffold(
        body: BlocBuilder<ComplaintsBloc, ComplaintsState>(
          builder: (context, state) {
            if (state is ComplaintsLoading) {
              return const LoadingIndicator();
            }

            if (state is ComplaintDetailLoaded) {
              return _ComplaintDetailView(complaint: state.complaint);
            }

            if (state is ComplaintsError) {
              return ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<ComplaintsBloc>().add(ComplaintsLoadDetail(complaintId));
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ComplaintDetailView extends StatelessWidget {
  final Complaint complaint;

  const _ComplaintDetailView({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App bar with images
        SliverAppBar(
          expandedHeight: complaint.images.isNotEmpty ? 250 : 0,
          pinned: true,
          flexibleSpace: complaint.images.isNotEmpty
              ? FlexibleSpaceBar(
                  background: PageView.builder(
                    itemCount: complaint.images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        complaint.images[index].url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      );
                    },
                  ),
                )
              : null,
          title: Text(
            complaint.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and category
                Row(
                  children: [
                    StatusChip(
                      label: complaint.status.displayName,
                      color: _getStatusColor(complaint.status),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      label: complaint.category.displayName,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      label: complaint.priority.displayName,
                      color: _getPriorityColor(complaint.priority),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(complaint.description),

                const SizedBox(height: 16),

                // Location
                if (complaint.location.address != null) ...[
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(complaint.location.address!),
                      subtitle: complaint.location.landmark != null
                          ? Text('Near: ${complaint.location.landmark}')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tagged authorities
                if (complaint.mentionedAuthorities.isNotEmpty) ...[
                  Text(
                    'Tagged Authorities',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: complaint.mentionedAuthorities
                        .map((a) => Chip(
                              label: Text('@${a.authorityType}'),
                              avatar: const Icon(Icons.person, size: 18),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Reporter info
                Text(
                  'Reported by',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: UserAvatar(name: complaint.reporterName),
                  title: Text(complaint.reporterName),
                  subtitle: Text(_formatDate(complaint.createdAt)),
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<ComplaintsBloc>().add(
                                ComplaintsToggleUpvote(complaint.id),
                              );
                        },
                        icon: Icon(
                          complaint.userHasUpvoted
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                        ),
                        label: Text('${complaint.upvoteCount}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showCommentSheet(context);
                        },
                        icon: const Icon(Icons.comment_outlined),
                        label: Text('${complaint.commentCount}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Share functionality
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return AppColors.pending;
      case ComplaintStatus.inProgress:
      case ComplaintStatus.acknowledged:
        return AppColors.inProgress;
      case ComplaintStatus.resolved:
        return AppColors.resolved;
      case ComplaintStatus.rejected:
        return AppColors.rejected;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getPriorityColor(ComplaintPriority priority) {
    switch (priority) {
      case ComplaintPriority.critical:
        return AppColors.error;
      case ComplaintPriority.high:
        return AppColors.warning;
      case ComplaintPriority.medium:
        return AppColors.info;
      case ComplaintPriority.low:
        return AppColors.success;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCommentSheet(BuildContext context) {
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Comment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write your comment...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      context.read<ComplaintsBloc>().add(
                            ComplaintsAddComment(
                              complaintId: complaint.id,
                              content: controller.text.trim(),
                            ),
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Post Comment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
