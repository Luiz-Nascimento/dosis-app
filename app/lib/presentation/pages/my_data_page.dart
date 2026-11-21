import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/enums.dart';
import '../../data/models/profile.dart';
import '../providers.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';

/// "Meus dados": nome, idade, peso, altura e sexo biológico, direto na API.
class MyDataPage extends ConsumerStatefulWidget {
  const MyDataPage({super.key});

  @override
  ConsumerState<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends ConsumerState<MyDataPage> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  BiologicalSex? _sex;
  bool _filled = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  /// Preenche os campos uma vez, com o que já está salvo.
  void _fill(Profile p) {
    if (_filled) return;
    _filled = true;
    _name.text = p.name ?? '';
    _age.text = p.age?.toString() ?? '';
    _weight.text = p.weightKg == null ? '' : _number(p.weightKg!);
    _height.text = p.heightCm == null ? '' : _number(p.heightCm!);
    _sex = p.biologicalSex;
  }

  String _number(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString().replaceAll('.', ',');

  /// Campo vazio vira `null` (não é enviado). Texto que não é número dá erro.
  double? _parse(String text, String label) {
    final clean = text.trim().replaceAll(',', '.');
    if (clean.isEmpty) return null;
    final value = double.tryParse(clean);
    if (value == null) throw ArgumentError('$label: digite só números.');
    return value;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final age = _parse(_age.text, 'Idade');
      if (age != null && age != age.roundToDouble()) throw ArgumentError('Idade: digite um número inteiro.');
      final name = _name.text.trim();
      await ref.read(updateProfileProvider)(
        name: name.isEmpty ? null : name,
        age: age?.toInt(),
        weightKg: _parse(_weight.text, 'Peso'),
        heightCm: _parse(_height.text, 'Altura'),
        biologicalSex: _sex,
      );
      ref.invalidate(profileProvider);
      ref.invalidate(accountProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Dados salvos.')));
      Navigator.of(context).pop();
    } on ArgumentError catch (error) {
      if (mounted) setState(() => _error = '${error.message}');
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
                Text(error is ApiException ? error.message : 'Não foi possível carregar seus dados.',
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
              const PageHeader('Meus dados'),
              const SizedBox(height: 16),
              AuthField(label: 'Nome', controller: _name, textInputAction: TextInputAction.next),
              const SizedBox(height: 14),
              AuthField(
                label: 'Idade (anos)',
                controller: _age,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AuthField(
                label: 'Peso (kg)',
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AuthField(
                label: 'Altura (cm)',
                controller: _height,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 18),
              const Text('Sexo biológico', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              for (final sex in BiologicalSex.values) ...[
                RadioRow(label: sex.label, selected: _sex == sex, onTap: () => setState(() => _sex = sex)),
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