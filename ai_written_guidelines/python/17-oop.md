# Object-Oriented Programming

## Class Basics

```python
class Service:
    """Base class for all services."""

    def __init__(self, name: str, host: str = "localhost") -> None:
        self.name = name
        self.host = host
        self._running = False

    def start(self) -> None:
        self._running = True
        print(f"{self.name} started on {self.host}")

    def stop(self) -> None:
        self._running = False
        print(f"{self.name} stopped")
```

## Inheritance

```python
class HTTPService(Service):
    def __init__(self, name: str, host: str = "localhost", port: int = 8080) -> None:
        super().__init__(name, host)
        self.port = port

    def start(self) -> None:
        super().start()
        print(f"Listening on {self.host}:{self.port}")
```

## Composition over Inheritance

```python
class HealthChecker:
    def check(self) -> bool: ...

class MetricsCollector:
    def collect(self) -> dict: ...

class MonitoringService:
    def __init__(self) -> None:
        self.health = HealthChecker()
        self.metrics = MetricsCollector()

    def run_check(self) -> bool:
        return self.health.check()
```

## Dunder Methods

```python
class Config:
    def __init__(self, data: dict) -> None:
        self._data = data

    def __getitem__(self, key: str) -> str:
        return self._data[key]

    def __setitem__(self, key: str, value: str) -> None:
        self._data[key] = value

    def __contains__(self, key: str) -> bool:
        return key in self._data

    def __repr__(self) -> str:
        return f"Config({self._data!r})"

    def __enter__(self) -> "Config":
        return self

    def __exit__(self, *args) -> None:
        self._data.clear()
```

## Dataclasses (Python 3.7+)

```python
from dataclasses import dataclass, field, asdict

@dataclass
class AppConfig:
    name: str
    host: str = "localhost"
    port: int = 8080
    tags: list[str] = field(default_factory=list)
    env: str = field(default="development", repr=False)

config = AppConfig(name="web", port=9000)
print(asdict(config))
```

## Properties

```python
class Temperature:
    def __init__(self, celsius: float) -> None:
        self._celsius = celsius

    @property
    def celsius(self) -> float:
        return self._celsius

    @celsius.setter
    def celsius(self, value: float) -> None:
        if value < -273.15:
            raise ValueError("Below absolute zero")
        self._celsius = value

    @property
    def fahrenheit(self) -> float:
        return self._celsius * 9/5 + 32
```

## Abstract Base Classes

```python
from abc import ABC, abstractmethod

class BaseRunner(ABC):
    @abstractmethod
    def run(self, command: str) -> int:
        ...

class LocalRunner(BaseRunner):
    def run(self, command: str) -> int:
        import subprocess
        return subprocess.call(command, shell=True)
```

## SOLID in Python (quick reference)

| Principle | Meaning | Python example |
|-----------|---------|----------------|
| **S**ingle Responsibility | One class = one reason to change | Split `Report` and `ReportGenerator` |
| **O**pen/Closed | Open for extension, closed for modification | Use ABCs/Protocols |
| **L**iskov Substitution | Subtypes must be substitutable | Don't weaken preconditions |
| **I**nterface Segregation | Many specific interfaces > one general | Use small ABCs or Protocols |
| **D**ependency Inversion | Depend on abstractions, not concretions | Inject dependencies via `__init__` |

## Protocols (Structural Subtyping, Python 3.8+)

```python
from typing import Protocol

class Runnable(Protocol):
    def run(self) -> None: ...

def execute(item: Runnable) -> None:
    item.run()  # any object with .run() works
```
