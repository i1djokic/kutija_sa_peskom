# Programming Principles

## SOLID

| Letter | Principle | Meaning |
|--------|-----------|---------|
| **S** | Single Responsibility | A class/module should have one reason to change |
| **O** | Open/Closed | Open for extension, closed for modification |
| **L** | Liskov Substitution | Subtypes must be substitutable for base types |
| **I** | Interface Segregation | Many specific interfaces > one general |
| **D** | Dependency Inversion | Depend on abstractions, not concretions |

### SRP example

```python
# Bad: handles both data and file I/O
class Report:
    def generate(self) -> str: ...
    def save_to_file(self, path: str) -> None: ...

# Good: separated concerns
class ReportGenerator:
    def generate(self) -> str: ...

class ReportWriter:
    def save(self, report: str, path: str) -> None: ...
```

### Dependency Injection

```python
# Bad: hardcoded dependency
class Deployer:
    def deploy(self) -> None:
        runner = LocalRunner()  # tight coupling
        runner.run("deploy.sh")

# Good: injected dependency
class Deployer:
    def __init__(self, runner: Runner) -> None:
        self._runner = runner

    def deploy(self) -> None:
        self._runner.run("deploy.sh")
```

## DRY (Don't Repeat Yourself)

```python
# Bad: duplicated logic
def start_service(name: str) -> None:
    subprocess.run(["systemctl", "start", name], check=True)
    log.info("Started %s", name)

def stop_service(name: str) -> None:
    subprocess.run(["systemctl", "stop", name], check=True)
    log.info("Stopped %s", name)

# Good: single function
def service_action(name: str, action: str) -> None:
    subprocess.run(["systemctl", action, name], check=True)
    log.info("%s %s", action.capitalize(), name)
```

## KISS (Keep It Simple, Stupid)

- Prefer flat over nested
- Prefer simple data structures over custom classes when sufficient
- Prefer stdlib over third-party when possible
- If it's hard to explain, it's probably overcomplicated

## YAGNI (You Ain't Gonna Need It)

- Don't add features "just in case"
- Don't abstract until you have at least 3 concrete use cases
- Premature abstraction is as bad as premature optimization

## Composition over Inheritance

```python
# Inheritance (rigid)
class Service:
    def start(self) -> None: ...
    def stop(self) -> None: ...

class MonitoredService(Service):
    def start(self) -> None:
        super().start()
        log.info("Monitoring started")

# Composition (flexible)
class Service:
    def start(self) -> None: ...

class Monitor:
    def start(self) -> None: ...

class MonitoredService:
    def __init__(self) -> None:
        self._service = Service()
        self._monitor = Monitor()

    def start(self) -> None:
        self._service.start()
        self._monitor.start()
```

## Fail Fast

```python
def deploy(env: str, version: str) -> None:
    if env not in {"dev", "staging", "prod"}:
        raise ValueError(f"Invalid environment: {env}")
    if not re.match(r"^v\d+\.\d+\.\d+$", version):
        raise ValueError(f"Invalid version: {version}")
    # proceed...
```

## Idempotency

```python
# An operation that can be run multiple times with same result
def ensure_directory(path: str) -> None:
    Path(path).mkdir(parents=True, exist_ok=True)

def ensure_user(username: str) -> bool:
    """Create user if doesn't exist. Returns True if created."""
    result = subprocess.run(["id", username], capture_output=True)
    if result.returncode == 0:
        return False  # already exists
    subprocess.run(["useradd", username], check=True)
    return True
```

## Separation of Concerns

```
Layer          Responsibility
─────          ──────────────
CLI            Parse args, call logic
Config         Load/validate configuration
Domain/Business Core logic, no I/O
Infrastructure I/O: files, network, DB
```

## Principle of Least Astonishment

- Follow conventions
- Use standard library patterns
- Match existing code style
- Be consistent with naming

## Summary

```
SOLID  → Maintainable OOP
DRY    → No duplication
KISS   → Simple over clever
YAGNI  → Only what you need now
Fail Fast → Validate early
Idempotency → Safe to retry
Separation → Organize by concern
Least Astonishment → Be predictable
```
