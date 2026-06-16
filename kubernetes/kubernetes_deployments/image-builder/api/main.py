import os
import json
import uuid
import shutil
import tempfile
import subprocess
import threading
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, request, jsonify, send_from_directory

app = Flask(__name__, static_folder='ui', static_url_path='')

DATA_DIR = Path(os.environ.get("DATA_DIR", "/data"))
DATA_DIR.mkdir(parents=True, exist_ok=True)

JOBS_FILE = DATA_DIR / "jobs.json"
BUILDS_DIR = DATA_DIR / "builds"
BUILDS_DIR.mkdir(parents=True, exist_ok=True)

DOCKER_REGISTRY = os.environ.get("DOCKER_REGISTRY", "127.0.0.1:5000")

# ---------------------------------------------------------------------------
# Persistence helpers
# ---------------------------------------------------------------------------

def _load_json(path):
    if path.exists():
        try:
            with open(path) as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def _save_json(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=2, default=str)

def load_jobs():
    return _load_json(JOBS_FILE)

def save_jobs(data):
    _save_json(JOBS_FILE, data)

def save_build(job_id, build_id, data):
    p = BUILDS_DIR / job_id
    p.mkdir(parents=True, exist_ok=True)
    _save_json(p / f"{build_id}.json", data)

def list_builds_for_job(job_id):
    build_dir = BUILDS_DIR / job_id
    if not build_dir.exists():
        return []
    result = []
    for f in sorted(build_dir.iterdir(), key=lambda p: p.stat().st_mtime, reverse=True):
        if f.suffix == ".json":
            b = _load_json(f)
            b["id"] = f.stem
            result.append(b)
    return result

# ---------------------------------------------------------------------------
# Serve UI
# ---------------------------------------------------------------------------

@app.route("/")
def index():
    return send_from_directory("ui", "index.html")

# ---------------------------------------------------------------------------
# Job CRUD
# ---------------------------------------------------------------------------

@app.route("/api/jobs")
def list_jobs():
    jobs = load_jobs()
    result = []
    for jid, j in jobs.items():
        j["id"] = jid
        builds = list_builds_for_job(jid)
        j["latest_build"] = builds[-1] if builds else None
        result.append(j)
    return jsonify(sorted(result, key=lambda x: x.get("created_at", ""), reverse=True))

@app.route("/api/jobs", methods=["POST"])
def create_job():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Invalid JSON"}), 400
    jid = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    jobs = load_jobs()
    jobs[jid] = {
        "name": data["name"],
        "dockerfile_content": data["dockerfile_content"],
        "image_name": data["image_name"],
        "image_tag": data.get("image_tag", "latest"),
        "created_at": now,
        "updated_at": now,
    }
    save_jobs(jobs)
    return jsonify({"id": jid, **jobs[jid]}), 201

@app.route("/api/jobs/<job_id>")
def get_job(job_id):
    jobs = load_jobs()
    j = jobs.get(job_id)
    if not j:
        return jsonify({"error": "Job not found"}), 404
    j["id"] = job_id
    return jsonify(j)

@app.route("/api/jobs/<job_id>", methods=["PUT"])
def update_job(job_id):
    jobs = load_jobs()
    j = jobs.get(job_id)
    if not j:
        return jsonify({"error": "Job not found"}), 404
    data = request.get_json()
    if not data:
        return jsonify({"error": "Invalid JSON"}), 400
    for field in ("name", "dockerfile_content", "image_name", "image_tag"):
        if field in data and data[field] is not None:
            j[field] = data[field]
    j["updated_at"] = datetime.now(timezone.utc).isoformat()
    save_jobs(jobs)
    return jsonify({"id": job_id, **j})

@app.route("/api/jobs/<job_id>", methods=["DELETE"])
def delete_job(job_id):
    jobs = load_jobs()
    if job_id not in jobs:
        return jsonify({"error": "Job not found"}), 404
    del jobs[job_id]
    save_jobs(jobs)
    build_dir = BUILDS_DIR / job_id
    if build_dir.exists():
        shutil.rmtree(build_dir)
    return jsonify({"ok": True})

