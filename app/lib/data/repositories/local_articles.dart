import '../models/catalog.dart';

/// Cópia local de `backend/apps/catalog/content.py`, usada quando o app está
/// sem internet (e no modo fake, sem backend). Se mudar um artigo lá, mude aqui
/// também.
class LocalArticles {
  const LocalArticles._();

  static const issnCreatina = Source(
    id: 'issn-creatina-2017',
    name: 'ISSN',
    citation: 'Kreider RB et al. International Society of Sports Nutrition position stand: safety and '
        'efficacy of creatine supplementation in exercise, sport, and medicine. J Int Soc Sports Nutr. 2017;14:18.',
    url: 'https://doi.org/10.1186/s12970-017-0173-z',
  );
  static const issnProteina = Source(
    id: 'issn-proteina-2017',
    name: 'ISSN',
    citation: 'Jäger R et al. International Society of Sports Nutrition Position Stand: protein and exercise. '
        'J Int Soc Sports Nutr. 2017;14:20.',
    url: 'https://doi.org/10.1186/s12970-017-0177-8',
  );
  static const efsaOmega3 = Source(
    id: 'efsa-omega3-2012',
    name: 'EFSA',
    citation: 'EFSA NDA Panel. Scientific Opinion related to the Tolerable Upper Intake Level of EPA, DHA and DPA. '
        'EFSA Journal 2012;10(7):2815.',
    url: 'https://doi.org/10.2903/j.efsa.2012.2815',
  );
  static const anvisaSuplementos = Source(
    id: 'anvisa-suplementos',
    name: 'ANVISA',
    citation: 'ANVISA. RDC nº 243/2018 e Instrução Normativa nº 28/2018: requisitos sanitários, constituintes, '
        'limites de uso e alegações de suplementos alimentares.',
    url: 'https://www.gov.br/anvisa/pt-br/assuntos/alimentos/suplementos-alimentares',
  );
  static const anvisaControlados = Source(
    id: 'anvisa-controlados',
    name: 'ANVISA',
    citation: 'Portaria SVS/MS nº 344/1998 (anabolizantes na lista C5 de controle especial) e Lei nº 9.965/2000 '
        '(venda de anabolizantes só com receita retida).',
    url: 'https://www.gov.br/anvisa/pt-br',
  );
  static const cfm = Source(
    id: 'cfm-2333-2023',
    name: 'CFM',
    citation: 'Conselho Federal de Medicina. Resolução nº 2.333/2023: veda a prescrição de esteroides anabolizantes '
        'com finalidade estética, de ganho de massa muscular ou de desempenho esportivo.',
    url: 'https://portal.cfm.org.br',
  );
  static const sbem = Source(
    id: 'sbem',
    name: 'SBEM',
    citation: 'Sociedade Brasileira de Endocrinologia e Metabologia: orientações sobre esteroides anabolizantes.',
    url: 'https://www.endocrino.org.br',
  );
  static const acsmHidratacao = Source(
    id: 'acsm-hidratacao-2007',
    name: 'ACSM',
    citation: 'Sawka MN et al. American College of Sports Medicine position stand: exercise and fluid '
        'replacement. Med Sci Sports Exerc. 2007;39(2):377-390.',
    url: 'https://doi.org/10.1249/mss.0b013e31802ca597',
  );
  static const aasmSono = Source(
    id: 'aasm-sono-2015',
    name: 'AASM/SRS',
    citation: 'Watson NF et al. Recommended Amount of Sleep for a Healthy Adult: a joint consensus '
        'statement of the AASM and SRS. Sleep. 2015;38(6):843-844.',
    url: 'https://doi.org/10.5665/sleep.4716',
  );

