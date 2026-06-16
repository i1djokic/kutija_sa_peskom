# Configuration Management

## Environment Variables

```python
import os

# Read
db_url = os.environ.get("DATABASE_URL", "sqlite:///dev.db")
debug = os.environ.get("DEBUG", "false").lower() == "true"

# Set (for subprocesses)
os.environ["MY_VAR"] = "value"

# Unset
os.environ.pop("MY_VAR", None)

# Required
db_url = os.environ["DATABASE_URL"]  # KeyError if missing
```

## python-dotenv

```python
# .env file
DATABASE_URL=postgres://localhost:5432/db
LOG_LEVEL=DEBUG
API_KEY=sk-abc123

# Load
from dotenv import load_dotenv
load_dotenv()  # loads .env (optional, no error if missing)
load_dotenv(".env.production")  # specific file

# Now use os.environ
```

## YAML Config

```yaml
# config.yaml
server:
  host: 0.0.0.0
  port: 8080

logging:
  level: INFO
  file: /var/log/app.log

database:
  url: postgres://localhost:5432/db
  pool_size: 10

features:
  - metrics
  - health_check
```

```python
from pathlib import Path
import yaml

def load_config(path: str = "config.yaml") -> dict:
    with open(path) as f:
        return yaml.safe_load(f)

cfg = load_config()
server_host = cfg["server"]["host"]
```

## Config with dataclasses

```python
from dataclasses import dataclass, field
import os
import yaml
from pathlib import Path

@dataclass
class DatabaseConfig:
    url: str = "sqlite:///dev.db"
    pool_size: int = 5

@dataclass
class AppConfig:
    host: str = "127.0.0.1"
    port: int = 8080
    debug: bool = False
    database: DatabaseConfig = field(default_factory=DatabaseConfig)

    @classmethod
    def from_yaml(cls, path: str) -> "AppConfig":
        with open(path) as f:
            raw = yaml.safe_load(f)
        return cls(**raw.get("app", {}))

    @classmethod
    def from_env(cls) -> "AppConfig":
        return cls(
            host=os.environ.get("HOST", "127.0.0.1"),
            port=int(os.environ.get("PORT", "8080")),
            debug=os.environ.get("DEBUG", "").lower() == "true",
            database=DatabaseConfig(
                url=os.environ.get("DATABASE_URL", "sqlite:///dev.db"),
            ),
        )

# Usage
config = AppConfig.from_yaml("config.yaml")
config = AppConfig.from_env()
```

## Config Merging (layered approach)

```python
def load_config() -> dict:
    config = {}

    # 1. Defaults
    config.update({
        "host": "127.0.0.1",
        "port": 8080,
        "debug": False,
    })

    # 2. YAML file
    config_path = os.environ.get("CONFIG_FILE", "config.yaml")
    if Path(config_path).exists():
        with open(config_path) as f:
            config.update(yaml.safe_load(f))

    # 3. Environment variables override
    if "HOST" in os.environ:
        config["host"] = os.environ["HOST"]
    if "PORT" in os.environ:
        config["port"] = int(os.environ["PORT"])

    return config
```

## Config validation

```python
def validate_config(cfg: dict) -> dict:
    required = ["host", "port"]
    for key in required:
        if key not in cfg:
            raise ConfigError(f"Missing required config: {key}")
    if not isinstance(cfg["port"], int) or not 1 <= cfg["port"] <= 65535:
        raise ConfigError(f"Invalid port: {cfg['port']}")
    return cfg
```

## pydantic Settings (popular in production)

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "MyApp"
    debug: bool = False
    database_url: str = "sqlite:///dev.db"
    api_key: str = ""

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
# Reads from .env file, then env vars, then defaults
```

## Configuration sources precedence

```
CLI args  >  env vars  >  config file  >  defaults
```

## Tips

- Never hardcode secrets; use env vars or secret managers
- Use `.env` for development only; never commit to VCS
- Validate config at startup, fail fast
- Use `os.environ.get()` with defaults for optional settings
- Keep config hierarchical (nested dicts/yaml) for complex apps
- Use `dev`, `staging`, `production` config profiles
