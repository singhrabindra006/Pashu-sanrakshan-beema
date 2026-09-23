import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-navigation shell for the farmer role. Sub-screens (forms, details) are
/// pushed above this shell so they get the full height.
class FarmerScaffold extends StatelessWidget {
  const FarmerScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const List<_Destination> _destinations = [
    _Destination(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _Destination(Icons.pets_outlined, Icons.pets_rounded, 'Animals'),
    _Destination(Icons.policy_outlined, Icons.policy_rounded, 'Schemes'),
    _Destination(Icons.description_outlined, Icons.description_rounded, 'Apps'),
    _Destination(Icons.medical_services_outlined, Icons.medical_services_rounded, 'Claims'),
    _Destination(Icons.person_outline, Icons.person_rounded, 'Me'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // `initialLocation: true` resets a branch to its root when re-tapped.
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
