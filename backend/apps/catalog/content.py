"""Conteúdo inicial do catálogo de produtos e dos artigos educativos.

As faixas de dose servem de referência para o app comparar com o que o
usuário registrou e avisar, sem bloquear, quando a dose sai da faixa usual.
Cada faixa aponta para a fonte que o alerta deve citar. Para anabolizantes não
existe faixa "segura" de uso sem prescrição, então eles não têm faixa e são
marcados como de uso exclusivo com acompanhamento médico.

Revise este arquivo com cuidado antes de mudar valores: é o que o usuário lê.
"""

SOURCES = {
    "issn-creatina-2017": {
        "name": "ISSN",
        "citation": (
            "Kreider RB et al. International Society of Sports Nutrition position stand: safety and "
            "efficacy of creatine supplementation in exercise, sport, and medicine. "
            "J Int Soc Sports Nutr. 2017;14:18."
        ),
        "url": "https://doi.org/10.1186/s12970-017-0173-z",
    },
    "issn-proteina-2017": {
        "name": "ISSN",
        "citation": (
            "Jäger R et al. International Society of Sports Nutrition Position Stand: protein and "
            "exercise. J Int Soc Sports Nutr. 2017;14:20."
        ),
        "url": "https://doi.org/10.1186/s12970-017-0177-8",
    },
    "efsa-omega3-2012": {
        "name": "EFSA",
        "citation": (
            "EFSA NDA Panel. Scientific Opinion related to the Tolerable Upper Intake Level of EPA, "
            "DHA and DPA. EFSA Journal 2012;10(7):2815."
        ),
        "url": "https://doi.org/10.2903/j.efsa.2012.2815",
    },
    "anvisa-suplementos": {
        "name": "ANVISA",
        "citation": (
            "ANVISA. RDC nº 243/2018 e Instrução Normativa nº 28/2018: requisitos sanitários, "
            "constituintes, limites de uso e alegações de suplementos alimentares."
        ),
        "url": "https://www.gov.br/anvisa/pt-br/assuntos/alimentos/suplementos-alimentares",
    },
    "anvisa-controlados": {
        "name": "ANVISA",
        "citation": (
            "Portaria SVS/MS nº 344/1998 (anabolizantes na lista C5 de controle especial) e "
            "Lei nº 9.965/2000 (venda de anabolizantes só com receita retida)."
        ),
        "url": "https://www.gov.br/anvisa/pt-br",
    },
    "cfm-2333-2023": {
        "name": "CFM",
        "citation": (
            "Conselho Federal de Medicina. Resolução nº 2.333/2023: veda a prescrição de esteroides "
            "anabolizantes com finalidade estética, de ganho de massa muscular ou de desempenho esportivo."
        ),
        "url": "https://portal.cfm.org.br",
    },
    "sbem": {
        "name": "SBEM",
        "citation": "Sociedade Brasileira de Endocrinologia e Metabologia: orientações sobre esteroides anabolizantes.",
        "url": "https://www.endocrino.org.br",
    },
    "acsm-hidratacao-2007": {
        "name": "ACSM",
        "citation": (
            "Sawka MN et al. American College of Sports Medicine position stand: exercise and fluid "
            "replacement. Med Sci Sports Exerc. 2007;39(2):377-390."
        ),
        "url": "https://doi.org/10.1249/mss.0b013e31802ca597",
    },
    "aasm-sono-2015": {
        "name": "AASM/SRS",
        "citation": (
            "Watson NF et al. Recommended Amount of Sleep for a Healthy Adult: a joint consensus "
            "statement of the AASM and SRS. Sleep. 2015;38(6):843-844."
        ),
        "url": "https://doi.org/10.5665/sleep.4716",
    },
}

ANABOLIC_CAUTION = (
    "Uso apenas com prescrição e acompanhamento médico. O CFM veda a prescrição para fins estéticos ou "
    "de desempenho. Pode afetar coração, fígado, fertilidade, pele e humor; exames periódicos ajudam a "
    "perceber alterações cedo."
)

