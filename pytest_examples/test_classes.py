import pytest


class TestCalculator:

    def setup_method(self):
        self.values = [10, 20, 30]

    def test_sum(self):
        assert sum(self.values) == 60

    def test_max(self):
        assert max(self.values) == 30

    def test_min(self):
        assert min(self.values) == 10


class TestStringOps:

    @pytest.mark.parametrize("s, expected", [
        ("hello", 5),
        ("", 0),
        ("abc", 3),
    ])
    def test_length(self, s, expected):
        assert len(s) == expected
