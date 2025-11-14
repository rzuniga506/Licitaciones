import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;
  final String title;
  final String currentRoute;

  const AppScaffold({
    super.key,
    required this.child,
    required this.title,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > AppConfig.desktopBreakpoint;
    final isMobile = size.width <= AppConfig.tabletBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          _AlertsBadge(),
          const SizedBox(width: 8),
          _UserMenu(),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isMobile ? _NavigationDrawer(currentRoute: currentRoute) : null,
      body: Row(
        children: [
          if (isDesktop) _NavigationRail(currentRoute: currentRoute),
          Expanded(
            child: Container(
              color: AppTheme.neutral50,
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          isMobile ? _BottomNavigation(currentRoute: currentRoute) : null,
    );
  }
}

class _NavigationRail extends StatelessWidget {
  final String currentRoute;

  const _NavigationRail({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppTheme.neutral300),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _NavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Dashboard',
            isSelected: currentRoute == '/',
            onTap: () => context.go('/'),
          ),
          _NavItem(
            icon: Icons.gavel_outlined,
            selectedIcon: Icons.gavel,
            label: 'Licitaciones',
            isSelected: currentRoute == '/licitaciones',
            onTap: () => context.go('/licitaciones'),
          ),
          _NavItem(
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications,
            label: 'Alertas',
            isSelected: currentRoute == '/alertas',
            onTap: () => context.go('/alertas'),
          ),
          const Divider(height: 32),
          _NavItem(
            icon: Icons.business_outlined,
            selectedIcon: Icons.business,
            label: 'Clientes',
            isSelected: currentRoute == '/clientes',
            onTap: () => context.go('/clientes'),
          ),
          _NavItem(
            icon: Icons.folder_outlined,
            selectedIcon: Icons.folder,
            label: 'Documentos',
            isSelected: currentRoute == '/documentos',
            onTap: () => context.go('/documentos'),
          ),
          _NavItem(
            icon: Icons.people_outlined,
            selectedIcon: Icons.people,
            label: 'CRM',
            isSelected: currentRoute == '/crm',
            onTap: () {
              // TODO: Implement
            },
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final String currentRoute;

  const _BottomNavigation({required this.currentRoute});

  int get _currentIndex {
    switch (currentRoute) {
      case '/':
        return 0;
      case '/licitaciones':
        return 1;
      case '/alertas':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/licitaciones');
            break;
          case 2:
            context.go('/alertas');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.gavel_outlined),
          activeIcon: Icon(Icons.gavel),
          label: 'Licitaciones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Alertas',
        ),
      ],
    );
  }
}

class _NavigationDrawer extends StatelessWidget {
  final String currentRoute;

  const _NavigationDrawer({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.gavel_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  'Licitaciones',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          _NavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Dashboard',
            isSelected: currentRoute == '/',
            onTap: () {
              context.go('/');
              Navigator.pop(context);
            },
          ),
          _NavItem(
            icon: Icons.gavel_outlined,
            selectedIcon: Icons.gavel,
            label: 'Licitaciones',
            isSelected: currentRoute == '/licitaciones',
            onTap: () {
              context.go('/licitaciones');
              Navigator.pop(context);
            },
          ),
          _NavItem(
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications,
            label: 'Alertas',
            isSelected: currentRoute == '/alertas',
            onTap: () {
              context.go('/alertas');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? AppTheme.primaryBlue : AppTheme.neutral700,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.neutral900,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppTheme.lightBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AlertsBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get real count from alerts provider
    const alertCount = 3;

    return IconButton(
      icon: Badge(
        label: const Text('3'),
        isLabelVisible: alertCount > 0,
        child: const Icon(Icons.notifications_outlined),
      ),
      onTap: () => context.go('/alertas'),
    );
  }
}

class _UserMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (authState is! _Authenticated) {
      return const SizedBox.shrink();
    }

    final user = authState.user;

    return PopupMenuButton<String>(
      tooltip: 'Menú de usuario',
      offset: const Offset(0, 48),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryBlue,
            child: Text(
              user.fullName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            user.fullName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Chip(
                label: Text(
                  UserRole.values
                      .firstWhere((r) => r.name == user.role)
                      .displayName,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Mi Perfil'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Configuración'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Cerrar Sesión'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'logout') {
          await ref.read(authStateProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
          }
        }
        // TODO: Handle other menu options
      },
    );
  }
}
