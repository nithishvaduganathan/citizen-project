import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../core/constants/app_colors.dart';

/// Admin dashboard page
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const LoadingIndicator();
        }

        final user = state.user;
        if (!user.isAdmin && !user.isAuthority) {
          return const Scaffold(
            body: Center(
              child: Text('Access denied. Admin or authority access required.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/'),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${user.fullName}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              StatusChip(
                                label: user.isAdmin ? 'ADMIN' : 'AUTHORITY',
                                color: user.isAdmin
                                    ? AppColors.error
                                    : AppColors.warning,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.admin_panel_settings, size: 48),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Stats overview
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: const [
                    _StatCard(
                      icon: Icons.report_problem,
                      title: 'Total Complaints',
                      value: '0',
                      color: AppColors.primary,
                    ),
                    _StatCard(
                      icon: Icons.pending_actions,
                      title: 'Pending',
                      value: '0',
                      color: AppColors.pending,
                    ),
                    _StatCard(
                      icon: Icons.autorenew,
                      title: 'In Progress',
                      value: '0',
                      color: AppColors.inProgress,
                    ),
                    _StatCard(
                      icon: Icons.check_circle,
                      title: 'Resolved',
                      value: '0',
                      color: AppColors.resolved,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _ActionItem(
                  icon: Icons.assignment,
                  title: 'Manage Complaints',
                  subtitle: 'View and update complaint status',
                  onTap: () {},
                ),
                if (user.isAdmin) ...[
                  _ActionItem(
                    icon: Icons.people,
                    title: 'User Management',
                    subtitle: 'Manage users and roles',
                    onTap: () {},
                  ),
                  _ActionItem(
                    icon: Icons.verified_user,
                    title: 'Authority Verification',
                    subtitle: 'Verify authority accounts',
                    onTap: () {},
                  ),
                  _ActionItem(
                    icon: Icons.map,
                    title: 'Complaint Heatmap',
                    subtitle: 'View geographic distribution',
                    onTap: () {},
                  ),
                  _ActionItem(
                    icon: Icons.security,
                    title: 'Content Moderation',
                    subtitle: 'Moderate posts and complaints',
                    onTap: () {},
                  ),
                ],
                if (user.isAuthority && !user.isAdmin) ...[
                  _ActionItem(
                    icon: Icons.location_on,
                    title: 'My Jurisdiction',
                    subtitle: 'View complaints in your area',
                    onTap: () {},
                  ),
                ],

                const SizedBox(height: 24),

                // Recent activity placeholder
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: EmptyStateView(
                      icon: Icons.history,
                      title: 'No recent activity',
                      subtitle: 'Activity will appear here',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
