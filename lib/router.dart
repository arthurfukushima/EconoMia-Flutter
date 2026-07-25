import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/receipt/receipt_screen.dart';
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

    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const PhasePlaceholder(
                title: 'Início',
                phase: 7,
                summary: 'A casa da Mia — quanto dá pra economizar, atalhos e a dica do dia.',
              ),
              routes: [
                // Nested under Home so a back gesture returns to the tile that
                // opened it, but rendered above the shell (see parentNavigatorKey).
                GoRoute(
                  path: 'notas',
                  parentNavigatorKey: _rootKey,
                  builder: (_, _) => const PhasePlaceholder(
                    title: 'Minhas Notas',
                    phase: 6,
                    summary: 'Suas notas escaneadas, com a economia de cada uma.',
                  ),
                  routes: [
                    GoRoute(
                      path: ':accessKey',
                      parentNavigatorKey: _rootKey,
                      builder: (_, state) =>
                          ReceiptScreen(accessKey: state.pathParameters['accessKey']!),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'mercado',
                  parentNavigatorKey: _rootKey,
                  builder: (_, _) => const PhasePlaceholder(
                    title: 'No mercado',
                    phase: 10,
                    summary: 'Escaneie as prateleiras e compare com os mercados vizinhos.',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lista',
              builder: (_, _) => const PhasePlaceholder(
                title: 'Lista de Compras',
                phase: 12,
                summary: 'Escreva do seu jeito e a Mia procura o melhor preço por perto.',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ofertas',
              builder: (_, _) => const PhasePlaceholder(
                title: 'Ofertas',
                phase: 15,
                summary: 'Os melhores dias da semana para cada categoria na sua região.',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/resumo',
              builder: (_, _) => const PhasePlaceholder(
                title: 'Resumo',
                phase: 14,
                summary: 'Para onde vai seu dinheiro e onde dá pra economizar.',
              ),
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/scan',
      parentNavigatorKey: _rootKey,
      builder: (_, state) => ScanScreen(
        mode: state.uri.queryParameters['mode'] == 'produto' ? ScanMode.produto : ScanMode.nota,
      ),
    ),
    GoRoute(
      path: '/produto/:gtin',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const PhasePlaceholder(
        title: 'Produto',
        phase: 9,
        summary: 'A faixa de preço na sua região e as lojas mais próximas.',
      ),
    ),
  ],
);
