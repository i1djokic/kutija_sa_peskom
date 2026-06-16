def test_assert_truth():
    assert True


def test_assert_equal():
    assert 1 + 1 == 2


def test_assert_in():
    assert "hello" in "hello world"


def test_assert_raises():
    with pytest.raises(ZeroDivisionError):
        1 / 0
