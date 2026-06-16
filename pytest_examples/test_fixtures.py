import pytest


@pytest.fixture
def numbers():
    return [1, 2, 3, 4, 5]


def test_sum(numbers):
    assert sum(numbers) == 15


def test_length(numbers):
    assert len(numbers) == 5


@pytest.fixture
def db_connection():
    conn = {"connected": True}
    yield conn
    conn["connected"] = False


def test_db_connected(db_connection):
    assert db_connection["connected"] is True
