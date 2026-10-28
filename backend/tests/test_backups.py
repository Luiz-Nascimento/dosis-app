"""KAN-23: backup criptografado dos registros, com restauração."""
import hashlib

import pytest

from backups import archive, service
from core.fields import utcnow


@pytest.fixture(autouse=True)
def fast_scrypt(monkeypatch):
    # Parâmetros menores só para os testes ficarem rápidos.
    monkeypatch.setattr(archive, "SCRYPT_PARAMS", {"n": 2**10, "r": 8, "p": 1})


@pytest.fixture
def data(client):
    item = client.post("/api/v1/routine-items", {"product_id": "creatina", "notes": "Tomar com água"}, format="json").data
    dose = client.post("/api/v1/doses", {"routine_item_id": item["id"]}, format="json").data
    symptom = client.post("/api/v1/symptoms", {"status": "different", "symptoms": ["nausea"]}, format="json").data
    water = client.post("/api/v1/hydration", {"amount_ml": 500}, format="json").data
    client.patch("/api/v1/profile", {"name": "Rafael", "weight_kg": 76}, format="json")
    return {"item": item, "dose": dose, "symptom": symptom, "water": water}


def create(client, **payload):
    response = client.post("/api/v1/backups", payload, format="json")
    assert response.status_code == 201, response.data
    return response.data


def test_create_list_and_detail(client, data):
    backup = create(client)
    assert backup["counts"] == {"routine_items": 1, "dose_logs": 1, "symptom_logs": 1, "hydration_logs": 1}
    assert backup["protected"] is False and backup["reason"] == "manual"
    assert [b["id"] for b in client.get("/api/v1/backups").data["results"]] == [backup["id"]]
    assert client.get(f"/api/v1/backups/{backup['id']}").data == backup


def test_backup_is_stored_encrypted(client, data, store):
    backup = create(client)
    uid = client.session_data["uid"]
    chunks = store.list(f"users/{uid}/backups/{backup['id']}/chunks")
    stored = "".join(c.data["data"] for c in chunks) + str(store.get(f"users/{uid}/backups/{backup['id']}"))
    for secret in ("Creatina", "Tomar com água", "nausea", "Rafael"):
        assert secret not in stored


def test_download_matches_hash(client, data):
    backup = create(client)
    file = client.get(f"/api/v1/backups/{backup['id']}/download")
    assert file.status_code == 200
    assert file["Content-Disposition"].startswith("attachment;")
    assert hashlib.sha256(file.data["ciphertext"].encode()).hexdigest() == backup["sha256"]
    assert file.data["kdf"]["name"] == "server-hkdf"


def test_restore_merge(client, data):
    backup = create(client)
    client.delete(f"/api/v1/doses/{data['dose']['id']}")
    client.patch(f"/api/v1/hydration/{data['water']['id']}", {"amount_ml": 999}, format="json")
    client.patch("/api/v1/profile", {"weight_kg": 80}, format="json")
    extra = client.post("/api/v1/hydration", {"amount_ml": 200}, format="json").data

    response = client.post(f"/api/v1/backups/{backup['id']}/restore", {"mode": "merge"}, format="json")
    assert response.status_code == 200, response.data
    assert response.data["restored"]["dose_logs"] == 1

    assert client.get(f"/api/v1/doses/{data['dose']['id']}").data["amount"] == 3
    assert client.get(f"/api/v1/hydration/{data['water']['id']}").data["amount_ml"] == 500
    assert client.get(f"/api/v1/hydration/{extra['id']}").status_code == 200  # mesclar mantém o que é novo
    assert client.get("/api/v1/profile").data["weight_kg"] == 76
    restored_dose = client.get(f"/api/v1/doses/{data['dose']['id']}").data
    assert restored_dose["created_at"] == data["dose"]["created_at"]  # datas originais preservadas


def test_restore_replace_and_safety_backup(client, data):
    backup = create(client)
    extra = client.post("/api/v1/hydration", {"amount_ml": 200}, format="json").data
    result = client.post(f"/api/v1/backups/{backup['id']}/restore", {"mode": "replace"}, format="json").data
    assert client.get(f"/api/v1/hydration/{extra['id']}").status_code == 404

    safety = client.get(f"/api/v1/backups/{result['safety_backup_id']}").data
    assert safety["reason"] == "pre_restore"
    assert safety["counts"]["hydration_logs"] == 2  # dá para desfazer

    client.post(f"/api/v1/backups/{safety['id']}/restore", {"mode": "replace"}, format="json")
    assert client.get(f"/api/v1/hydration/{extra['id']}").status_code == 200


