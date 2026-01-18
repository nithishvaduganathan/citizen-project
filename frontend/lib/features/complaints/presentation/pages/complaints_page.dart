import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/complaints_bloc.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/models/complaint_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/injection.dart';

/// Complaints list page
class ComplaintsPage extends StatelessWidget {
  const ComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ComplaintsBloc>()..add(const ComplaintsLoad()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Civic Issues'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // Show filter options
              },
            ),
          ],
        ),
        body: BlocBuilder<ComplaintsBloc, ComplaintsState>(
          builder: (context, state) {
            if (state is ComplaintsLoading) {
              return const LoadingIndicator(message: 'Loading complaints...');
            }

            if (state is ComplaintsLoaded) {
              if (state.complaints.isEmpty) {
                return EmptyStateView(
                  icon: Icons.report_problem_outlined,
                  title: 'No complaints found',
                  subtitle: 'Be the first to report an issue in your area',
                  action: ElevatedButton.icon(
                    onPressed: () => context.push('/complaints/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Report Issue'),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ComplaintsBloc>().add(const ComplaintsLoad());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = state.complaints[index];
                    return _ComplaintCard(
                      complaint: complaint,
                      onTap: () => context.push('/complaints/${complaint.id}'),
                    );
                  },
                ),
              );
            }

            if (state is ComplaintsError) {
              return ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<ComplaintsBloc>().add(const ComplaintsLoad());
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/complaints/create'),
          icon: const Icon(Icons.add),
          label: const Text('Report'),
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback onTap;

  const _ComplaintCard({
    required this.complaint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getCategoryIcon(complaint.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint.category.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: complaint.status.displayName,
                    color: _getStatusColor(complaint.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (complaint.location.address != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        complaint.location.address!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${complaint.upvoteCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${complaint.commentCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(complaint.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(ComplaintCategory category) {
    IconData icon;
    Color color;

    switch (category) {
      case ComplaintCategory.waterLeakage:
        icon = Icons.water_drop;
        color = AppColors.waterLeakage;
        break;
      case ComplaintCategory.streetLight:
        icon = Icons.lightbulb;
        color = AppColors.streetLight;
        break;
      case ComplaintCategory.garbage:
        icon = Icons.delete;
        color = AppColors.garbage;
        break;
      case ComplaintCategory.lawAndOrder:
        icon = Icons.gavel;
        color = AppColors.lawAndOrder;
        break;
      case ComplaintCategory.roadDamage:
        icon = Icons.construction;
        color = AppColors.roadDamage;
        break;
      default:
        icon = Icons.report_problem;
        color = AppColors.warning;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color, size: 20),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}
