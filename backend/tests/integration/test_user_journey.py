"""Jornada da persona Rafael pelas telas do Figma, de ponta a ponta na API."""

DAY = {"date_from": "2026-09-20", "date_to": "2026-09-20"}


def test_rafael_journey(api, auth_provider):
    # Cadastro (nome, e-mail, senha) e confirmação do e-mail
    session = api.post("/api/v1/auth/register/", {
        "name": "Rafael", "email": "rafael@gmail.com", "password": "senha1234", "accept_terms": True,
    }, format="json").data
    code = auth_provider.outbox[-1].oob_code
    assert api.post("/api/v1/auth/verify-email/confirm/", {"oob_code": code}, format="json").status_code == 204
    session = api.post("/api/v1/auth/refresh/", {"refresh_token": session["refresh_token"]}, format="json").data
    assert session["email_verified"] is True
    api.credentials(HTTP_AUTHORIZATION=f"Bearer {session['id_token']}")

    # Meus dados e objetivo
    profile = api.patch("/api/v1/profile/", {
        "age": 24, "weight_kg": 76, "height_cm": 178, "biological_sex": "male", "goal": "hypertrophy",
    }, format="json").data
    assert profile["name"] == "Rafael"

    # Adicionar à rotina, buscando no catálogo
    creatina = api.get("/api/v1/catalog/products/", {"search": "creat"}).data["results"][0]
    whey = api.get("/api/v1/catalog/products/", {"search": "whey"}).data["results"][0]
    item = api.post("/api/v1/tracking/routine-items/", {
        "product_id": creatina["id"], "schedule_times": ["08:00"],
    }, format="json").data
    whey_item = api.post("/api/v1/tracking/routine-items/", {
        "product_id": whey["id"], "dose_amount": 60,
    }, format="json").data
    assert [i["name"] for i in api.get("/api/v1/tracking/routine-items/", {"active": "true"}).data["results"]] == [
        "Whey Protein", "Creatina monohidratada",
    ]

    # Registrar dose em 3 toques e o alerta "acima da faixa normalmente utilizada"
    dose = api.post("/api/v1/tracking/doses/", {
        "routine_item_id": item["id"], "taken_at": "2026-09-20T08:00:00-03:00",
    }, format="json").data
    high = api.post("/api/v1/tracking/doses/", {
        "routine_item_id": item["id"], "amount": 20, "taken_at": "2026-09-20T20:30:00-03:00",
    }, format="json").data
    ranges = {r["protocol"]: r for r in api.get(f"/api/v1/catalog/products/{creatina['id']}/").data["dose_ranges"]}
    assert dose["amount"] <= ranges["continuous"]["max"] < high["amount"]  # o app mostra o alerta
    assert high["amount"] <= ranges["loading"]["max"]  # "Revisar protocolo": cabe na saturação
    assert ranges["continuous"]["sources"][0]["name"] == "ISSN"

    # Revisar protocolo e registrar o whey
    revised = api.patch(f"/api/v1/tracking/routine-items/{item['id']}/", {
        "protocol": "loading", "dose_amount": 20,
    }, format="json").data
    assert revised["protocol"] == "loading"
    api.post("/api/v1/tracking/doses/", {
        "routine_item_id": whey_item["id"], "taken_at": "2026-09-20T12:00:00-03:00",
    }, format="json")

    # Como se sente hoje? e água
    api.post("/api/v1/tracking/symptoms/", {
        "status": "different", "symptoms": ["dizziness", "fatigue"],
        "notes": "Um pouco tonto e mais cansado que o normal.", "logged_at": "2026-09-20T21:00:00-03:00",
    }, format="json")
    api.post("/api/v1/tracking/hydration/", {
        "amount_ml": 500, "logged_at": "2026-09-20T10:00:00-03:00",
    }, format="json")

    # Registros de 20 de setembro
    doses = api.get("/api/v1/tracking/doses/", DAY).data["results"]
    assert [(d["name"], d["amount"]) for d in doses] == [
        ("Creatina monohidratada", 20), ("Whey Protein", 60), ("Creatina monohidratada", 3),
    ]
    assert api.get("/api/v1/tracking/symptoms/", DAY).data["results"][0]["symptoms"] == ["dizziness", "fatigue"]
    assert api.get("/api/v1/tracking/hydration/", DAY).data["results"][0]["amount_ml"] == 500

    # Artigo sobre creatina, com fontes
    article_id = api.get("/api/v1/catalog/articles/", {"tag": "creatina"}).data["results"][0]["id"]
    assert api.get(f"/api/v1/catalog/articles/{article_id}/").data["sources"]

    # Backup e restauração depois de apagar uma dose sem querer
    backup = api.post("/api/v1/backups/", {}, format="json").data
    assert api.delete(f"/api/v1/tracking/doses/{dose['id']}/").status_code == 204
    api.post(f"/api/v1/backups/{backup['id']}/restore/", {"mode": "merge"}, format="json")
    assert api.get(f"/api/v1/tracking/doses/{dose['id']}/").data["amount"] == 3
