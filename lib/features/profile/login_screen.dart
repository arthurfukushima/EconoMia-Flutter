import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/tokens.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _showSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esse caminho entra nas próximas fases.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sa.forest,
                  borderRadius: SaRadius.xlAll,
                  boxShadow: sa.lift,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.account_circle_rounded,
                      color: sa.amber,
                      size: 34,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Entre quando quiser',
                      style: theme.textTheme.headlineSmall!.copyWith(
                        color: sa.paper,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Seu perfil vai ajudar a Mia a lembrar seu nome. O app continua funcionando sem login.',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: sa.paper.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => context.push('/perfil/criar'),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Criar conta'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _showSoon(context),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Já tenho conta'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Divider(color: sa.stroke2)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'ou',
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: sa.muted,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: sa.stroke2)),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _showSoon(context),
                icon: const Icon(Icons.g_mobiledata_rounded),
                label: const Text('Continuar com Google'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _showSoon(context),
                icon: const Icon(Icons.facebook_rounded),
                label: const Text('Continuar com Facebook'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
