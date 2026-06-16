import pytest


pytest_plugins = ["conftest"]


def test_shared_fixture(shared_data):
    assert shared_data["app"] == "pytest"
