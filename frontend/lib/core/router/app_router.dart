import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/licitaciones/presentation/pages/licitaciones_page.dart';
import '../../features/licitaciones/presentation/pages/licitacion_detail_page.dart';
import '../../features/clientes/presentation/pages/clientes_page.dart';
import '../../features/clientes/presentation/pages/cliente_detail_page.dart';
import '../../features/documentos/presentation/pages/documentos_page.dart';
import '../../features/documentos/presentation/pages/documento_detail_page.dart';
import '../../features/crm/presentation/pages/contactos_page.dart';
import '../../features/crm/presentation/pages/interacciones_page.dart';
import '../../features/ampliaciones/presentation/pages/ampliaciones_page.dart';
import '../../features/ampliaciones/presentation/pages/ampliacion_detail_page.dart';
import '../../features/usuarios/presentation/pages/usuarios_page.dart';
import '../../features/usuarios/presentation/pages/usuario_detail_page.dart';
import '../../features/alerts/presentation/pages/alerts_page.dart';
import '../providers/auth_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState is _Authenticated;
      final isLoggingIn = state.location == '/login';

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // If authenticated and on login page, redirect to dashboard
      if (isAuthenticated && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/licitaciones',
        name: 'licitaciones',
        builder: (context, state) => const LicitacionesPage(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'licitacion-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return LicitacionDetailPage(licitacionId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/clientes',
        name: 'clientes',
        builder: (context, state) => const ClientesPage(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'cliente-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return ClienteDetailPage(clienteId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/documentos',
        name: 'documentos',
        builder: (context, state) => const DocumentosPage(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'documento-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return DocumentoDetailPage(documentoId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/crm/contactos',
        name: 'crm-contactos',
        builder: (context, state) => const ContactosPage(),
      ),
      GoRoute(
        path: '/crm/interacciones',
        name: 'crm-interacciones',
        builder: (context, state) => const InteraccionesPage(),
      ),
      GoRoute(
        path: '/ampliaciones',
        name: 'ampliaciones',
        builder: (context, state) => const AmpliacionesPage(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'ampliacion-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return AmpliacionDetailPage(ampliacionId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/usuarios',
        name: 'usuarios',
        builder: (context, state) => const UsuariosPage(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'usuario-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return UsuarioDetailPage(usuarioId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/alertas',
        name: 'alertas',
        builder: (context, state) => const AlertsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página no encontrada: ${state.location}'),
      ),
    ),
  );
});
