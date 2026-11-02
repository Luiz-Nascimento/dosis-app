import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../widgets/dosis_chrome.dart';
import 'home_page.dart';
import 'hydration_page.dart';
import 'records_page.dart';
import 'routine_page.dart';

/// Barra do topo + 4 abas + menu de baixo, como no protótipo.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _pages = <Widget>[HomePage(), RoutinePage(), HydrationPage(), RecordsPage()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(tabIndexProvider);
    return Scaffold(
      appBar: const DosisTopBar(),
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: const DosisBottomNav(),
    );
  }
}