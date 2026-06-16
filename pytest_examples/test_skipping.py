import pytest
import sys


@pytest.mark.skip(reason="not implemented yet")
def test_feature():
    assert False


@pytest.mark.skipif(
    sys.version_info < (3, 10),
    reason="requires Python 3.10+",
)
def test_new_syntax():
    assert True


@pytest.mark.xfail(reason="known bug")
def test_expected_failure():
    assert 1 + 1 == 3
