import { escapeHtml, formatDate, makeQuoteLinks } from './utils.js';

export let postsMap = new Map();

export function renderPost(post, isOp, threadId) {
  const name = post.name || 'Anonymous';
  const date = formatDate(post.created_at);
  const content = makeQuoteLinks(escapeHtml(post.content));
  const linkTid = threadId || post.thread_id || post.id;
  const title = isOp && post.title ? escapeHtml(post.title) : '';

  return `
    <div class="post ${isOp ? 'op' : 'reply'}" id="post-${post.id}">
      ${title ? `<div class="post-title"><a href="#/thread/${linkTid}">${title}</a></div>` : ''}
      <div class="post-info">
        <span class="post-name">${escapeHtml(name)}</span>
        <span class="post-date"> ${date} </span>
        <span class="post-id">No.<a href="#/thread/${linkTid}">${post.id}</a></span>
        <span class="reply-btn" data-post-id="${post.id}">Reply</span>
      </div>
      <div class="post-message">${content}</div>
    </div>
  `;
}

function renderInlineReplyForm(postId) {
  return `
    <form class="inline-reply-form" data-reply-to="${postId}">
      <input type="text" class="reply-name" maxlength="100" placeholder="Anonymous">
      <textarea class="reply-content" maxlength="2000" rows="2" placeholder="Write a reply..." required></textarea>
      <input type="submit" value="Reply">
    </form>
  `;
}

function renderFormContainer(postId, hidden) {
  const cls = hidden ? 'reply-form-embed hidden' : 'reply-form-embed';
  return `<div class="${cls}" data-parent-id="${postId}">${renderInlineReplyForm(postId)}</div>`;
}

function buildReplyTree(replies) {
  const map = {};
  const roots = [];

  for (const r of replies) {
    postsMap.set(r.id, r);
    map[r.id] = { ...r, children: [] };
  }

  for (const r of replies) {
    if (r.reply_to && map[r.reply_to]) {
      map[r.reply_to].children.push(map[r.id]);
    } else {
      roots.push(map[r.id]);
    }
  }

  return roots;
}

function renderPostTree(post, threadId) {
  let html = renderPost(post, false, threadId);
  html += renderFormContainer(post.id, true);
  if (post.children && post.children.length > 0) {
    html += '<div class="replies-nested">';
    for (const child of post.children) {
      html += renderPostTree(child, threadId);
    }
    html += '</div>';
  }
  return html;
}

export function renderThreadList(threads) {
  if (threads.length === 0) {
    return '<div class="empty">No threads yet. Be the first!</div>';
  }

  postsMap.clear();
  const parts = [];
  for (const thread of threads) {
    parts.push(renderThreadInList(thread));
  }
  return parts.join('');
}

export function renderThreadInList(thread) {
  postsMap.set(thread.id, thread);
  const threadId = thread.id;

  let html = '<div class="thread">';
  html += renderPost(thread, true, threadId);

  for (const reply of thread.replies) {
    postsMap.set(reply.id, reply);
    html += renderPost(reply, false, threadId);
  }

  if (thread.reply_count > 3) {
    const omitted = thread.reply_count - 3;
    html += `<span class="omitted">${omitted} post${omitted !== 1 ? 's' : ''} omitted. Click Reply to view.</span>`;
  }

  html += '</div><hr class="thread-separator">';
  return html;
}

export function renderThreadView(thread) {
  postsMap.clear();
  postsMap.set(thread.id, thread);

  const roots = buildReplyTree(thread.replies || []);

  let html = '<div class="thread">';
  html += renderPost(thread, true, thread.id);
  html += renderFormContainer(thread.id, false);
  if (roots.length > 0) {
    html += '<div class="replies-nested">';
    for (const root of roots) {
      html += renderPostTree(root, thread.id);
    }
    html += '</div>';
  }
  html += '</div>';
  return html;
}