# ---------------------------------------------------------------------------
# Builds
# ---------------------------------------------------------------------------

@app.route("/api/jobs/<job_id>/builds")
def get_builds(job_id):
    jobs = load_jobs()
    if job_id not in jobs:
        return jsonify({"error": "Job not found"}), 404
    return jsonify(list_builds_for_job(job_id))

@app.route("/api/builds/<build_id>")
def get_build(build_id):
    for job_dir in BUILDS_DIR.iterdir():
        if job_dir.is_dir():
            path = job_dir / f"{build_id}.json"
            if path.exists():
                b = _load_json(path)
                b["id"] = build_id
                return jsonify(b)
    return jsonify({"error": "Build not found"}), 404

# ---------------------------------------------------------------------------
# Build execution
# ---------------------------------------------------------------------------

def _run_build(job_id, build_id, image_name, image_tag, dockerfile_content):
    full_image = f"{DOCKER_REGISTRY}/{image_name}:{image_tag}"
    build_data = {
        "job_id": job_id,
        "status": "running",
        "started_at": datetime.now(timezone.utc).isoformat(),
        "finished_at": None,
        "log": "",
    }
    save_build(job_id, build_id, build_data)

    tmpdir = None
    try:
        tmpdir = tempfile.mkdtemp(prefix="imgbuild-")
        df_path = os.path.join(tmpdir, "Dockerfile")
        with open(df_path, "w") as f:
            f.write(dockerfile_content)

        def _log(msg):
            build_data["log"] += msg + "\n"
            save_build(job_id, build_id, build_data)

        _log(f"Building: {full_image}")
        _log("--- docker build ---")

        proc = subprocess.Popen(
            ["docker", "build", "-t", full_image, "-f", df_path, tmpdir],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        for line in proc.stdout:
            _log(line.rstrip())
        rc = proc.wait()

        if rc != 0:
            build_data["status"] = "failed"
            build_data["finished_at"] = datetime.now(timezone.utc).isoformat()
            _log(f"Build failed (exit code {rc})")
            save_build(job_id, build_id, build_data)
            return

        _log("--- docker push ---")
        push_proc = subprocess.Popen(
            ["docker", "push", full_image],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        for line in push_proc.stdout:
            _log(line.rstrip())
        push_rc = push_proc.wait()

        if push_rc != 0:
            build_data["status"] = "failed"
            build_data["finished_at"] = datetime.now(timezone.utc).isoformat()
            _log(f"Push failed (exit code {push_rc})")
            save_build(job_id, build_id, build_data)
            return

        build_data["status"] = "success"
        build_data["finished_at"] = datetime.now(timezone.utc).isoformat()
        _log("=== Build and push complete ===")
        save_build(job_id, build_id, build_data)

    except Exception as e:
        build_data["status"] = "failed"
        build_data["finished_at"] = datetime.now(timezone.utc).isoformat()
        build_data["log"] += f"\nERROR: {e}"
        save_build(job_id, build_id, build_data)
    finally:
        if tmpdir:
            shutil.rmtree(tmpdir, ignore_errors=True)


@app.route("/api/jobs/<job_id>/build", methods=["POST"])
def trigger_build(job_id):
    jobs = load_jobs()
    j = jobs.get(job_id)
    if not j:
        return jsonify({"error": "Job not found"}), 404

    build_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    build_data = {
        "job_id": job_id,
        "status": "pending",
        "started_at": None,
        "finished_at": None,
        "log": "",
        "created_at": now,
    }
    save_build(job_id, build_id, build_data)

    t = threading.Thread(
        target=_run_build,
        args=(job_id, build_id, j["image_name"], j["image_tag"], j["dockerfile_content"]),
        daemon=True,
    )
    t.start()

    return jsonify({"build_id": build_id, "job_id": job_id, "status": "pending"})
