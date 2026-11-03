import 'package:flutter_test/flutter_test.dart';
import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/tracking.dart';
import 'package:dosis/domain/usecases/calculate_hydration.dart';

void main() {
  const calculate = CalculateHydration();

  group('CalculateHydration', () {
    test('calcula hidratação básica para usuário sem creatina', () {
      // 70 kg * 35 ml = 2450 ml
      final result = calculate(
        weightKg: 70,
        stackItems: const [],
      );

      expect(result.baseMl, 2450);
      expect(result.creatineBonusMl, 0);
      expect(result.totalMl, 2450);
      expect(result.creatineGrams, 0);
      expect(result.totalLitersText, '2,5 L');
    });

    test('adiciona bônus mínimo de 500 ml para dose padrão de creatina (3g)', () {
      final items = [
        const RoutineItem(
          id: '1',
          name: 'Creatina Monohidratada',
          kind: ProductKind.supplement,
          protocol: Protocol.continuous,
          doseAmount: 3,
          doseUnit: DoseUnit.g,
          scheduleTimes: ['08:00'],
          active: true,
        ),
      ];

      // 80 kg * 35 ml = 2800 ml + 500 ml bônus = 3300 ml
      final result = calculate(
        weightKg: 80,
        stackItems: items,
      );

      expect(result.baseMl, 2800);
      expect(result.creatineBonusMl, 500);
      expect(result.totalMl, 3300);
      expect(result.creatineGrams, 3.0);
      expect(result.totalLitersText, '3,3 L');
      expect(result.explanation, contains('creatina'));
    });

    test('calcula bônus proporcional para protocolo de saturação de creatina (20g)', () {
      final items = [
        const RoutineItem(
          id: '1',
          name: 'Creatina Creapure',
          kind: ProductKind.supplement,
          protocol: Protocol.loading,
          doseAmount: 20,
          doseUnit: DoseUnit.g,
          scheduleTimes: ['09:00'],
          active: true,
        ),
      ];

      // 80 kg * 35 ml = 2800 ml + (20 * 100 ml) = 2800 + 2000 = 4800 ml
      final result = calculate(
        weightKg: 80,
        stackItems: items,
      );

      expect(result.baseMl, 2800);
      expect(result.creatineBonusMl, 2000);
      expect(result.totalMl, 4800);
      expect(result.creatineGrams, 20.0);
      expect(result.totalLitersText, '4,8 L');
    });

    test('rejeita peso zero ou negativo com ArgumentError', () {
      expect(() => calculate(weightKg: 0, stackItems: const []), throwsArgumentError);
      expect(() => calculate(weightKg: -10, stackItems: const []), throwsArgumentError);
    });
  });
}
