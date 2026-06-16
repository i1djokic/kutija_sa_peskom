import pytest


@pytest.mark.parametrize("a, b, expected", [
    (1, 1, 2),
    (2, 3, 5),
    (0, 0, 0),
    (-1, 1, 0),
])
def test_add(a, b, expected):
    assert a + b == expected


@pytest.mark.parametrize("text", ["", "   ", "\n"])
def test_is_blank(text):
    assert not text.strip()
