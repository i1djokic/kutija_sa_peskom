import { apiPost, createBoard } from './api.js';
import { highlightPost } from './utils.js';
import { postsMap } from './render.js';
import {
  currentBoard, currentThreadId,
  navigate, loadBoardNav, showThread, loadThreadList,
  setPendingPostId
} from './router.js';

let currentTheme = localStorage.getItem('theme') || 'light';

const threadForm = document.getElementById('thread-form');
const threadName = document.getElementById('thread-name');
const threadContent = document.getElementById('thread-content');
const homeLink = document.getElementById('home-link');
const backLink = document.getElementById('back-link');
const newTopicLink = document.getElementById('new-topic-link');
const newTopicLinkThread = document.getElementById('new-topic-link-thread');
const themeToggle = document.getElementById('theme-toggle');
const createBoardForm = document.getElementById('create-board-form');
const newBoardName = document.getElementById('new-board-name');
const boardError = document.getElementById('board-error');

function setTheme(theme) {
  currentTheme = theme;
  document.documentElement.setAttribute('data-theme', theme);
  localStorage.setItem('theme', theme);
}

setTheme(currentTheme);

themeToggle.addEventListener('click', () => {
  setTheme(currentTheme === 'light' ? 'dark' : 'light');
});

window.addEventListener('hashchange', navigate);

homeLink.addEventListener('click', (e) => {
  e.preventDefault();
  location.hash = '#/';
});

backLink.addEventListener('click', (e) => {
  e.preventDefault();
  location.hash = '#/';
});

newTopicLink.addEventListener('click', (e) => {
  e.preventDefault();
  location.hash = `#/${currentBoard}`;
});

newTopicLinkThread.addEventListener('click', (e) => {
  e.preventDefault();
  location.hash = `#/${currentBoard}`;
});

document.addEventListener('click', (e) => {
  const btn = e.target.closest('.reply-btn');
  if (btn) {
    e.preventDefault();
    const postId = parseInt(btn.dataset.postId);
    if (currentThreadId) {
      const form = document.querySelector(`.reply-form-embed[data-parent-id="${postId}"]`);
      if (form) {
        const wasHidden = form.classList.contains('hidden');
        document.querySelectorAll('.reply-form-embed').forEach(f => f.classList.add('hidden'));
        if (wasHidden) {
          form.classList.remove('hidden');
          setTimeout(() => {
            form.querySelector('textarea').focus();
            form.scrollIntoView({ behavior: 'smooth', block: 'center' });
          }, 150);
        }
      }
    } else {
      const post = postsMap.get(postId);
      if (post) {
        const tid = post.thread_id || post.id;
        location.hash = `#/thread/${tid}`;
      }
    }
    return;
  }

  const ql = e.target.closest('.quote-link');
  if (ql) {
    e.preventDefault();
    const targetId = parseInt(ql.dataset.postId);
    const el = document.getElementById(`post-${targetId}`);
    if (el) {
      highlightPost(el);
    } else if (postsMap.has(targetId)) {
      const post = postsMap.get(targetId);
      setPendingPostId(targetId);
      location.hash = `#/thread/${post.thread_id || post.id}`;

      const checkLoaded = setInterval(() => {
        const targetEl = document.getElementById(`post-${targetId}`);
        if (targetEl) {
          highlightPost(targetEl);
          clearInterval(checkLoaded);
        }
      }, 100);

      setTimeout(() => clearInterval(checkLoaded), 5000);
    }
  }
});

threadForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const name = threadName.value.trim() || null;
  const content = threadContent.value.trim();
  if (!content) return;

  const btn = threadForm.querySelector('input[type="submit"]');
  btn.disabled = true;
  btn.value = 'Posting...';

  try {
    await apiPost({ name, content, board: currentBoard });
    threadContent.value = '';
    threadName.value = '';
    await loadThreadList();
  } catch (err) {
    alert('Error: ' + err.message);
  } finally {
    btn.disabled = false;
    btn.value = 'Create Thread';
  }
});

document.addEventListener('submit', async (e) => {
  const form = e.target.closest('.inline-reply-form');
  if (!form) return;
  e.preventDefault();

  const name = form.querySelector('.reply-name').value.trim() || null;
  const content = form.querySelector('.reply-content').value.trim();
  const replyTo = parseInt(form.dataset.replyTo);
  if (!content || !currentThreadId) return;

  const btn = form.querySelector('input[type="submit"]');
  btn.disabled = true;
  btn.value = 'Posting...';

  try {
    const result = await apiPost({ name, content, thread_id: currentThreadId, reply_to: replyTo });
    setPendingPostId(result.id);
    await showThread(currentThreadId);
  } catch (err) {
    alert('Error: ' + err.message);
    btn.disabled = false;
    btn.value = 'Reply';
  }
});

createBoardForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  boardError.textContent = '';
  const name = newBoardName.value.trim();
  if (!name) return;

  const btn = createBoardForm.querySelector('input[type="submit"]');
  btn.disabled = true;

  try {
    await createBoard(name);
    newBoardName.value = '';
    await loadBoardNav();
    location.hash = `#/${name}`;
  } catch (err) {
    boardError.textContent = err.message;
  } finally {
    btn.disabled = false;
  }
});

async function init() {
  await loadBoardNav();
  navigate();
}

init();
