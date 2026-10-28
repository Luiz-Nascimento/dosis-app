import 'package:flutter/material.dart';

import 'core/api/api_exception.dart';
import 'data/dosis_api.dart';
import 'data/models/auth.dart';

void main() => runApp(DosisApp(api: DosisApi.secure()));

/// Casca do app. As telas do Figma entram no lugar de [ApiStatusPage]
/// (tarefas de interface); a camada de dados já está em `lib/data`.
class DosisApp extends StatelessWidget {
  const DosisApp({super.key, required this.api});

  final DosisApi api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dosis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD60A),
          secondary: Color(0xFFFF9A22),
          surface: Color(0xFF17181D),
        ),
      ),
      home: ApiStatusPage(api: api),
    );
  }
}

/// Confere se o app alcança o backend (útil ao configurar o emulador).
class ApiStatusPage extends StatefulWidget {
  const ApiStatusPage({super.key, required this.api});

  final DosisApi api;

  @override
  State<ApiStatusPage> createState() => _ApiStatusPageState();
}

class _ApiStatusPageState extends State<ApiStatusPage> {
  late Future<HealthStatus> _health = widget.api.system.health();

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
                    onPressed: () => setState(() => _health = widget.api.system.health()),
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
