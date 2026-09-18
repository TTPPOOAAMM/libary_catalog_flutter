import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../state/auth_notifier.dart';

class NavigationDestinationItem {
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool Function(UserRole role) isPermitted;

  const NavigationDestinationItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isPermitted,
  });
}

class AdaptiveShell extends StatelessWidget {
  final Widget child;
  const AdaptiveShell({super.key, required this.child});

  static final List<NavigationDestinationItem> _allDestinations = [
    NavigationDestinationItem(
      route: '/books',
      label: 'Каталог',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      isPermitted: (_) => true,
    ),
    NavigationDestinationItem(
      route: '/my-loans',
      label: 'Мои книги',
      icon: Icons.bookmark_border,
      selectedIcon: Icons.bookmark,
      isPermitted: (role) => AppPermissions.canViewMyLoans(role),
    ),
    NavigationDestinationItem(
      route: '/loans',
      label: 'Выдачи',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      isPermitted: (role) => AppPermissions.canManageLoans(role),
    ),
    NavigationDestinationItem(
      route: '/authors',
      label: 'Авторы',
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
      isPermitted: (_) => true,
    ),
    NavigationDestinationItem(
      route: '/genres',
      label: 'Жанры',
      icon: Icons.category_outlined,
      selectedIcon: Icons.category,
      isPermitted: (role) => AppPermissions.canManageCatalogs(role),
    ),
    NavigationDestinationItem(
      route: '/publishers',
      label: 'Издатели',
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
      isPermitted: (role) => AppPermissions.canManageCatalogs(role),
    ),
    NavigationDestinationItem(
      route: '/readers',
      label: 'Читатели',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
      isPermitted: (role) => AppPermissions.canManageReaders(role),
    ),
    NavigationDestinationItem(
      route: '/users',
      label: 'Пользователи',
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
      isPermitted: (role) => AppPermissions.canManageUsers(role),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final role = auth.currentRole;
    final currentRoute = GoRouterState.of(context).uri.path;

    final permittedItems =
        _allDestinations.where((item) => item.isPermitted(role)).toList();
    var selectedIndex = permittedItems
        .indexWhere((item) => currentRoute.startsWith(item.route));
    if (selectedIndex == -1) selectedIndex = 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        Widget content = child;
        if (width >= 1920) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: child,
            ),
          );
        }

        if (width < 768) {
          return Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) =>
                  context.go(permittedItems[idx].route),
              destinations: permittedItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                  tooltip: item.label,
                );
              }).toList(),
            ),
          );
        }

        final isExtended = width >= 1280;

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: isExtended,
                minWidth: 72,
                minExtendedWidth: 200,
                selectedIndex: selectedIndex,
                onDestinationSelected: (idx) =>
                    context.go(permittedItems[idx].route),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Icon(
                    Icons.local_library_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IconButton(
                        icon: const Icon(Icons.logout),
                        tooltip: 'Выйти из системы',
                        onPressed: () => context.read<AuthNotifier>().logout(),
                      ),
                    ),
                  ),
                ),
                destinations: permittedItems.map((item) {
                  return NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  );
                }).toList(),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}
