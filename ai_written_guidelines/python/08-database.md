# Database Interaction

## SQLite (built-in, zero config)

```python
import sqlite3

def init_db(path: str = "automation.db") -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    conn.execute("""
        CREATE TABLE IF NOT EXISTS deployments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            version TEXT NOT NULL,
            environment TEXT NOT NULL,
            status TEXT NOT NULL,
            started_at TEXT NOT NULL DEFAULT (datetime('now')),
            finished_at TEXT,
            output TEXT
        )
    """)
    conn.commit()
    return conn

def record_deployment(
    conn: sqlite3.Connection,
    version: str,
    environment: str,
    status: str,
    output: str = "",
) -> int:
    cursor = conn.execute(
        "INSERT INTO deployments (version, environment, status, output) VALUES (?, ?, ?, ?)",
        (version, environment, status, output),
    )
    conn.commit()
    return cursor.lastrowid

def get_deployments(conn: sqlite3.Connection, limit: int = 10) -> list[sqlite3.Row]:
    return conn.execute(
        "SELECT * FROM deployments ORDER BY started_at DESC LIMIT ?",
        (limit,),
    ).fetchall()
```

### Context manager helper

```python
from contextlib import contextmanager

@contextmanager
def get_db(path: str = "automation.db"):
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

# Usage
with get_db() as db:
    db.execute("INSERT INTO tasks (name) VALUES (?)", ("backup",))
    rows = db.execute("SELECT * FROM tasks").fetchall()
```

## PostgreSQL with psycopg2

```bash
pip install psycopg2-binary
```

```python
import psycopg2
from psycopg2.extras import DictCursor

def get_conn(dsn: str | None = None) -> psycopg2.extensions.connection:
    return psycopg2.connect(
        dsn or os.environ["DATABASE_URL"],
        cursor_factory=DictCursor,
    )

def query(conn, sql: str, params: tuple = ()) -> list[dict]:
    with conn.cursor() as cur:
        cur.execute(sql, params)
        if cur.description:
            columns = [desc[0] for desc in cur.description]
            return [dict(zip(columns, row)) for row in cur.fetchall()]
        return []
```

### Connection pool

```python
from psycopg2.pool import SimpleConnectionPool

pool = SimpleConnectionPool(minconn=2, maxconn=10, dsn=DSN)

def query(sql: str, params: tuple = ()) -> list[dict]:
    conn = pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            columns = [desc[0] for desc in cur.description]
            return [dict(zip(columns, row)) for row in cur.fetchall()]
    finally:
        pool.putconn(conn)
```

## SQLAlchemy (ORM and Core)

```bash
pip install sqlalchemy
```

### Core (table-based)

```python
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, DateTime, select
from sqlalchemy.sql import func

engine = create_engine(os.environ["DATABASE_URL"])
metadata = MetaData()

deployments = Table(
    "deployments", metadata,
    Column("id", Integer, primary_key=True),
    Column("version", String, nullable=False),
    Column("environment", String, nullable=False),
    Column("status", String, nullable=False),
    Column("created_at", DateTime, server_default=func.now()),
)

metadata.create_all(engine)

with engine.connect() as conn:
    conn.execute(
        deployments.insert().values(version="v2.1", environment="prod", status="success")
    )
    conn.commit()

    result = conn.execute(
        select(deployments).where(deployments.c.environment == "prod")
    )
    for row in result:
        print(row._mapping)
```

### ORM (class-based)

```python
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, Session

class Base(DeclarativeBase):
    pass

class Deployment(Base):
    __tablename__ = "deployments"

    id: Mapped[int] = mapped_column(primary_key=True)
    version: Mapped[str]
    environment: Mapped[str]
    status: Mapped[str]

    def __repr__(self) -> str:
        return f"Deployment({self.version}, {self.environment}, {self.status})"

engine = create_engine(os.environ["DATABASE_URL"])
Base.metadata.create_all(engine)

with Session(engine) as session:
    session.add(Deployment(version="v2.1", environment="prod", status="success"))
    session.commit()

    for dep in session.query(Deployment).filter_by(environment="prod").all():
        print(dep)
```

## Alembic (database migrations)

```bash
pip install alembic
alembic init alembic
```

```python
# alembic/env.py - configure your engine
from myapp.db import engine
target_metadata = Base.metadata

# Create migration
alembic revision --autogenerate -m "add deployments table"
alembic upgrade head
```

## Use cases in automation

| Use case | Approach |
|----------|----------|
| Track deployment history | SQLite or PostgreSQL |
| Store task/job results | SQLite (simple) or PostgreSQL (multi-node) |
| Configuration store | SQLite with key-value pattern |
| Inventory / asset tracking | PostgreSQL with SQLAlchemy |
| Log aggregation (structured) | PostgreSQL with JSON columns |
| Migrations | Alembic |

## Key-value store pattern (SQLite)

```python
def init_kv(conn):
    conn.execute("""
        CREATE TABLE IF NOT EXISTS kv_store (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at TEXT DEFAULT (datetime('now'))
        )
    """)
    conn.commit()

def kv_get(conn, key: str, default: str | None = None) -> str | None:
    row = conn.execute("SELECT value FROM kv_store WHERE key = ?", (key,)).fetchone()
    return row["value"] if row else default

def kv_set(conn, key: str, value: str) -> None:
    conn.execute("""
        INSERT INTO kv_store (key, value, updated_at)
        VALUES (?, ?, datetime('now'))
        ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at
    """, (key, value))
    conn.commit()
```
