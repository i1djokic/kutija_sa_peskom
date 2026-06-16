const API_BASE = '/api';
const messagesEl = document.getElementById('messages');
const messageInput = document.getElementById('messageInput');
const sendBtn = document.getElementById('sendBtn');
const newChatBtn = document.getElementById('newChatBtn');
const convList = document.getElementById('convList');
const loadingOverlay = document.getElementById('loadingOverlay');

let currentConvId = null;
let conversations = [];

async function api(method, url, body) {
  const opts = { method, headers: {} };
  if (body) {
    opts.headers['Content-Type'] = 'application/json';
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(url, opts);
  const text = await res.text();
  if (!res.ok) throw new Error(text);
  return JSON.parse(text);
}

async function createConversation() {
  const conv = await api('POST', `${API_BASE}/conversations`);
  currentConvId = conv.id;
  renderMessages();
  await loadConversations();
}

async function loadConversations() {
  conversations = await api('GET', `${API_BASE}/conversations`);
  convList.innerHTML = '';
  for (const conv of conversations) {
    const div = document.createElement('div');
    div.className = 'conv-item' + (conv.id === currentConvId ? ' active' : '');
    const msg = conv.messages.find(m => m.role === 'user');
    div.textContent = msg ? msg.content.slice(0, 40) + (msg.content.length > 40 ? '...' : '') : 'Empty chat';
    div.addEventListener('click', () => switchConversation(conv.id));
    convList.appendChild(div);
  }
}

async function switchConversation(cid) {
  currentConvId = cid;
  renderMessages();
  const items = convList.querySelectorAll('.conv-item');
  items.forEach(el => el.classList.remove('active'));
  const idx = conversations.findIndex(c => c.id === cid);
  if (idx !== -1 && convList.children[idx]) convList.children[idx].classList.add('active');
}

async function renderMessages() {
  if (!currentConvId) {
    messagesEl.innerHTML = '<div class="welcome"><h2>opencode Chat</h2><p>Click "New Chat" to start a conversation.</p></div>';
    return;
  }
  try {
    const conv = await api('GET', `${API_BASE}/conversations/${currentConvId}/history`);
    messagesEl.innerHTML = conv.messages.length === 0
      ? '<div class="welcome"><h2>New conversation</h2><p>Type a message to start chatting with opencode.</p></div>'
      : conv.messages.map(m => `<div class="message ${m.role}">${escapeHtml(m.content)}</div>`).join('');
    messagesEl.scrollTop = messagesEl.scrollHeight;
  } catch {
    messagesEl.innerHTML = '<div class="message system">Failed to load conversation.</div>';
  }
}

function escapeHtml(s) {
  const d = document.createElement('div');
  d.textContent = s;
  return d.innerHTML;
}

async function sendMessage() {
  const text = messageInput.value.trim();
  if (!text) return;
  if (!currentConvId) {
    const conv = await api('POST', `${API_BASE}/conversations`);
    currentConvId = conv.id;
  }
  messageInput.value = '';
  renderMessage('user', text);
  loadingOverlay.classList.remove('hidden');
  try {
    const result = await api('POST', `${API_BASE}/conversations/${currentConvId}/chat`, { message: text });
    renderMessage('assistant', result.reply);
    await loadConversations();
  } catch (err) {
    renderMessage('system', 'Error: ' + err.message);
  } finally {
    loadingOverlay.classList.add('hidden');
  }
}

function renderMessage(role, content) {
  const welcome = messagesEl.querySelector('.welcome');
  if (welcome) welcome.remove();
  const div = document.createElement('div');
  div.className = `message ${role}`;
  div.textContent = content;
  messagesEl.appendChild(div);
  messagesEl.scrollTop = messagesEl.scrollHeight;
}

sendBtn.addEventListener('click', sendMessage);
messageInput.addEventListener('keydown', e => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    sendMessage();
  }
});

newChatBtn.addEventListener('click', async () => {
  await createConversation();
});

(async function init() {
  const convs = await api('GET', `${API_BASE}/conversations`);
  if (convs.length > 0) {
    currentConvId = convs[0].id;
    await renderMessages();
  } else {
    messagesEl.innerHTML = '<div class="welcome"><h2>opencode Chat</h2><p>Click "New Chat" to start a conversation.</p></div>';
  }
  await loadConversations();
})();
