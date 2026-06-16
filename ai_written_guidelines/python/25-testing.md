# Testing

## pytest basics

```python
# test_example.py
def test_add():
    assert add(2, 3) == 5

def test_failure():
    with pytest.raises(ValueError):
        validate_port(0)
```

```bash
pytest                          # run all tests
pytest -v                       # verbose
pytest -k "add"                 # filter by name
pytest -x                       # stop on first failure
pytest --tb=short               # shorter tracebacks
pytest --coverage               # requires pytest-cov
```

## Fixtures

```python
import pytest
import tempfile
from pathlib import Path

@pytest.fixture
def temp_dir():
    with tempfile.TemporaryDirectory() as tmp:
        yield Path(tmp)

@pytest.fixture
def config_file(temp_dir):
    path = temp_dir / "config.yaml"
    path.write_text("key: value\n")
    return path

def test_load_config(config_file):
    cfg = load_config(config_file)
    assert cfg["key"] == "value"
```

### Fixture scopes

```python
@pytest.fixture(scope="session")   # once per test session
@pytest.fixture(scope="module")    # once per module
@pytest.fixture(scope="class")     # once per class
@pytest.fixture(scope="function")  # default: once per test
```

## Mocking

```python
from unittest.mock import Mock, patch, PropertyMock

# Mock a function
@patch("mymodule.subprocess.run")
def test_deploy(mock_run):
    mock_run.return_value = Mock(returncode=0, stdout="success", stderr="")
    result = deploy("production")
    assert result is True

# Mock return values
mock_run.return_value.returncode = 0

# Mock side effects (different values per call)
mock_run.side_effect = [
    Mock(returncode=0),
    Mock(returncode=1, stderr="error"),
    subprocess.TimeoutExpired(cmd="test", timeout=10),
]

# Mock an object
class MockService:
    def start(self):
        return True
    def stop(self):
        pass

@patch("mymodule.Service", return_value=MockService())
def test_service_start(mock_service):
    ...
```

## Parametrize

```python
@pytest.mark.parametrize("input,expected", [
    ("hello", 5),
    ("", 0),
    ("a b c", 5),
])
def test_length(input, expected):
    assert len(input) == expected

# Multiple parameter combinations
@pytest.mark.parametrize("env", ["dev", "staging", "prod"])
@pytest.mark.parametrize("dry_run", [True, False])
def test_deploy_params(env, dry_run):
    ...
```

## Temporary files and directories

```python
def test_file_operations(tmp_path):
    d = tmp_path / "subdir"
    d.mkdir()
    f = d / "test.txt"
    f.write_text("content")
    assert f.read_text() == "content"
    assert f.stat().st_size == 7
```

## Testing CLI tools

```python
from click.testing import CliRunner

def test_cli():
    runner = CliRunner()
    result = runner.invoke(cli, ["deploy", "--env", "prod", "--dry-run"])
    assert result.exit_code == 0
    assert "Deploying" in result.output
```

## Code coverage

```bash
pytest --cov=src/ --cov-report=term --cov-report=html
```

## Test directory structure

```
tests/
  conftest.py          # shared fixtures
  test_cli.py
  test_config.py
  test_deploy.py
  fixtures/
    config.yaml
    sample_data.json
```

## Pre-commit test hook

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: pytest
      name: pytest
      entry: pytest
      language: system
      types: [python]
      pass_filenames: false
```
