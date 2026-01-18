import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'features/complaints/presentation/pages/complaints_page.dart';
import 'features/complaints/presentation/pages/create_complaint_page.dart';
import 'features/complaints/presentation/pages/complaint_detail_page.dart';
import 'features/community/presentation/pages/community_page.dart';
import 'features/community/presentation/pages/create_post_page.dart';
import 'features/maps/presentation/pages/map_page.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isLoggedIn = authState is AuthAuthenticated;
    final isLoggingIn = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }

    if (isLoggedIn && isLoggingIn) {
      return '/';
    }

    return null;
  },
  routes: [
    // Auth routes
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),

    // Main app shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/chat',
          name: 'chat',
          builder: (context, state) => const ChatPage(),
        ),
        GoRoute(
          path: '/complaints',
          name: 'complaints',
          builder: (context, state) => const ComplaintsPage(),
          routes: [
            GoRoute(
              path: 'create',
              name: 'create-complaint',
              builder: (context, state) => const CreateComplaintPage(),
            ),
            GoRoute(
              path: ':id',
              name: 'complaint-detail',
              builder: (context, state) => ComplaintDetailPage(
                complaintId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/community',
          name: 'community',
          builder: (context, state) => const CommunityPage(),
          routes: [
            GoRoute(
              path: 'create',
              name: 'create-post',
              builder: (context, state) => const CreatePostPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/map',
          name: 'map',
          builder: (context, state) => const MapPage(),
        ),
      ],
    ),

    // Admin routes
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => const AdminDashboardPage(),
    ),
  ],
);

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/chat');
              break;
            case 2:
              context.go('/complaints');
              break;
            case 3:
              context.go('/community');
              break;
            case 4:
              context.go('/map');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'AI Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}
