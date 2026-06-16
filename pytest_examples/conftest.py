import pytest


@pytest.fixture
def shared_data():
    return {"app": "pytest", "version": "8.x"}