PRODUCTS = [
    {
        "id": "creatina",
        "name": "Creatina monohidratada",
        "kind": "supplement",
        "default_unit": "g",
        "default_dose": 3,
        "dose_ranges": [
            {
                "protocol": "continuous",
                "per": "day",
                "min": 3,
                "max": 5,
                "unit": "g",
                "note": "Manutenção: 3 a 5 g por dia.",
                "source_ids": ["issn-creatina-2017"],
            },
            {
                "protocol": "loading",
                "per": "day",
                "min": 15,
                "max": 25,
                "unit": "g",
                "note": "Saturação: cerca de 0,3 g/kg por dia, em 4 tomadas, por 5 a 7 dias.",
                "source_ids": ["issn-creatina-2017"],
            },
        ],
        "caution": (
            "Em pessoas saudáveis, as doses usuais não mostraram prejuízo aos rins. Quem tem doença renal "
            "deve conversar com um médico antes. A creatina pode elevar a creatinina no exame de sangue: "
            "avise o médico que você usa."
        ),
        "requires_medical_supervision": False,
        "source_ids": ["issn-creatina-2017", "anvisa-suplementos"],
    },
    {
        "id": "whey-protein",
        "name": "Whey Protein",
        "kind": "supplement",
        "default_unit": "g",
        "default_dose": 30,
        "dose_ranges": [
            {
                "protocol": "continuous",
                "per": "dose",
                "min": 20,
                "max": 40,
                "unit": "g",
                "note": "Por tomada. O total de proteína do dia (comida + suplemento) costuma ficar entre 1,4 e 2,0 g/kg.",
                "source_ids": ["issn-proteina-2017"],
            },
        ],
        "caution": "É alimento: conta no total de proteína do dia junto com as refeições.",
        "requires_medical_supervision": False,
        "source_ids": ["issn-proteina-2017", "anvisa-suplementos"],
    },
    {
        "id": "omega-3",
        "name": "Ômega 3",
        "kind": "supplement",
        "default_unit": "mg",
        "default_dose": 1000,
        "dose_ranges": [
            {
                "protocol": "continuous",
                "per": "day",
                "min": 250,
                "max": 5000,
                "unit": "mg",
                "note": "Quantidade de EPA + DHA (veja no rótulo), não do óleo total.",
                "source_ids": ["efsa-omega3-2012"],
            },
        ],
        "caution": "Quem usa anticoagulante deve conversar com o médico antes de doses altas.",
        "requires_medical_supervision": False,
        "source_ids": ["efsa-omega3-2012", "anvisa-suplementos"],
    },
    {
        "id": "bcaa",
        "name": "BCAA",
        "kind": "supplement",
        "default_unit": "g",
        "default_dose": 5,
        "dose_ranges": [],
        "caution": "Se você já consome proteína suficiente no dia, o ganho extra do BCAA tende a ser pequeno.",
        "requires_medical_supervision": False,
        "source_ids": ["issn-proteina-2017", "anvisa-suplementos"],
    },
    {
        "id": "hipercalorico",
        "name": "Hipercalórico",
        "kind": "supplement",
        "default_unit": "g",
        "default_dose": None,
        "dose_ranges": [],
        "caution": "Siga a porção do rótulo e lembre que as calorias entram no total do dia.",
        "requires_medical_supervision": False,
        "source_ids": ["anvisa-suplementos"],
    },
    {
        "id": "multivitaminico",
        "name": "Multivitamínico",
        "kind": "supplement",
        "default_unit": "caps",
        "default_dose": 1,
        "dose_ranges": [],
        "caution": "Siga a porção do rótulo: vitaminas A, D, E e K se acumulam no corpo em doses altas.",
        "requires_medical_supervision": False,
        "source_ids": ["anvisa-suplementos"],
    },
    {
        "id": "testosterona",
        "name": "Testosterona",
        "kind": "anabolic",
        "default_unit": "mg",
        "default_dose": None,
        "dose_ranges": [],
        "caution": ANABOLIC_CAUTION,
        "requires_medical_supervision": True,
        "source_ids": ["cfm-2333-2023", "anvisa-controlados", "sbem"],
    },
    {
        "id": "nandrolona",
        "name": "Nandrolona",
        "kind": "anabolic",
        "default_unit": "mg",
        "default_dose": None,
        "dose_ranges": [],
        "caution": ANABOLIC_CAUTION,
        "requires_medical_supervision": True,
        "source_ids": ["cfm-2333-2023", "anvisa-controlados", "sbem"],
    },
    {
        "id": "oxandrolona",
        "name": "Oxandrolona",
        "kind": "anabolic",
        "default_unit": "mg",
        "default_dose": None,
        "dose_ranges": [],
        "caution": ANABOLIC_CAUTION + " Por ser oral, exige atenção especial ao fígado.",
        "requires_medical_supervision": True,
        "source_ids": ["cfm-2333-2023", "anvisa-controlados", "sbem"],
    },
    {
        "id": "trembolona",
        "name": "Trembolona",
        "kind": "anabolic",
        "default_unit": "mg",
        "default_dose": None,
        "dose_ranges": [],
        "caution": "Não tem uso aprovado em humanos. " + ANABOLIC_CAUTION,
        "requires_medical_supervision": True,
        "source_ids": ["cfm-2333-2023", "anvisa-controlados", "sbem"],
    },
]

