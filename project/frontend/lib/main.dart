import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'screens/dashboard_screen.dart';
import 'screens/incidents_screen.dart';
import 'screens/staff_screen.dart';
import 'screens/ai_assist_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: CrisisSyncApp()));
}

class CrisisSyncApp extends ConsumerWidget {
  const CrisisSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'CrisisSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53020),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Syne',
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/dashboard',  builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/incidents',  builder: (_, __) => const IncidentsScreen()),
        GoRoute(path: '/staff',      builder: (_, __) => const StaffScreen()),
        GoRoute(path: '/ai-assist',  builder: (_, __) => const AiAssistScreen()),
      ],
    ),
  ],
);

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xFF111418),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.warning_amber), label: Text('Incidents')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('Staff')),
              NavigationRailDestination(icon: Icon(Icons.auto_awesome), label: Text('AI Assist')),
            ],
            selectedIndex: 0,
            onDestinationSelected: (i) {
              final routes = ['/dashboard', '/incidents', '/staff', '/ai-assist'];
              context.go(routes[i]);
            },
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
