from io import StringIO

from django.core.management import call_command

from catalog.content import ARTICLES, PRODUCTS


def test_products_are_seeded_and_paginated(client):
    response = client.get("/api/v1/products", {"page_size": 3})
    assert response.status_code == 200
    assert response.data["count"] == len(PRODUCTS)
    assert len(response.data["results"]) == 3
    assert response.data["page"] == 1


def test_products_filter_by_kind_and_search_without_accents(client):
    anabolics = client.get("/api/v1/products", {"kind": "anabolic"}).data["results"]
    assert {p["id"] for p in anabolics} == {"testosterona", "nandrolona", "oxandrolona", "trembolona"}
    assert all(p["requires_medical_supervision"] for p in anabolics)

    found = client.get("/api/v1/products", {"search": "omega"}).data["results"]
    assert [p["name"] for p in found] == ["Ômega 3"]


def test_product_detail_has_dose_ranges_with_sources(client):
    creatina = client.get("/api/v1/products/creatina").data
    protocols = {r["protocol"]: r for r in creatina["dose_ranges"]}
    assert protocols["continuous"]["min"] == 3 and protocols["continuous"]["max"] == 5
    assert protocols["loading"]["sources"][0]["name"] == "ISSN"
    assert {s["name"] for s in creatina["sources"]} >= {"ISSN", "ANVISA"}


def test_unknown_product_returns_404(client):
    response = client.get("/api/v1/products/nao-existe")
    assert response.status_code == 404
    assert response.data["error"]["code"] == "not_found"


def test_articles_list_filter_and_detail(client):
    listing = client.get("/api/v1/articles").data
    assert listing["count"] == len(ARTICLES)
    assert "body" not in listing["results"][0]

    whey = client.get("/api/v1/articles", {"tag": "whey"}).data["results"]
    assert {a["id"] for a in whey} == {"whey-quanto-usar-por-dia", "hora-do-whey"}

    article = client.get("/api/v1/articles/creatina-e-rins").data
    assert "Cockcroft-Gault" in article["body"]
    assert article["sources"][0]["url"].startswith("https://")


def test_catalog_requires_authentication(api):
    assert api.get("/api/v1/products").status_code == 401


def test_seed_command_is_idempotent():
    out = StringIO()
    call_command("seed_content", stdout=out)
    assert "0 documento(s)" in out.getvalue()
    call_command("seed_content", "--overwrite", stdout=out)
    assert f"{len(PRODUCTS) + len(ARTICLES)} documento(s)" in out.getvalue()
