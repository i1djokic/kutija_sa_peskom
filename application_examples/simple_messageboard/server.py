import os
import re
import time
from collections import defaultdict
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json

DB_TYPE = os.environ.get('DB_TYPE', 'mysql').lower()

if DB_TYPE == 'sqlite':
    import sqlite3

    DB_PATH = os.environ.get('DB_PATH', '/app/data.db')

    def get_conn():
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA foreign_keys=ON")
        conn.isolation_level = None
        return conn

    PLACEHOLDER = '?'

    def _init_db():
        conn = get_conn()
        conn.executescript('''
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                author TEXT DEFAULT NULL,
                content TEXT NOT NULL,
                board TEXT DEFAULT 'general',
                thread_id INTEGER DEFAULT NULL,
                title TEXT DEFAULT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS boards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        ''')
        try:
            conn.execute('ALTER TABLE messages ADD COLUMN reply_to INTEGER DEFAULT NULL')
        except Exception:
            pass
        existing = set()
        for r in conn.execute('SELECT name FROM boards').fetchall():
            existing.add(r['name'])
        for b in DEFAULT_BOARDS:
            if b not in existing:
                conn.execute('INSERT INTO boards (name) VALUES (?)', (b,))
        conn.close()

    def _format_date(d):
        return d.replace('T', ' ')[:19] if d and 'T' in d else d

else:
    import pymysql
    from pymysql.cursors import DictCursor

    DB_HOST = os.environ.get('DB_HOST', 'my-db-mariadb')
    DB_PORT = int(os.environ.get('DB_PORT', 3306))
    DB_USER = os.environ.get('DB_USER', 'root')
    DB_PASSWORD = os.environ.get('DB_PASSWORD', 'changeme')
    DB_NAME = os.environ.get('DB_NAME', 'app')

    def get_conn():
        conn = pymysql.connect(
            host=DB_HOST, port=DB_PORT, user=DB_USER,
            password=DB_PASSWORD, database=DB_NAME,
            cursorclass=DictCursor,
        )
        conn.autocommit(True)
        return conn

    PLACEHOLDER = '%s'

    def _init_db():
        conn = get_conn()
        with conn.cursor() as cur:
            cur.execute('''
                CREATE TABLE IF NOT EXISTS messages (
                    id INTEGER PRIMARY KEY AUTO_INCREMENT,
                    author TEXT DEFAULT NULL,
                    content TEXT NOT NULL,
                    board TEXT DEFAULT 'general',
                    thread_id INTEGER DEFAULT NULL,
                    title TEXT DEFAULT NULL,
                    created_at DATETIME DEFAULT NOW()
                )
            ''')
            cur.execute('''
                CREATE TABLE IF NOT EXISTS boards (
                    id INTEGER PRIMARY KEY AUTO_INCREMENT,
                    name VARCHAR(255) UNIQUE NOT NULL,
                    created_at DATETIME DEFAULT NOW()
                )
            ''')
            try:
                cur.execute('ALTER TABLE messages ADD COLUMN reply_to INTEGER DEFAULT NULL')
            except Exception:
                pass
            existing = set()
            cur.execute('SELECT name FROM boards')
            for r in cur.fetchall():
                existing.add(r['name'])
            for b in DEFAULT_BOARDS:
                if b not in existing:
                    cur.execute(f'INSERT INTO boards (name) VALUES ({PLACEHOLDER})', (b,))
        conn.close()

    def _format_date(d):
        return d.strftime('%Y-%m-%d %H:%M:%S') if d else None

STATIC_DIR = os.path.join(os.path.dirname(__file__), 'src')

MAX_CONTENT_LENGTH = 1024 * 500
MAX_NAME_LENGTH = 100
MAX_CONTENT_LENGTH_FIELD = 2000

RATE_LIMIT_REQUESTS = 10
RATE_LIMIT_WINDOW = 60
_request_log = defaultdict(list)

DEFAULT_BOARDS = ['general', 'random', 'announcements', 'technology', 'offtopic']


def _is_rate_limited(ip):
    now = time.time()
    _request_log[ip] = [t for t in _request_log[ip] if now - t < RATE_LIMIT_WINDOW]
    if len(_request_log[ip]) >= RATE_LIMIT_REQUESTS:
        return True
    _request_log[ip].append(now)
    return False


def board_exists(name):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(f'SELECT id FROM boards WHERE name = {PLACEHOLDER}', (name,))
    row = cur.fetchone()
    conn.close()
    return row is not None


def get_boards():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute('SELECT name FROM boards ORDER BY id ASC')
    rows = cur.fetchall()
    conn.close()
    return [r['name'] for r in rows]


def row_to_dict(d):
    d = dict(d)
    d['name'] = d.pop('author')
    if d.get('created_at'):
        d['created_at'] = _format_date(d['created_at'])
    d['reply_to'] = d.get('reply_to')
    return d


