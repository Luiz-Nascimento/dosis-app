import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/auth/welcome_page.dart';
import 'pages/home_shell.dart';
import 'providers.dart';
import 'theme/app_theme.dart';

class DosisApp extends StatelessWidget {
  const DosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dosis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}

/// Com sessão: o app. Sem sessão: boas-vindas, login e cadastro.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(sessionProvider).when(
          data: (signedIn) => signedIn ? const HomeShell() : const WelcomePage(),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) => const WelcomePage(),
        );
  }
}