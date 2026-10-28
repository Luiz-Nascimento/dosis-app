"""Valores fixos do domínio, com o rótulo exibido no app (Figma)."""

KIND_CHOICES = [
    ("supplement", "Suplemento"),
    ("anabolic", "Anabolizante"),
]

PROTOCOL_CHOICES = [
    ("continuous", "Uso contínuo"),
    ("loading", "Protocolo de saturação"),
    ("cycle", "Ciclo"),
    ("as_needed", "Quando necessário"),
]

UNIT_CHOICES = [
    ("g", "g"),
    ("mg", "mg"),
    ("mcg", "mcg"),
    ("ml", "ml"),
    ("ui", "UI"),
    ("caps", "cápsulas"),
    ("tabs", "comprimidos"),
    ("drops", "gotas"),
]

BIOLOGICAL_SEX_CHOICES = [
    ("male", "Masculino"),
    ("female", "Feminino"),
    ("undisclosed", "Prefiro não dizer"),
]

GOAL_CHOICES = [
    ("hypertrophy", "Hipertrofia"),
    ("weight_loss", "Emagrecimento"),
    ("performance", "Performance"),
    ("general_health", "Saúde geral"),
]

SYMPTOM_STATUS_CHOICES = [
    ("normal", "Não senti nada de diferente"),
    ("different", "Senti algo diferente"),
]

SYMPTOM_CHOICES = [
    ("pain", "Dor"),
    ("dizziness", "Tontura"),
    ("fatigue", "Cansaço"),
    ("nausea", "Náusea"),
    ("palpitation", "Palpitação"),
    ("hair_loss", "Queda de cabelo"),
    ("acne", "Acne"),
    ("mood_change", "Alteração de humor"),
    ("other", "Outro"),
]
