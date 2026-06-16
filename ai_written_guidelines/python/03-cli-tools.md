# CLI Tools & Scripting

## Shebang & Entry Point

```python
#!/usr/bin/env python3
"""Tool description."""

def main() -> int:
    ...

if __name__ == "__main__":
    import sys
    sys.exit(main())
```

## argparse (stdlib)

```python
import argparse

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Deploy application",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Examples:\n  deploy.py -e prod --dry-run",
    )
    parser.add_argument(
        "target",
        help="Deployment target",
    )
    parser.add_argument(
        "-e", "--env",
        default="development",
        choices=["development", "staging", "production"],
        help="Environment (default: %(default)s)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simulate without making changes",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="count",
        default=0,
        help="Increase verbosity (-v, -vv)",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=30,
        help="Timeout in seconds (default: %(default)s)",
    )
    return parser.parse_args()
```

## click

```python
# pip install click
import click

@click.group()
@click.option("--verbose", "-v", is_flag=True, help="Verbose output")
@click.pass_context
def cli(ctx: click.Context, verbose: bool) -> None:
    """Deployment automation tool."""
    ctx.ensure_object(dict)
    ctx.obj["verbose"] = verbose

@cli.command()
@click.option("--env", "-e", default="development", help="Environment")
@click.option("--dry-run", is_flag=True, help="Simulate only")
@click.pass_context
def deploy(ctx: click.Context, env: str, dry_run: bool) -> None:
    """Deploy application to environment."""
    click.echo(f"Deploying to {env}")
    if dry_run:
        click.echo("Dry run - no changes made")

@cli.command()
@click.argument("service")
@click.option("--reason", "-r", help="Restart reason")
@click.pass_context
def restart(ctx: click.Context, service: str, reason: str | None) -> None:
    """Restart a service."""
    click.echo(f"Restarting {service}")

if __name__ == "__main__":
    cli()
```

## typer (modern click alternative)

```python
# pip install typer
import typer

app = typer.Typer()

@app.command()
def deploy(
    target: str = typer.Argument(..., help="Deployment target"),
    env: str = typer.Option("development", "-e", "--env", help="Environment"),
    dry_run: bool = typer.Option(False, "--dry-run", help="Simulate only"),
    verbose: bool = typer.Option(False, "-v", "--verbose"),
):
    """Deploy application to environment."""
    typer.echo(f"Deploying {target} to {env}")
    if dry_run:
        typer.echo("Dry run")

@app.command()
def list_services():
    """List all available services."""
    for svc in ["web", "api", "worker"]:
        typer.echo(f"  - {svc}")

if __name__ == "__main__":
    app()
```

## Exit codes

```python
import sys

EXIT_SUCCESS = 0
EXIT_FAILURE = 1
EXIT_CONFIG_ERROR = 2
EXIT_PERMISSION_ERROR = 3

def main() -> int:
    try:
        run()
    except ConfigError as e:
        log.error("Config error: %s", e)
        return EXIT_CONFIG_ERROR
    return EXIT_SUCCESS

sys.exit(main())
```

## Progress indicators

```python
from rich.progress import track  # pip install rich
import time

for step in track(range(5), description="Deploying..."):
    time.sleep(1)  # actual work

# Simple spinner
import itertools
import sys
import threading
import time

class Spinner:
    def __init__(self, message: str = "Working"):
        self._message = message
        self._spin = itertools.cycle("|/-\\")
        self._stop = threading.Event()

    def __enter__(self):
        self._thread = threading.Thread(target=self._spin_task)
        self._thread.start()
        return self

    def __exit__(self, *args):
        self._stop.set()
        self._thread.join()
        sys.stdout.write("\r" + " " * 40 + "\r")
        sys.stdout.flush()

    def _spin_task(self):
        while not self._stop.is_set():
            sys.stdout.write(f"\r{self._message} {next(self._spin)}")
            sys.stdout.flush()
            time.sleep(0.1)

with Spinner("Processing"):
    time.sleep(3)
```

## Rich tracebacks

```python
from rich.traceback import install
install(show_locals=True)
```

## Best practices

- Always return exit codes (`0` for success)
- Support `--dry-run` for destructive operations
- Support `--verbose` / `-v` for debug output
- Use `--help` that actually explains things
- Color output only when stdout is a TTY
- Read input from stdin for pipe compatibility
- Write errors to stderr (`click.echo(msg, err=True)`)
- Use `sys.exit(main())` pattern
