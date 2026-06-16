import subprocess
import re
import uuid
import os
from flask import Flask, request, jsonify

ANSI_RE = re.compile(r'\x1B\[[0-?]*[ -/]*[@-~]')

def strip_ansi(s):
    return ANSI_RE.sub('', s)

HERE = os.path.dirname(os.path.abspath(__file__))
UI_DIR = os.path.join(HERE, "..", "ui")

app = Flask(__name__, static_folder=UI_DIR, static_url_path="")

CONVERSATIONS = {}

@app.route("/")
def index():
    return app.send_static_file("index.html")

@app.route("/api/conversations", methods=["POST"])
def create_conversation():
    cid = str(uuid.uuid4())
    CONVERSATIONS[cid] = {"id": cid, "messages": []}
    return jsonify(CONVERSATIONS[cid]), 201

@app.route("/api/conversations/<cid>/chat", methods=["POST"])
def chat(cid):
    if cid not in CONVERSATIONS:
        return jsonify({"error": "Conversation not found"}), 404
    data = request.get_json()
    if not data or "message" not in data:
        return jsonify({"error": "message field required"}), 400
    message = data["message"]
    CONVERSATIONS[cid]["messages"].append({"role": "user", "content": message})
    try:
        proc = subprocess.run(
            ["opencode", "run", "--dangerously-skip-permissions", message],
            capture_output=True, text=True, timeout=180,
        )
        reply = strip_ansi(proc.stdout or proc.stderr or "").strip()
        if not reply or reply.strip("> ") == "":
            reply = ("(opencode is running but needs an AI provider configured. "
                     "Set ANTHROPIC_API_KEY, OPENAI_API_KEY, or run "
                     "`opencode auth login` in the container.)")
    except FileNotFoundError:
        reply = "(opencode CLI not found in container)"
    except subprocess.TimeoutExpired:
        reply = "(request timed out)"
    CONVERSATIONS[cid]["messages"].append({"role": "assistant", "content": reply})
    return jsonify({"reply": reply, "conversation_id": cid})

@app.route("/api/conversations/<cid>/history", methods=["GET"])
def history(cid):
    if cid not in CONVERSATIONS:
        return jsonify({"error": "Conversation not found"}), 404
    return jsonify(CONVERSATIONS[cid])

@app.route("/api/conversations", methods=["GET"])
def list_conversations():
    return jsonify(list(CONVERSATIONS.values()))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
