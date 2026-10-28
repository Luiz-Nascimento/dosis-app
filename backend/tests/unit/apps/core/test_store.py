from datetime import datetime, timedelta, timezone

import pytest

from apps.core.store import DocumentAlreadyExists, DocumentNotFound, StoreError
from apps.core.store.memory import MemoryStore


@pytest.fixture
def mem():
    return MemoryStore()


def test_set_get_and_merge(mem):
    mem.set("users/u1", {"name": "Rafael", "prefs": {"a": 1}})
    mem.set("users/u1", {"prefs": {"b": 2}}, merge=True)
    assert mem.get("users/u1") == {"name": "Rafael", "prefs": {"a": 1, "b": 2}}
    assert mem.get("users/nao-existe") is None


def test_returned_data_is_a_copy(mem):
    mem.set("users/u1", {"tags": ["a"]})
    mem.get("users/u1")["tags"].append("b")
    assert mem.get("users/u1") == {"tags": ["a"]}


def test_create_fails_when_document_exists(mem):
    mem.create("users/u1", {"x": 1})
    with pytest.raises(DocumentAlreadyExists):
        mem.create("users/u1", {"x": 2})
    assert mem.get("users/u1") == {"x": 1}


def test_update_requires_existing_document(mem):
    with pytest.raises(DocumentNotFound):
        mem.update("users/u1", {"x": 1})


def test_invalid_paths_are_rejected(mem):
    with pytest.raises(ValueError):
        mem.get("users")
    with pytest.raises(ValueError):
        mem.list("users/u1")


def test_list_filters_orders_and_limits(mem):
    base = datetime(2026, 9, 20, tzinfo=timezone.utc)
    for i in range(5):
        mem.set(f"users/u1/doses/d{i}", {"amount": i, "taken_at": base + timedelta(hours=i), "tags": ["x"] if i % 2 else []})
    mem.set("users/u2/doses/outro", {"amount": 99, "taken_at": base})

    docs = mem.list("users/u1/doses", where=[("amount", ">=", 2)], order_by=[("taken_at", "desc")], limit=2)
    assert [d.id for d in docs] == ["d4", "d3"]
    assert [d.id for d in mem.list("users/u1/doses", where=[("tags", "array_contains", "x")])] == ["d1", "d3"]
    assert [d.id for d in mem.list("users/u1/doses", where=[("amount", "in", [0, 4])])] == ["d0", "d4"]


def test_list_ignores_documents_without_order_field(mem):
    mem.set("c/a", {"n": 1})
    mem.set("c/b", {})
    assert [d.id for d in mem.list("c", order_by=[("n", "asc")])] == ["a"]


def test_transaction_applies_all_writes(mem):
    def work(tx):
        assert tx.get("c/a") is None
        tx.create("c/a", {"n": 1})
        tx.set("c/b", {"n": 2})
        return "ok"

    assert mem.run_transaction(work) == "ok"
    assert mem.get("c/a") == {"n": 1} and mem.get("c/b") == {"n": 2}


def test_transaction_is_atomic_when_function_fails(mem):
    def work(tx):
        tx.set("c/a", {"n": 1})
        raise RuntimeError("queda no meio")

    with pytest.raises(RuntimeError):
        mem.run_transaction(work)
    assert mem.get("c/a") is None


def test_transaction_is_atomic_when_create_conflicts(mem):
    mem.set("c/existe", {"n": 0})

    def work(tx):
        tx.set("c/novo", {"n": 1})
        tx.create("c/existe", {"n": 2})

    with pytest.raises(DocumentAlreadyExists):
        mem.run_transaction(work)
    assert mem.get("c/novo") is None
    assert mem.get("c/existe") == {"n": 0}


def test_transaction_rejects_read_after_write(mem):
    def work(tx):
        tx.set("c/a", {"n": 1})
        tx.get("c/a")

    with pytest.raises(StoreError):
        mem.run_transaction(work)


def test_delete_tree_removes_subcollections(mem):
    mem.set("users/u1", {"a": 1})
    mem.set("users/u1/doses/d1", {"a": 1})
    mem.set("users/u10", {"a": 1})
    mem.delete_tree("users/u1")
    assert mem.get("users/u1") is None
    assert mem.get("users/u1/doses/d1") is None
    assert mem.get("users/u10") == {"a": 1}


def test_persistence_survives_restart(tmp_path):
    path = tmp_path / "mock.json"
    when = datetime(2026, 9, 20, 8, 0, tzinfo=timezone.utc)
    MemoryStore(path).set("users/u1", {"when": when, "blob": b"\x00\x01", "nested": {"when": when}})
    reloaded = MemoryStore(path)
    assert reloaded.get("users/u1") == {"when": when, "blob": b"\x00\x01", "nested": {"when": when}}
