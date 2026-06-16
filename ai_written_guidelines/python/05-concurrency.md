# Concurrency & Async

## When to use what

| Approach | Best for |
|----------|----------|
| `threading` | I/O-bound tasks (HTTP, file I/O, DB queries) |
| `multiprocessing` | CPU-bound tasks (computation, data processing) |
| `asyncio` | High-concurrency I/O (many connections) |
| `concurrent.futures` | High-level interface for thread/process pools |

## threading

```python
import threading
import time

def worker(name: str, delay: float) -> None:
    log.info("Worker %s started", name)
    time.sleep(delay)
    log.info("Worker %s finished", name)

threads = [
    threading.Thread(target=worker, args=("A", 2)),
    threading.Thread(target=worker, args=("B", 1)),
]
for t in threads:
    t.start()
for t in threads:
    t.join()

print("All workers done")
```

### Thread safety with Lock

```python
import threading

class Counter:
    def __init__(self) -> None:
        self._value = 0
        self._lock = threading.Lock()

    def increment(self) -> None:
        with self._lock:
            self._value += 1

    def get(self) -> int:
        with self._lock:
            return self._value
```

### Thread pool

```python
from concurrent.futures import ThreadPoolExecutor, as_completed

def fetch_url(url: str) -> str:
    resp = requests.get(url, timeout=10)
    return resp.text

with ThreadPoolExecutor(max_workers=10) as pool:
    futures = {pool.submit(fetch_url, url): url for url in urls}
    for future in as_completed(futures):
        url = futures[future]
        try:
            data = future.result()
            process(url, data)
        except Exception as e:
            log.error("Failed %s: %s", url, e)
```

## multiprocessing

```python
from multiprocessing import Pool

def cpu_intensive(n: int) -> int:
    return sum(i * i for i in range(n))

with Pool(processes=4) as pool:
    results = pool.map(cpu_intensive, [10_000_000, 20_000_000])
```

### Shared state

```python
from multiprocessing import Value, Array, Manager

# Simple shared values
counter = Value("i", 0)
with counter.get_lock():
    counter.value += 1

# Shared dict/list via Manager
with Manager() as manager:
    shared_dict = manager.dict()
    shared_list = manager.list()
```

## asyncio

```python
import asyncio
import aiohttp  # pip install aiohttp

async def fetch(session: aiohttp.ClientSession, url: str) -> dict:
    async with session.get(url) as resp:
        return await resp.json()

async def main():
    async with aiohttp.ClientSession() as session:
        tasks = [fetch(session, url) for url in urls]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        for result in results:
            if isinstance(result, Exception):
                log.error("Fetch failed: %s", result)

asyncio.run(main())
```

### Async file I/O (aiofiles)

```python
import asyncio
import aiofiles  # pip install aiofiles

async def read_file(path: str) -> str:
    async with aiofiles.open(path) as f:
        return await f.read()
```

### asyncio subprocess

```python
async def run_cmd(cmd: str) -> tuple[int, str]:
    proc = await asyncio.create_subprocess_shell(
        cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await proc.communicate()
    return proc.returncode, stdout.decode()

async def main():
    results = await asyncio.gather(
        run_cmd("sleep 1 && echo done"),
        run_cmd("sleep 2 && echo done"),
    )
```

## concurrent.futures (high-level)

```python
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor, wait

# CPU-bound -> ProcessPoolExecutor
# I/O-bound -> ThreadPoolExecutor

with ThreadPoolExecutor(max_workers=5) as executor:
    futures = [executor.submit(worker, i) for i in range(10)]
    done, not_done = wait(futures, timeout=30)
    for f in done:
        print(f.result())
```

## Common patterns for automation

```python
# Parallel SSH commands
def run_ssh(host: str, cmd: str) -> tuple[str, int]:
    result = subprocess.run(
        ["ssh", host, cmd], capture_output=True, text=True, timeout=30
    )
    return host, result.returncode

with ThreadPoolExecutor(max_workers=10) as pool:
    for host, rc in pool.map(lambda h: run_ssh(h, "uptime"), hosts):
        print(f"{host}: {rc}")

# Parallel health checks
def check_health(host: str, port: int) -> bool:
    try:
        with socket.create_connection((host, port), timeout=5):
            return True
    except OSError:
        return False

with ThreadPoolExecutor(max_workers=20) as pool:
    results = pool.map(lambda h: check_health(h, 80), hosts)
```

## Thread vs Process vs Async

```
              ┌─────────────┐
              │  Work Type  │
              └──────┬──────┘
                     │
          ┌──────────┼──────────┐
          v          v          v
     I/O-bound   CPU-bound  Many I/O
     threading    multiproc  asyncio
```
