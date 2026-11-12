import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/settings.dart';
import '../../domain/usecases/hydration_goals.dart';
import '../format.dart';
import '../pages/reminders_page.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'dosis_bar_chart.dart';
import 'dosis_widgets.dart';

/// Topo da aba Hidratação: meta do dia, botões para registrar água,
/// registros de hoje, gráfico da semana e atalho para os lembretes.
class HydrationGoalSection extends ConsumerWidget {
  const HydrationGoalSection({super.key});

  static const _quickAmounts = [200, 300, 500];

  void _toast(BuildContext context, String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _log(BuildContext context, WidgetRef ref, int amountMl) async {
    try {
      await ref.read(logWaterProvider)(amountMl);
      ref.invalidate(hydrationProgressProvider);
    } on ArgumentError catch (error) {
      if (context.mounted) _toast(context, '${error.message}');
    } catch (error) {
      if (context.mounted) _toast(context, 'Não foi possível registrar: $error');
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(removeWaterLogProvider)(id);
      ref.invalidate(hydrationProgressProvider);
    } catch (error) {
      if (context.mounted) _toast(context, 'Não foi possível apagar: $error');
    }
  }

  /// Pede um número ao usuário. Devolve `null` se ele cancelar.
  Future<double?> _askNumber(BuildContext context, {required String title, required String unit, String? initial}) {
    final controller = TextEditingController(text: initial);
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: unit),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(double.tryParse(controller.text.trim().replaceAll(',', '.'))),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _customAmount(BuildContext context, WidgetRef ref) async {
    final ml = await _askNumber(context, title: 'Quanto você bebeu?', unit: 'ml');
    if (ml == null || !context.mounted) return;
    await _log(context, ref, ml.round());
  }

  Future<void> _editGoal(BuildContext context, WidgetRef ref, UserSettings settings) async {
    final liters = await _askNumber(
      context,
      title: 'Meta diária de água',
      unit: 'litros',
      initial: formatRounded(settings.hydrationGoalMl / 1000),
    );
    if (liters == null || !context.mounted) return;
    try {
      await ref.read(settingsProvider.notifier).save(settings.copyWith(hydrationGoalMl: (liters * 1000).round()));
    } on ArgumentError catch (error) {
      if (context.mounted) _toast(context, '${error.message}');
    } catch (error) {
      if (context.mounted) _toast(context, 'Não foi possível salvar a meta: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const UserSettings();
    final async = ref.watch(hydrationProgressProvider);
    final progress = async.value;

    if (progress == null) {
      return DosisCard(
        child: SizedBox(
          height: 80,
          child: Center(
            child: async.hasError
                ? Text('Não foi possível carregar a meta: ${async.error}', style: const TextStyle(color: AppColors.muted))
                : const CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Meta de hoje'),
        const SizedBox(height: 12),
        _GoalCard(
          progress: progress,
          onEditGoal: () => _editGoal(context, ref, settings),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final amount in _quickAmounts) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _log(context, ref, amount),
                  style: _addButtonStyle,
                  child: Text('+$amount ml', style: _addTextStyle),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: OutlinedButton(
                onPressed: () => _customAmount(context, ref),
                style: _addButtonStyle,
                child: const Text('Outro', style: _addTextStyle),
              ),
            ),
          ],
        ),
        if (progress.todayLogs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final log in progress.todayLogs)
                InputChip(
                  label: Text('${formatTime(log.loggedAt)} · ${log.amountMl} ml'),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  backgroundColor: AppColors.card,
                  side: const BorderSide(color: AppColors.border),
                  deleteIconColor: AppColors.muted,
                  deleteButtonTooltipMessage: 'Apagar registro',
                  onDeleted: () => _remove(context, ref, log.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        SectionTitle(
          'Últimos 7 dias',
          subtitle: 'Em litros. Meta batida em ${progress.daysOnGoal} de 7 dias',
        ),
        const SizedBox(height: 12),
        DosisCard(
          padding: const EdgeInsets.fromLTRB(10, 14, 14, 10),
          child: DosisBarChart(
            height: 150,
            values: [for (final day in progress.week) day.totalMl / 1000],
            labels: [for (final day in progress.week) formatDayShort(day.day)],
            reference: progress.goalMl / 1000,
            warnAbove: false,
            semanticLabel: 'Água nos últimos 7 dias. Meta de ${formatVolume(progress.goalMl)} '
                'batida em ${progress.daysOnGoal} dias.',
          ),
        ),
        const SizedBox(height: 16),
        NavCard(
          icon: Icons.notifications_active_outlined,
          title: 'Lembretes',
          subtitle: _remindersSummary(settings),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RemindersPage())),
        ),
      ],
    );
  }

  static final _addButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.yellow,
    side: const BorderSide(color: AppColors.yellow),
    padding: const EdgeInsets.symmetric(vertical: 12),
  );

  /// No texto (e não no estilo do botão) para herdar a fonte do tema.
  static const _addTextStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w800);

  static String _remindersSummary(UserSettings settings) {
    if (!settings.anyReminder) return 'Desligados. Toque para ativar';
    return [
      if (settings.waterReminders) 'Água a cada ${settings.waterIntervalHours} h',
      if (settings.supplementReminders) 'Suplementos nos horários da rotina',
    ].join(' · ');
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.progress, required this.onEditGoal});

  final HydrationProgress progress;
  final VoidCallback onEditGoal;

  @override
  Widget build(BuildContext context) {
    final percent = progress.goalMl <= 0 ? 0 : (progress.consumedMl * 100 / progress.goalMl).round();
    return DosisCard(
      borderColor: progress.goalReached ? AppColors.yellow : AppColors.border,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatVolume(progress.consumedMl),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.yellow),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'de ${formatVolume(progress.goalMl)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                ),
              ),
              IconButton(
                onPressed: onEditGoal,
                tooltip: 'Alterar meta',
                icon: const Icon(Icons.edit_outlined, color: AppColors.yellow, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.fraction,
                minHeight: 10,
                backgroundColor: AppColors.surface,
                color: AppColors.yellow,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            progress.goalReached
                ? 'Meta do dia batida ($percent%).'
                : 'Faltam ${formatVolume(progress.remainingMl)} para a meta ($percent%).',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
