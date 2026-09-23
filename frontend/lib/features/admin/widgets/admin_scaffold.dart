import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-navigation shell for the admin role.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const List<_Destination> _destinations = [
    _Destination(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home'),
    _Destination(Icons.policy_outlined, Icons.policy_rounded, 'Schemes'),
    _Destination(Icons.description_outlined, Icons.description_rounded, 'Apps'),
    _Destination(Icons.medical_services_outlined, Icons.medical_services_rounded, 'Claims'),
    _Destination(Icons.groups_outlined, Icons.groups_rounded, 'Farmers'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
              tooltip: destination.label,
            ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
