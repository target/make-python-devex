from example import sum_numbers


def test_universal_truth():
    assert True
    assert 1 == 1
    assert len("len") == 3


def test_sum_numbers():
    assert sum_numbers([1, 2]) == 3
