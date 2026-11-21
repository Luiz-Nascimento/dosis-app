import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/enums.dart';
import '../../data/models/profile.dart';
import '../providers.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';

/// "Meu objetivo": escolhe o objetivo e salva direto na API.
class MyGoalPage extends ConsumerStatefulWidget {
  const MyGoalPage({super.key});

  @override
  ConsumerState<MyGoalPage> createState() => _MyGoalPageState();
}

class _MyGoalPageState extends ConsumerState<MyGoalPage> {
  Goal? _goal;
  bool _filled = false;
  bool _saving = false;
  String? _error;

  void _fill(Profile p) {
    if (_filled) return;
    _filled = true;
    _goal = p.goal;
  }

  Future<void> _save() async {
    final goal = _goal;
    if (goal == null) {
      setState(() => _error = 'Escolha um objetivo.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(updateProfileProvider)(goal: goal);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Objetivo salvo.')));
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível salvar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: const DosisTopBar(),
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error is ApiException ? error.message : 'Não foi possível carregar seu objetivo.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(onPressed: () => ref.invalidate(profileProvider), child: const Text('Tentar de novo')),
              ],
            ),
          ),
        ),
        data: (p) {
          _fill(p);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const PageHeader('Meu objetivo'),
              const SizedBox(height: 16),
              const Text('O que você quer?', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              for (final goal in Goal.values) ...[
                RadioRow(label: goal.label, selected: _goal == goal, onTap: () => setState(() => _goal = goal)),
                const SizedBox(height: 8),
              ],
              AuthError(_error),
              const SizedBox(height: 18),
              AuthButton(label: 'Salvar', busy: _saving, onPressed: _save),
            ],
          );
        },
      ),
    );
  }
}