class Handler(BaseHTTPRequestHandler):

    def _send_json(self, data, status=200):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_static(self, path):
        if path == '/' or path == '':
            path = '/index.html'
        file_path = os.path.join(STATIC_DIR, path.lstrip('/'))
        file_path = os.path.normpath(file_path)
        if not file_path.startswith(STATIC_DIR):
            self.send_error(403)
            return
        if not os.path.isfile(file_path):
            self.send_error(404)
            return
        ext_map = {
            '.html': 'text/html',
            '.css': 'text/css',
            '.js': 'application/javascript',
        }
        ext = os.path.splitext(file_path)[1]
        content_type = ext_map.get(ext, 'application/octet-stream')
        with open(file_path, 'rb') as f:
            data = f.read()
        self.send_response(200)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == '/api/threads':
            params = parse_qs(parsed.query)
            board = params.get('board', ['general'])[0]
            if not board_exists(board):
                board = 'general'
            conn = get_conn()
            cur = conn.cursor()
            cur.execute(
                f'SELECT id, author, content, title, board, thread_id, reply_to, created_at FROM messages WHERE board = {PLACEHOLDER} AND thread_id IS NULL ORDER BY created_at DESC',
                (board,)
            )
            ops = cur.fetchall()
            result = []
            for op in ops:
                op_dict = row_to_dict(op)
                cur.execute(f'SELECT COUNT(*) as count FROM messages WHERE thread_id = {PLACEHOLDER}', (op['id'],))
                op_dict['reply_count'] = dict(cur.fetchone())['count']
                cur.execute(
                    f'SELECT id, author, content, title, board, thread_id, reply_to, created_at FROM messages WHERE thread_id = {PLACEHOLDER} ORDER BY created_at ASC LIMIT 3',
                    (op['id'],)
                )
                op_dict['replies'] = [row_to_dict(r) for r in cur.fetchall()]
                result.append(op_dict)
            conn.close()
            self._send_json(result)

        elif path.startswith('/api/thread/'):
            thread_id_str = path.rsplit('/', 1)[-1]
            if not thread_id_str.isdigit():
                self._send_json({'error': 'Invalid thread ID'}, 400)
                return
            thread_id = int(thread_id_str)
            conn = get_conn()
            cur = conn.cursor()
            cur.execute(
                f'SELECT id, author, content, title, board, thread_id, reply_to, created_at FROM messages WHERE id = {PLACEHOLDER}',
                (thread_id,)
            )
            op = cur.fetchone()
            if not op:
                conn.close()
                self._send_json({'error': 'Thread not found'}, 404)
                return
            cur.execute(
                f'SELECT id, author, content, title, board, thread_id, reply_to, created_at FROM messages WHERE thread_id = {PLACEHOLDER} ORDER BY created_at ASC',
                (thread_id,)
            )
            replies = cur.fetchall()
            conn.close()
            result = row_to_dict(op)
            result['replies'] = [row_to_dict(r) for r in replies]
            self._send_json(result)

        elif path == '/api/boards':
            self._send_json(get_boards())

        else:
            self._send_static(parsed.path)

    def do_POST(self):
        client_ip = self.client_address[0]
        if _is_rate_limited(client_ip):
            self._send_json({'error': 'Too many requests'}, 429)
            return

        parsed = urlparse(self.path)
        path = parsed.path

        if path == '/api/boards':
            content_type = self.headers.get('Content-Type', '')
            if content_type != 'application/json':
                self._send_json({'error': 'Content-Type must be application/json'}, 415)
                return
            length = int(self.headers.get('Content-Length', 0))
            if length > MAX_CONTENT_LENGTH:
                self._send_json({'error': 'Request body too large'}, 413)
                return
            body = self.rfile.read(length)
            if not body:
                self._send_json({'error': 'Request body is empty'}, 400)
                return
            try:
                data = json.loads(body)
            except json.JSONDecodeError:
                self._send_json({'error': 'Invalid JSON'}, 400)
                return
            if not isinstance(data, dict):
                self._send_json({'error': 'Request body must be a JSON object'}, 400)
                return
            name = data.get('name', '').strip()
            if not name:
                self._send_json({'error': 'Board name is required'}, 400)
                return
            if not re.match(r'^[a-zA-Z0-9_-]+$', name):
                self._send_json({'error': 'Board name can only contain letters, numbers, hyphens and underscores'}, 400)
                return
            if len(name) > 50:
                self._send_json({'error': 'Board name must be at most 50 characters'}, 400)
                return
            try:
                conn = get_conn()
                cur = conn.cursor()
                cur.execute(f'INSERT INTO boards (name) VALUES ({PLACEHOLDER})', (name,))
                conn.close()
            except Exception:
                self._send_json({'error': 'Board already exists'}, 409)
                return
            self._send_json({'name': name}, 201)

        elif path == '/api/messages':
            content_type = self.headers.get('Content-Type', '')
            if content_type != 'application/json':
                self._send_json({'error': 'Content-Type must be application/json'}, 415)
                return
            length = int(self.headers.get('Content-Length', 0))
            if length > MAX_CONTENT_LENGTH:
                self._send_json({'error': 'Request body too large'}, 413)
                return
            body = self.rfile.read(length)
            if not body:
                self._send_json({'error': 'Request body is empty'}, 400)
                return
            try:
                data = json.loads(body)
            except json.JSONDecodeError:
                self._send_json({'error': 'Invalid JSON'}, 400)
                return
            if not isinstance(data, dict):
                self._send_json({'error': 'Request body must be a JSON object'}, 400)
                return

            name = data.get('name')
            if name is not None:
                if not isinstance(name, str):
                    self._send_json({'error': 'Name must be a string'}, 400)
                    return
                name = name.strip()
                if len(name) > MAX_NAME_LENGTH:
                    self._send_json({'error': f'Name must be at most {MAX_NAME_LENGTH} characters'}, 400)
                    return
                if not name:
                    name = None

            content = data.get('content', '').strip()
            if not isinstance(content, str):
                self._send_json({'error': 'Content must be a string'}, 400)
                return
            if not content:
                self._send_json({'error': 'Content is required'}, 400)
                return
            if len(content) > MAX_CONTENT_LENGTH_FIELD:
                self._send_json({'error': f'Content must be at most {MAX_CONTENT_LENGTH_FIELD} characters'}, 400)
                return

            title = data.get('title')
            if title is not None:
                if not isinstance(title, str):
                    self._send_json({'error': 'Title must be a string'}, 400)
                    return
                title = title.strip()
                if len(title) > MAX_NAME_LENGTH:
                    self._send_json({'error': f'Title must be at most {MAX_NAME_LENGTH} characters'}, 400)
                    return
                if not title:
                    title = None

            board = data.get('board', 'general')
            if not board_exists(board):
                self._send_json({'error': 'Board does not exist'}, 404)
                return

            thread_id = data.get('thread_id')
            if thread_id is not None:
                if not isinstance(thread_id, int):
                    self._send_json({'error': 'thread_id must be an integer'}, 400)
                    return
                check_conn = get_conn()
                cur = check_conn.cursor()
                cur.execute(f'SELECT id, thread_id FROM messages WHERE id = {PLACEHOLDER}', (thread_id,))
                post = cur.fetchone()
                check_conn.close()
                if not post:
                    self._send_json({'error': 'Thread not found'}, 404)
                    return
                if post['thread_id'] is not None:
                    thread_id = post['thread_id']

            reply_to = data.get('reply_to')
            if reply_to is not None:
                if not isinstance(reply_to, int):
                    self._send_json({'error': 'reply_to must be an integer'}, 400)
                    return
                check_conn = get_conn()
                cur = check_conn.cursor()
                cur.execute(f'SELECT id, thread_id FROM messages WHERE id = {PLACEHOLDER}', (reply_to,))
                parent = cur.fetchone()
                check_conn.close()
                if not parent:
                    self._send_json({'error': 'Parent message not found'}, 404)
                    return
                if thread_id is None:
                    thread_id = parent['thread_id'] if parent['thread_id'] is not None else parent['id']
                elif parent['thread_id'] != thread_id and parent['id'] != thread_id:
                    self._send_json({'error': 'Parent message does not belong to this thread'}, 400)
                    return

            conn = get_conn()
            cur = conn.cursor()
            cur.execute(
                f'INSERT INTO messages (author, content, title, board, thread_id, reply_to) VALUES ({PLACEHOLDER}, {PLACEHOLDER}, {PLACEHOLDER}, {PLACEHOLDER}, {PLACEHOLDER}, {PLACEHOLDER})',
                (name, content, title, board, thread_id, reply_to)
            )
            msg_id = cur.lastrowid
            cur.execute(
                f'SELECT id, author, content, title, board, thread_id, reply_to, created_at FROM messages WHERE id = {PLACEHOLDER}',
                (msg_id,)
            )
            row = cur.fetchone()
            conn.close()
            self._send_json(row_to_dict(row), 201)


if __name__ == '__main__':
    retries = 10 if DB_TYPE == 'mysql' else 1
    for i in range(retries):
        try:
            _init_db()
            break
        except Exception as e:
            if i < retries - 1:
                time.sleep(3)
            else:
                raise
    port = int(os.environ.get('PORT', 8000))
    server = HTTPServer(('127.0.0.1', port), Handler)
    print(f'Server running on http://127.0.0.1:{port} with DB_TYPE={DB_TYPE}')
    server.serve_forever()
