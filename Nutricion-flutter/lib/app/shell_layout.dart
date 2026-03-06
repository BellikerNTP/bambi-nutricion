import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellLayout extends StatelessWidget {
  const ShellLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            labelType: NavigationRailLabelType.all,
            selectedIndex: _indexForLocation(currentLocation),
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/inventario');
                  break;
                case 1:
                  context.go('/platos-servidos');
                  break;
              }
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Inventario'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: Text('Platos Servidos'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  title: const Text('Nutrición'),
                  centerTitle: false,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                const Divider(height: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/platos-servidos')) return 1;
    return 0;
  }
}