ARTICLES = [
    {
        "id": "whey-quanto-usar-por-dia",
        "title": "Whey Protein: quanto usar por dia?",
        "summary": "O que importa é o total de proteína do dia, não só o shake.",
        "tags": ["whey", "proteina"],
        "reading_minutes": 2,
        "published_at": "2026-10-01",
        "source_ids": ["issn-proteina-2017"],
        "body": (
            "Whey é proteína do leite em pó: um alimento prático, não um remédio.\n\n"
            "**Quanto de proteína no dia?** Para quem treina, a recomendação mais usada fica entre "
            "1,4 e 2,0 g por kg de peso por dia, somando comida e suplemento. Para 76 kg, isso dá "
            "de 106 a 152 g no dia.\n\n"
            "**Quanto por tomada?** Entre 20 e 40 g de proteína por vez costuma ser suficiente. Mais "
            "do que isso numa tomada só não traz ganho extra relevante.\n\n"
            "**Na prática:** some a proteína das refeições, veja quanto falta e use o whey para "
            "completar. Se as refeições já batem a meta, o shake é opcional."
        ),
    },
    {
        "id": "hora-do-whey",
        "title": "Hora do whey protein",
        "summary": "Existe um horário certo? Menos do que parece.",
        "tags": ["whey", "proteina"],
        "reading_minutes": 2,
        "published_at": "2026-10-01",
        "source_ids": ["issn-proteina-2017"],
        "body": (
            "A tal \"janela anabólica\" de 30 minutos depois do treino é mais flexível do que se dizia.\n\n"
            "O que pesa mais é o **total de proteína do dia** e **distribuir** em tomadas de 20 a 40 g "
            "a cada 3 ou 4 horas.\n\n"
            "Tomar depois do treino continua sendo uma boa escolha por praticidade. Antes de dormir, "
            "uma porção de proteína de digestão lenta (como caseína) também pode ajudar na recuperação."
        ),
    },
    {
        "id": "creatina-e-rins",
        "title": "Creatina e rins: o que diz a ciência",
        "summary": "Doses usuais são seguras para rins saudáveis, mas o exame pode confundir.",
        "tags": ["creatina", "rins"],
        "reading_minutes": 3,
        "published_at": "2026-10-01",
        "source_ids": ["issn-creatina-2017"],
        "body": (
            "A creatina é um dos suplementos mais estudados. Em pessoas saudáveis, 3 a 5 g por dia não "
            "mostraram prejuízo à função dos rins.\n\n"
            "**Por que o exame muda?** O corpo transforma creatina em creatinina, e a creatinina é usada "
            "para estimar a função renal (por exemplo, pela fórmula de Cockcroft-Gault). Quem usa "
            "creatina pode ter o valor um pouco mais alto sem ter problema nenhum. Avise o médico.\n\n"
            "**Quando ter mais cuidado:** se você tem doença renal, diabetes ou pressão alta, ou usa "
            "remédios que afetam os rins, converse com um médico antes.\n\n"
            "**Saturação:** cerca de 20 g por dia por 5 a 7 dias é um protocolo conhecido, mas não é "
            "obrigatório: 3 a 5 g por dia chegam ao mesmo resultado em 3 a 4 semanas."
        ),
    },
    {
        "id": "sinais-para-parar-e-pedir-ajuda",
        "title": "Sinais que vale parar e pedir ajuda",
        "summary": "Alguns sintomas pedem pausa no uso e avaliação profissional.",
        "tags": ["sintomas", "seguranca"],
        "reading_minutes": 2,
        "published_at": "2026-10-01",
        "source_ids": ["sbem", "anvisa-suplementos"],
        "body": (
            "Registrar como você se sente ajuda a perceber padrões. Alguns sinais pedem atenção:\n\n"
            "**Procure atendimento logo (SAMU 192):** dor ou aperto no peito, falta de ar forte, "
            "desmaio, palpitação que não passa.\n\n"
            "**Pare o uso e marque uma consulta:** urina escura ou em pouca quantidade, pele ou olhos "
            "amarelados, inchaço nas pernas, dor de cabeça forte e frequente, acne intensa, queda de "
            "cabelo acelerada, mudança de humor marcante.\n\n"
            "**Se o humor pesar:** irritação, tristeza ou ansiedade fora do comum também contam. O CVV "
            "atende pelo 188, 24 horas.\n\n"
            "Leve o seu histórico do Dosis para a consulta: datas, doses e sintomas ajudam muito o "
            "profissional."
        ),
    },
    {
        "id": "como-ler-o-rotulo",
        "title": "Como ler o rótulo de um suplemento",
        "summary": "Porção, quantidade por porção e advertências: o que olhar primeiro.",
        "tags": ["rotulo", "anvisa"],
        "reading_minutes": 2,
        "published_at": "2026-10-01",
        "source_ids": ["anvisa-suplementos"],
        "body": (
            "1. **Porção:** quanto é uma dose (ex.: 1 scoop de 30 g).\n"
            "2. **Quantidade por porção:** quanto do ingrediente principal vem em cada porção. Em ômega 3, "
            "procure EPA + DHA, não só \"óleo de peixe\".\n"
            "3. **Recomendação diária:** quantas porções por dia o fabricante indica. Não ultrapasse.\n"
            "4. **Lista de ingredientes:** em ordem do que tem mais para o que tem menos.\n"
            "5. **Lote e validade.**\n\n"
            "Desconfie de promessas como \"seca em 7 dias\" ou \"cura\": suplemento alimentar só pode "
            "usar as alegações aprovadas pela ANVISA."
        ),
    },
    {
        "id": "hidratacao-e-treino",
        "title": "Hidratação e treino",
        "summary": "Beber antes, durante e depois, sem exagero.",
        "tags": ["hidratacao"],
        "reading_minutes": 2,
        "published_at": "2026-10-01",
        "source_ids": ["acsm-hidratacao-2007"],
        "body": (
            "**Antes:** cerca de 5 a 7 ml por kg algumas horas antes do treino (para 76 kg, de 380 a "
            "530 ml).\n\n"
            "**Durante:** a meta é não perder mais de 2% do peso em suor. Em treinos longos ou no calor, "
            "beba aos poucos.\n\n"
            "**Depois:** se você se pesar antes e depois, reponha cerca de 1,5 litro para cada kg "
            "perdido, ao longo das horas seguintes.\n\n"
            "Urina clara é um bom sinal. Beber água demais, muito acima da sede, também faz mal. A "
            "calculadora do Dosis dá uma estimativa geral e não substitui orientação profissional."
        ),
    },
    {
        "id": "sono-e-recuperacao",
        "title": "Sono e recuperação muscular",
        "summary": "Dormir bem faz parte do treino.",
        "tags": ["sono", "recuperacao"],
        "reading_minutes": 2,
        "published_at": "2026-10-01",
        "source_ids": ["aasm-sono-2015"],
        "body": (
            "Adultos precisam de **7 horas ou mais** de sono por noite, com regularidade.\n\n"
            "Durante o sono profundo o corpo faz boa parte da recuperação muscular. Noites curtas "
            "seguidas reduzem força, atenção e motivação para treinar.\n\n"
            "**Dicas rápidas:** horário regular para deitar e acordar, evitar cafeína nas 6 horas antes "
            "de dormir (atenção ao pré-treino à noite) e quarto escuro e fresco."
        ),
    },
    {
        "id": "anabolizantes-o-que-saber",
        "title": "Anabolizantes: o que saber antes",
        "summary": "Regras, efeitos no corpo e como reduzir riscos se você usa.",
        "tags": ["anabolizantes"],
        "reading_minutes": 3,
        "published_at": "2026-10-01",
        "source_ids": ["cfm-2333-2023", "anvisa-controlados", "sbem"],
        "body": (
            "Esteroides anabolizantes são medicamentos controlados: só podem ser vendidos com receita "
            "retida. Desde 2023 o CFM proíbe médicos de prescrevê-los para estética, ganho de massa ou "
            "desempenho.\n\n"
            "**Efeitos que podem aparecer:** queda da produção natural de testosterona e da fertilidade, "
            "acne, queda de cabelo, aumento das mamas em homens, piora do colesterol, pressão alta, "
            "alterações no fígado (principalmente nos orais) e mudanças de humor.\n\n"
            "**Se você usa:** não esconda do seu médico. Exames periódicos (hemograma, colesterol, "
            "função do fígado e dos rins) ajudam a perceber problemas cedo. Registre doses e sintomas "
            "no Dosis para ter esse histórico em mãos."
        ),
    },
]
