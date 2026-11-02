import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../theme/app_theme.dart';

/// Barra do topo: logo "Dosis" amarelo + ícone de perfil.
class DosisTopBar extends StatelessWidget implements PreferredSizeWidget {
  const DosisTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Text('Dosis', style: AppTheme.logo),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.person_outline, size: 20),
          ),
        ),
      ],
    );
  }
}

class _PillIcon extends StatelessWidget {
  const _PillIcon(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -math.pi / 4,
      child: Container(
        width: 30,
        height: 14,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Container(width: 2, color: color)),
      ),
    );
  }
}

/// Menu de baixo: 4 ícones sem texto (início, rotina, hidratação, registros).
/// Com [popToRoot], as telas empilhadas voltam para a raiz ao trocar de aba.
class DosisBottomNav extends ConsumerWidget {
  const DosisBottomNav({super.key, this.popToRoot = false});

  final bool popToRoot;

  static const _labels = ['Início', 'Rotina', 'Hidratação', 'Registros'];

  Widget _icon(int index, Color color) => switch (index) {
        0 => Icon(Icons.home_outlined, size: 32, color: color),
        1 => _PillIcon(color),
        2 => Icon(Icons.water_drop_outlined, size: 30, color: color),
        _ => Icon(Icons.assignment_outlined, size: 30, color: color),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(tabIndexProvider);
    return Container(
      color: AppColors.navBar,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: _labels[i],
                    child: InkResponse(
                      onTap: () {
                        ref.read(tabIndexProvider.notifier).select(i);
                        if (popToRoot) Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Center(child: _icon(i, i == current ? AppColors.yellow : Colors.white)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}