def test_passphrase_protected_backup(client, data):
    backup = create(client, passphrase="minha-senha-forte")
    assert backup["protected"] is True
    url = f"/api/v1/backups/{backup['id']}/restore"

    missing = client.post(url, {}, format="json")
    assert missing.data["error"]["code"] == "passphrase_required"
    wrong = client.post(url, {"passphrase": "outra-senha"}, format="json")
    assert wrong.data["error"]["code"] == "invalid_passphrase"
    assert client.post(url, {"passphrase": "minha-senha-forte"}, format="json").status_code == 200

    short = client.post("/api/v1/backups", {"passphrase": "curta"}, format="json")
    assert short.status_code == 400


def test_protected_file_can_move_to_another_account(client, data, make_client):
    backup = create(client, passphrase="minha-senha-forte")
    file = client.get(f"/api/v1/backups/{backup['id']}/download").data

    other = make_client()
    response = other.post(
        "/api/v1/backups/restore", {"file": file, "passphrase": "minha-senha-forte"}, format="json"
    )
    assert response.status_code == 200, response.data
    assert other.get(f"/api/v1/doses/{data['dose']['id']}").data["name"] == "Creatina monohidratada"
    assert other.get("/api/v1/profile").data["weight_kg"] == 76


def test_server_key_file_only_restores_in_same_account(client, data, make_client):
    backup = create(client)
    file = client.get(f"/api/v1/backups/{backup['id']}/download").data
    other = make_client()
    response = other.post("/api/v1/backups/restore", {"file": file}, format="json")
    assert response.status_code == 400
    assert response.data["error"]["code"] == "invalid_backup"
    assert client.post("/api/v1/backups/restore", {"file": file}, format="json").status_code == 200


def test_tampered_file_is_refused(client, data):
    backup = create(client)
    file = client.get(f"/api/v1/backups/{backup['id']}/download").data
    ciphertext = list(file["ciphertext"])
    ciphertext[20] = "A" if ciphertext[20] != "A" else "B"
    file["ciphertext"] = "".join(ciphertext)
    response = client.post("/api/v1/backups/restore", {"file": file}, format="json")
    assert response.data["error"]["code"] == "invalid_backup"


def test_crafted_backup_cannot_escape_user_tree(client, store):
    uid = client.session_data["uid"]
    content = {
        "format": archive.FORMAT,
        "version": archive.VERSION,
        "exported_at": utcnow(),
        "profile": {"name": "Ok"},
        "collections": {
            "hydration_logs": [
                {"id": "valido123", "amount_ml": 300, "is_admin": True},
                {"id": "../../outro/usuario", "amount_ml": 1},
                "lixo",
            ],
        },
    }
    file = archive.seal(uid, "arquivo1", content, passphrase="minha-senha-forte")
    response = client.post(
        "/api/v1/backups/restore", {"file": file, "passphrase": "minha-senha-forte"}, format="json"
    )
    assert response.status_code == 200, response.data
    assert response.data["restored"]["hydration_logs"] == 1
    assert "is_admin" not in store.get(f"users/{uid}/hydration_logs/valido123")


def test_large_backup_is_split_in_chunks(client, data, store, monkeypatch):
    monkeypatch.setattr(service, "CHUNK_CHARS", 100)
    backup = create(client)
    assert len(store.list(f"users/{client.session_data['uid']}/backups/{backup['id']}/chunks")) > 1
    assert client.post(f"/api/v1/backups/{backup['id']}/restore", {}, format="json").status_code == 200


def test_old_backups_are_pruned(client, settings):
    settings.BACKUP_MAX_PER_USER = 2
    ids = [create(client)["id"] for _ in range(3)]
    remaining = [b["id"] for b in client.get("/api/v1/backups").data["results"]]
    assert remaining == [ids[2], ids[1]]


def test_delete_and_isolation(client, data, make_client):
    backup = create(client)
    other = make_client()
    assert other.get(f"/api/v1/backups/{backup['id']}").status_code == 404
    assert other.get(f"/api/v1/backups/{backup['id']}/download").status_code == 404
    assert other.post(f"/api/v1/backups/{backup['id']}/restore", {}, format="json").status_code == 404

    assert client.delete(f"/api/v1/backups/{backup['id']}").status_code == 204
    assert client.get(f"/api/v1/backups/{backup['id']}").status_code == 404
