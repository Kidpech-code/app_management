import 'package:flutter/material.dart';

import 'package:app_management/app/router/app_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  int get _currentIndex => location.startsWith(SettingsRoute.location) ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              TodosRoute.go(context);
            case 1:
              SettingsRoute.go(context);
          }
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'Todos'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
