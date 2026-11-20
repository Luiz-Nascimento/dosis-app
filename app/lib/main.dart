import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_dependencies.dart';
import 'presentation/app.dart';
import 'presentation/providers.dart';

void main() {
  // Usa a API por padrão; `--dart-define=USE_API=false` roda com dados em memória.
  const useApi = bool.fromEnvironment('USE_API', defaultValue: true);
  final dependencies = useApi ? AppDependencies.create() : AppDependencies.fake();

  runApp(
    ProviderScope(
      overrides: [dependenciesProvider.overrideWithValue(dependencies)],
      child: const DosisApp(),
    ),
  );
}