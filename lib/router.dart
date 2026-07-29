import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/catalogo/catalogo_screen.dart';
import 'features/gamification/missions_screen.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/lista/lista_screen.dart';
import 'features/mercado/mercado_screen.dart';
import 'features/produto/busca_screen.dart';
import 'features/produto/produto_screen.dart';
import 'features/profile/create_profile_screen.dart';
import 'features/profile/login_screen.dart';
import 'features/receipt/receipt_screen.dart';
import 'features/resumo/resumo_screen.dart';
import 'features/scan/scan_mode.dart';
import 'features/scan/scan_screen.dart';
import 'features/splash/splash_screen.dart';
import 'widgets/app_shell.dart';
import 'widgets/phase_placeholder.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Four tab branches under a persistent shell; everything else is pushed on top
/// of it. Minhas Notas and No mercado are full routes but deliberately have no
/// tab — they hang off Home's shortcut tiles.
final router = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(
      path: '/perfil/login',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: '/perfil/criar',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const CreateProfileScreen(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const HomeScreen(),
              routes: [
                // Nested under Home so a back gesture returns to the tile that
                // opened it, but rendered above the shell (see parentNavigatorKey).
                GoRoute(
                  path: 'notas',
                  parentNavigatorKey: _rootKey,
                  builder: (_, _) => const HistoryScreen(),
                  routes: [
                    GoRoute(
                      path: ':accessKey',
                      parentNavigatorKey: _rootKey,
                      builder: (_, state) => ReceiptScreen(
                        accessKey: state.pathParameters['accessKey']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'mercado',
                  parentNavigatorKey: _rootKey,
                  builder: (_, _) => const MercadoScreen(),
                ),
                // Two ways in: from Home with no market chosen yet (the screen's
                // own picker chooses one), or from Mercado with the market you
                // are standing in already known.
                GoRoute(
                  path: 'catalogo',
                  parentNavigatorKey: _rootKey,
                  builder: (_, _) => const CatalogoScreen(),
                  routes: [
                    GoRoute(
                      path: ':cod',
                      parentNavigatorKey: _rootKey,
                      builder: (_, state) => CatalogoScreen(
                        marketCodigo: state.pathParameters['cod'],
                        marketLabel: state.uri.queryParameters['nome'],
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'missoes',
                  parentNavigatorKey: _rootKey,
                  builder: (_, _) => const MissionsScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/lista', builder: (_, _) => const ListaScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ofertas',
              builder: (_, _) => const PhasePlaceholder(
                title: 'Ofertas',
                phase: 15,
                summary:
                    'Os melhores dias da semana para cada categoria na sua região.',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/resumo', builder: (_, _) => const ResumoScreen()),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/scan',
      parentNavigatorKey: _rootKey,
      builder: (_, state) => ScanScreen(
        mode: state.uri.queryParameters['mode'] == 'produto'
            ? ScanMode.produto
            : ScanMode.nota,
      ),
    ),
    // Declared before the `:gtin` route below: go_router matches sibling
    // routes in declaration order, so this static path must come first or
    // "/produto/busca" would match the dynamic route with gtin="busca".
    GoRoute(
      path: '/produto/busca',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const BuscaScreen(),
    ),
    GoRoute(
      path: '/produto/:gtin',
      parentNavigatorKey: _rootKey,
      builder: (_, state) => ProdutoScreen(gtin: state.pathParameters['gtin']!),
    ),
  ],
);