  static const articles = <Article>[
    Article(
      id: 'whey-quanto-usar-por-dia',
      title: 'Whey Protein: quanto usar por dia?',
      summary: 'O que importa é o total de proteína do dia, não só o shake.',
      tags: ['whey', 'proteina'],
      readingMinutes: 2,
      publishedAt: '2026-10-01',
      sources: [issnProteina],
      body: '''Whey é proteína do leite em pó: um alimento prático, não um remédio.

**Quanto de proteína no dia?** Para quem treina, a recomendação mais usada fica entre 1,4 e 2,0 g por kg de peso por dia, somando comida e suplemento. Para 76 kg, isso dá de 106 a 152 g no dia.

**Quanto por tomada?** Entre 20 e 40 g de proteína por vez costuma ser suficiente. Mais do que isso numa tomada só não traz ganho extra relevante.

**Na prática:** some a proteína das refeições, veja quanto falta e use o whey para completar. Se as refeições já batem a meta, o shake é opcional.''',
    ),
    Article(
      id: 'hora-do-whey',
      title: 'Hora do whey protein',
      summary: 'Existe um horário certo? Menos do que parece.',
      tags: ['whey', 'proteina'],
      readingMinutes: 2,
      publishedAt: '2026-10-01',
      sources: [issnProteina],
      body: '''A tal "janela anabólica" de 30 minutos depois do treino é mais flexível do que se dizia.

O que pesa mais é o **total de proteína do dia** e **distribuir** em tomadas de 20 a 40 g a cada 3 ou 4 horas.

Tomar depois do treino continua sendo uma boa escolha por praticidade. Antes de dormir, uma porção de proteína de digestão lenta (como caseína) também pode ajudar na recuperação.''',
    ),
    Article(
      id: 'creatina-e-rins',
      title: 'Creatina e rins: o que diz a ciência',
      summary: 'Doses usuais são seguras para rins saudáveis, mas o exame pode confundir.',
      tags: ['creatina', 'rins'],
      readingMinutes: 3,
      publishedAt: '2026-10-01',
      sources: [issnCreatina],
      body: '''A creatina é um dos suplementos mais estudados. Em pessoas saudáveis, 3 a 5 g por dia não mostraram prejuízo à função dos rins.

**Por que o exame muda?** O corpo transforma creatina em creatinina, e a creatinina é usada para estimar a função renal (por exemplo, pela fórmula de Cockcroft-Gault). Quem usa creatina pode ter o valor um pouco mais alto sem ter problema nenhum. Avise o médico.

**Quando ter mais cuidado:** se você tem doença renal, diabetes ou pressão alta, ou usa remédios que afetam os rins, converse com um médico antes.

**Saturação:** cerca de 20 g por dia por 5 a 7 dias é um protocolo conhecido, mas não é obrigatório: 3 a 5 g por dia chegam ao mesmo resultado em 3 a 4 semanas.''',
    ),
    Article(
      id: 'sinais-para-parar-e-pedir-ajuda',
      title: 'Sinais que vale parar e pedir ajuda',
      summary: 'Alguns sintomas pedem pausa no uso e avaliação profissional.',
      tags: ['sintomas', 'seguranca'],
      readingMinutes: 2,
      publishedAt: '2026-10-01',
      sources: [sbem, anvisaSuplementos],
      body: '''Registrar como você se sente ajuda a perceber padrões. Alguns sinais pedem atenção:

**Procure atendimento logo (SAMU 192):** dor ou aperto no peito, falta de ar forte, desmaio, palpitação que não passa.

**Pare o uso e marque uma consulta:** urina escura ou em pouca quantidade, pele ou olhos amarelados, inchaço nas pernas, dor de cabeça forte e frequente, acne intensa, queda de cabelo acelerada, mudança de humor marcante.

**Se o humor pesar:** irritação, tristeza ou ansiedade fora do comum também contam. O CVV atende pelo 188, 24 horas.

Leve o seu histórico do Dosis para a consulta: datas, doses e sintomas ajudam muito o profissional.''',
    ),
    Article(
      id: 'como-ler-o-rotulo',
      title: 'Como ler o rótulo de um suplemento',
      summary: 'Porção, quantidade por porção e advertências: o que olhar primeiro.',
      tags: ['rotulo', 'anvisa'],
      readingMinutes: 2,
      publishedAt: '2026-10-01',
      sources: [anvisaSuplementos],
      body: '''1. **Porção:** quanto é uma dose (ex.: 1 scoop de 30 g).
2. **Quantidade por porção:** quanto do ingrediente principal vem em cada porção. Em ômega 3, procure EPA + DHA, não só "óleo de peixe".
3. **Recomendação diária:** quantas porções por dia o fabricante indica. Não ultrapasse.
4. **Lista de ingredientes:** em ordem do que tem mais para o que tem menos.
5. **Lote e validade.**

Desconfie de promessas como "seca em 7 dias" ou "cura": suplemento alimentar só pode usar as alegações aprovadas pela ANVISA.''',
    ),
    Article(
      id: 'hidratacao-e-treino',
      title: 'Hidratação e treino',
      summary: 'Beber antes, durante e depois, sem exagero.',
      tags: ['hidratacao'],
      readingMinutes: 2,
      publishedAt: '2026-10-01',
      sources: [acsmHidratacao],
      body: '''**Antes:** cerca de 5 a 7 ml por kg algumas horas antes do treino (para 76 kg, de 380 a 530 ml).

**Durante:** a meta é não perder mais de 2% do peso em suor. Em treinos longos ou no calor, beba aos poucos.

**Depois:** se você se pesar antes e depois, reponha cerca de 1,5 litro para cada kg perdido, ao longo das horas seguintes.

Urina clara é um bom sinal. Beber água demais, muito acima da sede, também faz mal. A calculadora do Dosis dá uma estimativa geral e não substitui orientação profissional.''',
    ),
    Article(
      id: 'sono-e-recuperacao',
      title: 'Sono e recuperação muscular',
      summary: 'Dormir bem faz parte do treino.',
      tags: ['sono', 'recuperacao'],
      readingMinutes: 2,
      publishedAt: '2026-10-01',
      sources: [aasmSono],
      body: '''Adultos precisam de **7 horas ou mais** de sono por noite, com regularidade.

Durante o sono profundo o corpo faz boa parte da recuperação muscular. Noites curtas seguidas reduzem força, atenção e motivação para treinar.

**Dicas rápidas:** horário regular para deitar e acordar, evitar cafeína nas 6 horas antes de dormir (atenção ao pré-treino à noite) e quarto escuro e fresco.''',
    ),
    Article(
      id: 'anabolizantes-o-que-saber',
      title: 'Anabolizantes: o que saber antes',
      summary: 'Regras, efeitos no corpo e como reduzir riscos se você usa.',
      tags: ['anabolizantes'],
      readingMinutes: 3,
      publishedAt: '2026-10-01',
      sources: [cfm, anvisaControlados, sbem],
      body: '''Esteroides anabolizantes são medicamentos controlados: só podem ser vendidos com receita retida. Desde 2023 o CFM proíbe médicos de prescrevê-los para estética, ganho de massa ou desempenho.

**Efeitos que podem aparecer:** queda da produção natural de testosterona e da fertilidade, acne, queda de cabelo, aumento das mamas em homens, piora do colesterol, pressão alta, alterações no fígado (principalmente nos orais) e mudanças de humor.

**Se você usa:** não esconda do seu médico. Exames periódicos (hemograma, colesterol, função do fígado e dos rins) ajudam a perceber problemas cedo. Registre doses e sintomas no Dosis para ter esse histórico em mãos.''',
    ),
  ];
}

/// Filtro local por tag e por parte do título/resumo. Usado quando não há
/// internet: a lista continua navegável mesmo sem a API.
List<ArticleSummary> filterArticles(List<ArticleSummary> articles, {String? tag, String? search}) {
  var result = articles;
  if (tag != null && tag.trim().isNotEmpty) {
    final wanted = tag.trim().toLowerCase();
    result = result.where((a) => a.tags.any((t) => t.toLowerCase() == wanted)).toList();
  }
  if (search != null && search.trim().isNotEmpty) {
    final term = search.trim().toLowerCase();
    result = result
        .where((a) => a.title.toLowerCase().contains(term) || a.summary.toLowerCase().contains(term))
        .toList();
  }
  return result;
}
