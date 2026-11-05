import 'package:flutter_test/flutter_test.dart';
import 'package:dosis/data/models/enums.dart';
import 'package:dosis/domain/usecases/check_dose_safety.dart';

void main() {
  const checkDoseSafety = CheckDoseSafety();

  group('CheckDoseSafety - Creatina', () {
    test('aceita dose dentro da faixa de uso contínuo (3g a 5g)', () {
      final check3g = checkDoseSafety(
        productName: 'Creatina Monohidratada',
        amount: 3.0,
        unit: DoseUnit.g,
        protocol: Protocol.continuous,
      );
      expect(check3g.isAboveRange, isFalse);

      final check5g = checkDoseSafety(
        productName: 'Creatina Creapure',
        amount: 5.0,
        unit: DoseUnit.g,
        protocol: Protocol.continuous,
      );
      expect(check5g.isAboveRange, isFalse);
    });

    test('alerta para dose acima da faixa em uso contínuo (> 5g)', () {
      final check10g = checkDoseSafety(
        productName: 'Creatina',
        amount: 10.0,
        unit: DoseUnit.g,
        protocol: Protocol.continuous,
      );

      expect(check10g.isAboveRange, isTrue);
      expect(check10g.recommendedMin, 3.0);
      expect(check10g.recommendedMax, 5.0);
      expect(check10g.message, contains('3 a 5 g/dia'));
      expect(check10g.caution, contains('rins'));
      expect(check10g.sourcesFormatted, contains('ISSN'));
      expect(check10g.sourcesFormatted, contains('ANVISA'));
    });

    test('aceita dose de saturação até 25g no protocolo loading', () {
      final check20g = checkDoseSafety(
        productName: 'Creatina',
        amount: 20.0,
        unit: DoseUnit.g,
        protocol: Protocol.loading,
      );
      expect(check20g.isAboveRange, isFalse);
    });

    test('alerta para dose acima de 25g mesmo no protocolo de saturação', () {
      final check30g = checkDoseSafety(
        productName: 'Creatina',
        amount: 30.0,
        unit: DoseUnit.g,
        protocol: Protocol.loading,
      );

      expect(check30g.isAboveRange, isTrue);
      expect(check30g.recommendedMin, 15.0);
      expect(check30g.recommendedMax, 25.0);
      expect(check30g.message, contains('saturação'));
    });

    test('converte mg para g na verificação', () {
      final check6000mg = checkDoseSafety(
        productName: 'Creatina',
        amount: 6000.0,
        unit: DoseUnit.mg,
        protocol: Protocol.continuous,
      );
      expect(check6000mg.isAboveRange, isTrue);
    });
  });
}
