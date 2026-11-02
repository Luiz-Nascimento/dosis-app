import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Título de seção com a barrinha amarela vertical.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cartão escuro com borda fina.
class DosisCard extends StatelessWidget {
  const DosisCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.color = AppColors.card,
    this.borderColor = AppColors.border,
    this.radius = 16,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Seta de voltar + título centralizado.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.backColor = Colors.white});

  final String title;
  final Color backColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, color: backColor),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

/// Linha do "Stack de hoje": horário amarelo, nome e dose.
class StackRow extends StatelessWidget {
  const StackRow({super.key, required this.time, required this.name, required this.amount});

  final String time;
  final String name;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Text(time, style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}

/// Opção selecionável: escura normal, laranja com check quando marcada.
class SelectBox extends StatelessWidget {
  const SelectBox({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 52,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : Colors.white;
    return Material(
      color: selected ? AppColors.orangeSoft : AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.orange : AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check, size: 16, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.orange : Colors.transparent,
        border: selected ? null : Border.all(color: AppColors.muted),
      ),
    );
  }
}

/// Linha de lista com bolinha de seleção (catálogo de suplementos/anabolizantes).
class RadioRow extends StatelessWidget {
  const RadioRow({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      onTap: onTap,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      color: selected ? AppColors.orangeSoft : AppColors.card,
      borderColor: selected ? AppColors.orange : AppColors.border,
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          RadioDot(selected: selected),
        ],
      ),
    );
  }
}

/// Paginação "‹ 1 2 3 4 ›".
class Pager extends StatelessWidget {
  const Pager({super.key, required this.page, required this.pages, required this.onChanged});

  final int page;
  final int pages;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 0 ? () => onChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left, color: AppColors.yellow),
        ),
        for (var i = 0; i < pages; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == page ? AppColors.yellow : Colors.transparent,
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: i == page ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        IconButton(
          onPressed: page < pages - 1 ? () => onChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right, color: AppColors.yellow),
        ),
      ],
    );
  }
}

/// Cartão de navegação da Home: ícone, título, subtítulo e seta amarela.
class NavCard extends StatelessWidget {
  const NavCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.boxedIcon = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool boxedIcon;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      onTap: onTap,
      child: Row(
        children: [
          if (boxedIcon)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.yellow),
            )
          else
            Icon(icon, color: AppColors.yellow, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.yellow, size: 28),
        ],
      ),
    );
  }
}

/// Campo de busca com lupa amarela.
class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.hint, this.onChanged});

  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: AppColors.yellow),
      ),
    );
  }
}