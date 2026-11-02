import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/auth.dart';
import '../../domain/repositories/system_repository.dart';

/// Confere se o app alcança o backend (útil ao configurar o emulador).
class ApiStatusPage extends StatefulWidget {
  const ApiStatusPage({super.key, required this.system});

  final SystemRepository system;

  @override
  State<ApiStatusPage> createState() => _ApiStatusPageState();
}

class _ApiStatusPageState extends State<ApiStatusPage> {
  late Future<HealthStatus> _health = widget.system.health();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<HealthStatus>(
            future: _health,
            builder: (context, snapshot) {
              final text = switch (snapshot) {
                AsyncSnapshot(hasData: true, :final data?) => 'API conectada (Firebase: ${data.firebaseMode})',
                AsyncSnapshot(hasError: true, :final error) =>
                  error is ApiException ? error.message : 'Erro ao conectar: $error',
                _ => 'Conectando à API...',
              };
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Dosis', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 16),
                  Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => setState(() => _health = widget.system.health()),
                    child: const Text('Testar de novo'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}