import { apiGet } from './api.js';
import { escapeHtml, highlightPost } from './utils.js';
import { postsMap, renderThreadList, renderThreadView } from './render.js';

export let currentBoard = 'general';
export let currentThreadId = null;

let _pendingPostId = null;

export function setPendingPostId(id) {
  _pendingPostId = id;
}

const boardNav = document.getElementById('board-nav');
const boardNavBottom = document.getElementById('board-nav-bottom');
const boardTitle = document.getElementById('board-title');
const boardView = document.getElementById('board-view');
const threadView = document.getElementById('thread-view');
const threadList = document.getElementById('thread-list');
const threadPosts = document.getElementById('thread-posts');

export function navigate() {
  const hash = location.hash.slice(1) || '/';
  const parts = hash.split('/').filter(Boolean);

  if (parts[0] === 'thread' && parts[1]) {
    const id = parseInt(parts[1]);
    if (id) { showThread(id); return; }
  }

  const board = parts[0] || 'general';
  showBoard(board);
}

export async function loadBoardNav() {
  try {
    const boards = await apiGet('/boards');
    const html = boards.map(b => `[<a href="#/${b}">/${b}/</a>]`).join(' ');
    boardNav.innerHTML = html;
    boardNavBottom.innerHTML = html;
  } catch {
    boardNav.innerHTML = '[Error loading boards]';
  }
}

export async function showBoard(board) {
  currentBoard = board || 'general';
  currentThreadId = null;
  _pendingPostId = null;
  boardView.classList.remove('hidden');
  threadView.classList.add('hidden');
  boardTitle.textContent = `/${currentBoard}/`;
  loadThreadList();
}

export async function loadThreadList() {
  threadList.innerHTML = '<div class="loading">Loading...</div>';
  try {
    const threads = await apiGet(`/threads?board=${encodeURIComponent(currentBoard)}`);
    threadList.innerHTML = renderThreadList(threads);
  } catch (e) {
    threadList.innerHTML = `<div class="error-msg">Error: ${escapeHtml(e.message)}</div>`;
  }
}

export async function showThread(id) {
  currentThreadId = id;
  boardView.classList.add('hidden');
  threadView.classList.remove('hidden');
  boardTitle.textContent = '/thread/';
  threadPosts.innerHTML = '<div class="loading">Loading...</div>';

  try {
    const thread = await apiGet(`/thread/${id}`);
    threadPosts.innerHTML = renderThreadView(thread);

    if (_pendingPostId) {
      const el = document.getElementById(`post-${_pendingPostId}`);
      if (el) highlightPost(el);
      _pendingPostId = null;
    }
  } catch (e) {
    threadPosts.innerHTML = `<div class="error-msg">Error: ${escapeHtml(e.message)}</div>`;
  }
}
