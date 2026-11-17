import 'package:flutter/material.dart';

import '../../data/models/recommendation.dart';
import '../theme/app_theme.dart';
import 'dosis_widgets.dart';

/// Cartão de uma recomendação do motor, com a fonte que embasa o texto.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({super.key, required this.recommendation, this.onTap});

  final Recommendation recommendation;
  final VoidCallback? onTap;

  (IconData, Color, String) get _style => switch (recommendation.level) {
        RecommendationLevel.medical => (Icons.medical_services_outlined, AppColors.orange, 'Acompanhamento médico'),
        RecommendationLevel.attention => (Icons.warning_amber_rounded, AppColors.yellow, 'Vale revisar'),
        RecommendationLevel.info => (Icons.lightbulb_outline, AppColors.yellow, 'Dica educativa'),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _style;
    return DosisCard(
      onTap: onTap,
      borderColor: recommendation.level == RecommendationLevel.info ? AppColors.border : color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  recommendation.body,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 13, color: color),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${recommendation.sourcesFormatted} · $label',
                        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
