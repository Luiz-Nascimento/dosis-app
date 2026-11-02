import 'package:flutter/material.dart';

import 'pages/home_shell.dart';
import 'theme/app_theme.dart';

class DosisApp extends StatelessWidget {
  const DosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dosis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeShell(),
    );
  }
}