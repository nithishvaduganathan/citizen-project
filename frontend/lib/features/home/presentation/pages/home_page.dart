import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../core/constants/app_colors.dart';

/// Home page - Dashboard for users
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const LoadingIndicator();
        }

        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Citizen Civic AI'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Navigate to notifications
                },
              ),
              PopupMenuButton<String>(
                icon: UserAvatar(
                  name: user.fullName,
                  imageUrl: user.profile.avatarUrl,
                  size: 32,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      // Navigate to profile
                      break;
                    case 'settings':
                      // Navigate to settings
                      break;
                    case 'admin':
                      context.push('/admin');
                      break;
                    case 'logout':
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Profile'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (user.isAdmin || user.isAuthority)
                    const PopupMenuItem(
                      value: 'admin',
                      child: ListTile(
                        leading: Icon(Icons.admin_panel_settings_outlined),
                        title: Text('Admin Panel'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Logout', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Refresh data
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome card
                  _WelcomeCard(user: user),
                  
                  const SizedBox(height: 24),
                  
                  // Quick actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionsGrid(),
                  
                  const SizedBox(height: 24),
                  
                  // Features section
                  Text(
                    'Features',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _FeaturesList(),
                  
                  const SizedBox(height: 24),
                  
                  // Recent activity
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _RecentActivityList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final dynamic user;

  const _WelcomeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  StatusChip(
                    label: user.role.name.toUpperCase(),
                    color: _getRoleColor(user),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.how_to_vote,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(dynamic user) {
    if (user.isAdmin) {
      return AppColors.error;
    }
    if (user.isAuthority) {
      return AppColors.warning;
    }
    return AppColors.primary;
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _QuickActionCard(
          icon: Icons.chat,
          title: 'AI Assistant',
          subtitle: 'Ask about laws',
          color: AppColors.primary,
          onTap: () => context.go('/chat'),
        ),
        _QuickActionCard(
          icon: Icons.report_problem,
          title: 'Report Issue',
          subtitle: 'Submit complaint',
          color: AppColors.warning,
          onTap: () => context.push('/complaints/create'),
        ),
        _QuickActionCard(
          icon: Icons.map,
          title: 'View Map',
          subtitle: 'See nearby issues',
          color: AppColors.secondary,
          onTap: () => context.go('/map'),
        ),
        _QuickActionCard(
          icon: Icons.people,
          title: 'Community',
          subtitle: 'Join discussions',
          color: AppColors.accent,
          onTap: () => context.go('/community'),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeatureItem(
          icon: Icons.gavel,
          title: 'Constitutional Knowledge',
          description: 'Learn about Indian Constitution and laws through AI-powered chat',
        ),
        _FeatureItem(
          icon: Icons.language,
          title: 'Multi-language Support',
          description: 'Available in English, Tamil, and Hindi',
        ),
        _FeatureItem(
          icon: Icons.location_on,
          title: 'Location-based Reporting',
          description: 'Report issues with GPS coordinates and photos',
        ),
        _FeatureItem(
          icon: Icons.group,
          title: 'Community Engagement',
          description: 'Connect with fellow citizens and authorities',
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title),
      subtitle: Text(description),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const EmptyStateView(
              icon: Icons.history,
              title: 'No recent activity',
              subtitle: 'Your recent activities will appear here',
            ),
          ],
        ),
      ),
    );
  }
}
