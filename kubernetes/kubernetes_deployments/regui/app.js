const API_BASE = '/api/v2';

const MANIFEST_ACCEPT = [
  'application/vnd.docker.distribution.manifest.v2+json',
  'application/vnd.docker.distribution.manifest.list.v2+json',
  'application/vnd.oci.image.manifest.v1+json',
  'application/vnd.oci.image.index.v1+json',
  'application/vnd.docker.distribution.manifest.v1+json',
].join(', ');

const $ = (s, p) => (p || document).querySelector(s);
const $$ = (s, p) => [...(p || document).querySelectorAll(s)];

const repoList = $('#repoList');
const loading = $('#loading');
const errorEl = $('#error');
const searchInput = $('#searchInput');

let allRepos = [];
let allReposMeta = [];
let dockerfileCache = {};
let digestCache = {};

function dKey(repo, tag) { return `${repo}:${tag}`; }

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function fetchJSON(url, opts = {}) {
  const res = await fetch(url, opts);
  const text = await res.text().catch(() => '');
  if (!res.ok) {
    throw new Error(`${res.status} ${res.statusText}${text ? ': ' + text.slice(0, 300) : ''}`);
  }
  try { return JSON.parse(text); } catch { return text; }
}

async function fetchWithDigest(url, headers = {}) {
  const res = await fetch(url, { method: 'HEAD', headers });
  return {
    digest: res.headers.get('Docker-Content-Digest'),
    contentLength: res.headers.get('Content-Length'),
    contentType: res.headers.get('Content-Type'),
  };
}

async function resolveDigest(repo, tag) {
  const cached = digestCache[dKey(repo, tag)];
  if (cached) return cached;
  const url = `${API_BASE}/${encodeURIComponent(repo)}/manifests/${encodeURIComponent(tag)}`;
  const head = await fetchWithDigest(url, { 'Accept': MANIFEST_ACCEPT });
  if (head.digest) return head.digest;
  const res = await fetch(url, { method: 'GET', headers: { 'Accept': MANIFEST_ACCEPT } });
  await res.body?.cancel();
  return res.headers.get('Docker-Content-Digest');
}

async function apiFetch(method, url, body) {
  const opts = { method };
  if (body) opts.body = body;
  const res = await fetch(url, opts);
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(`${res.status} ${res.statusText}${text ? ': ' + text.slice(0, 200) : ''}`);
  }
  return res;
}

function humanSize(bytes) {
  if (bytes === undefined || bytes === null) return '';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  let i = 0;
  let size = bytes;
  while (size >= 1024 && i < units.length - 1) { size /= 1024; i++; }
  return size.toFixed(i > 0 ? 1 : 0) + ' ' + units[i];
}

function escapeHtml(s) {
  const d = document.createElement('div');
  d.textContent = s;
  return d.innerHTML;
}

function escapeAttr(s) {
  return s.replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function hideDeleteBtn(tag) {
  const btn = $(`#deleteBtn-${escapeAttr(tag)}`);
  if (btn) btn.style.display = 'none';
}

function showError(msg) {
  errorEl.classList.remove('hidden');
  errorEl.innerHTML = `<span>${msg}</span><button class="btn btn-sm" onclick="this.parentElement.classList.add('hidden')">Dismiss</button>`;
}

function copyToClipboard(text) {
  navigator.clipboard.writeText(text).then(() => {
    const el = document.createElement('div');
    el.className = 'copy-feedback';
    el.textContent = 'Copied!';
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 1600);
  }).catch(() => {});
}

function showConfirm(msg, onConfirm) {
  const dialog = $('#confirmDialog');
  $('#confirmMsg').textContent = msg;
  dialog.classList.remove('hidden');
  const btn = $('#confirmDeleteBtn');
  const next = btn.cloneNode(true);
  btn.parentNode.replaceChild(next, btn);
  next.addEventListener('click', () => {
    dialog.classList.add('hidden');
    onConfirm();
  });
}

function closeConfirm() {
  $('#confirmDialog').classList.add('hidden');
}

async function loadDashboard() {
  try {
    const res = await fetch(`${API_BASE}/`, { method: 'GET' });
    const ver = res.headers.get('Docker-Distribution-API-Version') || 'v2';
    $('#statVersion').innerHTML = `<span>${escapeHtml(ver)}</span>`;
  } catch {
    $('#statVersion').innerHTML = '<span>v2</span>';
  }
}

async function loadRepos() {
  loading.classList.remove('hidden');
  repoList.innerHTML = '';
  errorEl.classList.add('hidden');

  try {
    const data = await fetchJSON(`${API_BASE}/_catalog`);
    allRepos = data.repositories || [];
    loading.classList.add('hidden');

    if (allRepos.length === 0) {
      repoList.innerHTML = '<div class="empty-state"><h2>No repositories found</h2><p>Push an image to get started.</p></div>';
      updateStats(0, 0);
      return;
    }

    allReposMeta = [];
    renderRepoGrid(allRepos);

    let totalTags = 0;
    let tagPromises = allRepos.map(async (repo, i) => {
      try {
        const tagsData = await fetchJSON(`${API_BASE}/${encodeURIComponent(repo)}/tags/list`);
        const tags = tagsData.tags || [];
        totalTags += tags.length;
        allReposMeta[i] = tags;
        const card = repoList.querySelector(`[data-repo="${escapeAttr(repo)}"]`);
        if (card) {
          const tc = card.querySelector('.repo-tag-count');
          if (tc) tc.innerHTML = `<span>${tags.length}</span> tag${tags.length !== 1 ? 's' : ''}`;
        }
      } catch { allReposMeta[i] = []; }
    });

    await Promise.all(tagPromises);
    updateStats(allRepos.length, totalTags);
  } catch (err) {
    loading.classList.add('hidden');
    showError(`Failed to load repositories: ${err.message}`);
  }
}

function renderRepoGrid(repos) {
  repoList.innerHTML = '';
  for (const repo of repos) {
    const card = document.createElement('div');
    card.className = 'repo-card';
    card.dataset.repo = repo;
    card.innerHTML = `<div class="repo-name">${escapeHtml(repo)}</div><div class="repo-tag-count">0 tags</div>`;
    card.addEventListener('click', () => openTagModal(repo));
    repoList.appendChild(card);
  }
}

function updateStats(repoCount, tagCount) {
  $('#statRepos').innerHTML = `<span>${repoCount}</span> repo${repoCount !== 1 ? 's' : ''}`;
  $('#statTags').innerHTML = `<span>${tagCount}</span> tag${tagCount !== 1 ? 's' : ''}`;
}

function filterRepos(query) {
  const q = query.toLowerCase().trim();
  const cards = $$('.repo-card');
  let visible = 0;
  for (const card of cards) {
    const match = !q || card.dataset.repo.toLowerCase().includes(q);
    card.classList.toggle('hidden', !match);
    if (match) visible++;
  }
  const empty = repoList.querySelector('.empty-state');
  if (visible === 0 && cards.length > 0) {
    if (!empty) {
      const el = document.createElement('div');
      el.className = 'empty-state';
      el.innerHTML = '<h2>No matching repositories</h2>';
      repoList.appendChild(el);
    }
  } else if (empty) {
    empty.remove();
  }
}

async function openTagModal(repo) {
  const modal = $('#tagModal');
  const title = $('#modalTitle');
  const body = $('#modalBody');

  title.textContent = repo;
  body.innerHTML = '<div class="loading" style="display:block;padding:2rem 0">Loading tags...</div>';
  modal.classList.remove('hidden');

  let tags;
  const idx = allRepos.indexOf(repo);
  if (idx !== -1 && allReposMeta[idx]) {
    tags = allReposMeta[idx];
  } else {
    try {
      const data = await fetchJSON(`${API_BASE}/${encodeURIComponent(repo)}/tags/list`);
      tags = data.tags || [];
    } catch (err) {
      body.innerHTML = `<div class="error" style="display:block">Failed: ${escapeHtml(err.message)}</div>`;
      return;
    }
  }

  if (tags.length === 0) {
    body.innerHTML = '<div class="empty-state" style="padding:2rem"><h2>No tags</h2></div>';
    return;
  }

  let html = '<ul class="tag-list">';
  for (const tag of tags) {
    html += `
      <li class="tag-item" data-tag="${escapeAttr(tag)}" data-repo="${escapeAttr(repo)}">
        <div class="tag-item-header" onclick="toggleDetail(this)">
          <span class="tag-name">${escapeHtml(tag)}</span>
          <div class="tag-meta">
            <span class="pill" id="metaOS-${escapeAttr(tag)}">--</span>
            <span class="pill" id="metaArch-${escapeAttr(tag)}">--</span>
            <span id="metaSize-${escapeAttr(tag)}" class="pill">--</span>
          </div>
        </div>
        <div class="tag-detail" id="detail-${escapeAttr(tag)}">
          <div class="detail-grid" id="detailGrid-${escapeAttr(tag)}">
            <span class="detail-label">Digest</span>
            <span class="detail-value" id="digest-${escapeAttr(tag)}">loading...</span>
            <span class="detail-label">MediaType</span>
            <span class="detail-value" id="mediaType-${escapeAttr(tag)}">--</span>
            <span class="detail-label">OS</span>
            <span class="detail-value" id="os-${escapeAttr(tag)}">--</span>
            <span class="detail-label">Architecture</span>
            <span class="detail-value" id="arch-${escapeAttr(tag)}">--</span>
            <span class="detail-label">Created</span>
            <span class="detail-value" id="created-${escapeAttr(tag)}">--</span>
            <span class="detail-label">Layers</span>
            <span class="detail-value" id="layers-${escapeAttr(tag)}">--</span>
          </div>
          <div id="layersDetail-${escapeAttr(tag)}"></div>
          <div id="manifestsSection-${escapeAttr(tag)}" class="manifests-section hidden"></div>
          <div id="dockerfileSection-${escapeAttr(tag)}" class="dockerfile-section hidden">
            <div class="detail-section-title">Dockerfile</div>
            <pre id="dockerfileContent-${escapeAttr(tag)}" class="dockerfile-content"></pre>
          </div>
          <div style="margin-top:0.75rem;display:flex;gap:0.35rem">
            <button class="btn btn-sm" onclick="copyDigest('${escapeAttr(tag)}')">Copy Digest</button>
            <button class="btn btn-sm btn-outline" onclick="toggleDockerfile('${escapeAttr(repo)}', '${escapeAttr(tag)}')">Dockerfile</button>
            <button class="btn btn-sm btn-outline" onclick="pullTag('${escapeAttr(repo)}', '${escapeAttr(tag)}')">Pull Cmd</button>
            <button class="btn btn-sm btn-danger" id="deleteBtn-${escapeAttr(tag)}" onclick="confirmDeleteTag('${escapeAttr(repo)}', '${escapeAttr(tag)}')">Delete</button>
          </div>
        </div>
      </li>`;
  }
  html += '</ul>';
  body.innerHTML = html;

  for (const tag of tags) {
    loadTagMeta(repo, tag);
  }
}

async function loadTagMeta(repo, tag) {
  const manifestUrl = `${API_BASE}/${encodeURIComponent(repo)}/manifests/${encodeURIComponent(tag)}`;

  try {
    const res = await fetch(manifestUrl, {
      method: 'GET',
      headers: { 'Accept': MANIFEST_ACCEPT },
    });
    const digest = res.headers.get('Docker-Content-Digest') || 'unknown';
    const contentType = res.headers.get('Content-Type') || '';
    const text = await res.text();
    const manifest = JSON.parse(text);

    $(`#digest-${escapeAttr(tag)}`).textContent = digest;
    if (digest && digest !== 'unknown') {
      digestCache[dKey(repo, tag)] = digest;
    } else {
      hideDeleteBtn(tag);
    }
    if (manifest.mediaType) {
      $(`#mediaType-${escapeAttr(tag)}`).textContent = manifest.mediaType;
    } else {
      $(`#mediaType-${escapeAttr(tag)}`).textContent = contentType;
    }

    if (manifest.mediaType === 'application/vnd.docker.distribution.manifest.list.v2+json' ||
        manifest.mediaType === 'application/vnd.oci.image.index.v1+json' ||
        manifest.manifests) {
      await loadManifestList(repo, manifest, tag);
    } else {
      await loadImageManifest(repo, manifest, tag);
    }
  } catch (err) {
    const digestEl = $(`#digest-${escapeAttr(tag)}`);
    if (digestEl) digestEl.textContent = `error: ${err.message}`;
    hideDeleteBtn(tag);
  }
}

async function loadManifestList(repo, manifest, tag) {
  const list = manifest.manifests || [];
  const section = $(`#manifestsSection-${escapeAttr(tag)}`);

  $(`#layers-${escapeAttr(tag)}`).textContent = `${list.length} platform${list.length !== 1 ? 's' : ''}`;

  let totalSize = 0;
  for (const m of list) {
    totalSize += m.size || 0;
  }
  $(`#metaSize-${escapeAttr(tag)}`).textContent = totalSize ? humanSize(totalSize) : '--';

  if (section) {
    let html = '<div class="detail-section-title">Platforms</div>';
    for (const m of list) {
      const arch = `${m.platform.os || '?'}/${m.platform.architecture || '?'}`;
      const variant = m.platform.variant ? ` ${m.platform.variant}` : '';
      html += `<div class="platform-item">
        <span class="platform-arch">${escapeHtml(arch)}${escapeHtml(variant)}</span>
        <span class="platform-digest">${escapeHtml((m.digest || '').substring(0, 19))}...</span>
        <span class="platform-size">${humanSize(m.size)}</span>
      </div>`;
    }
    section.innerHTML = html;
    section.classList.remove('hidden');
  }

  try {
    const first = list[0];
    if (first && first.digest) {
      const configRes = await fetch(
        `${API_BASE}/${encodeURIComponent(repo)}/manifests/${encodeURIComponent(first.digest)}`,
        { headers: { 'Accept': MANIFEST_ACCEPT } }
      );
      const configText = await configRes.text();
      const subManifest = JSON.parse(configText);

      if (subManifest.config && subManifest.config.digest) {
        const configUrl = `${API_BASE}/${encodeURIComponent(repo)}/blobs/${subManifest.config.digest}`;
        const configResp = await fetch(configUrl);
        const config = await configResp.json();
        if (config.created) {
          $(`#created-${escapeAttr(tag)}`).textContent = new Date(config.created).toLocaleString();
        }
        if (config.history) {
          dockerfileCache[`${repo}:${tag}`] = config.history;
        }
      }
    }
  } catch {}

  for (let i = 0; i < list.length; i++) {
    const m = list[i];
    loadSubManifest(repo, m, tag, i);
  }
}

async function loadSubManifest(repo, manifestEntry, parentTag, index) {
  if (!manifestEntry.digest) return;

  try {
    const res = await fetch(
      `${API_BASE}/${encodeURIComponent(repo)}/manifests/${encodeURIComponent(manifestEntry.digest)}`,
      { headers: { 'Accept': MANIFEST_ACCEPT } }
    );
    const text = await res.text();
    const subManifest = JSON.parse(text);

    let totalSize = 0;
    const layers = subManifest.layers || [];
    for (const layer of layers) {
      totalSize += layer.size || 0;
    }

    if (subManifest.config && subManifest.config.digest) {
      try {
        const configResp = await fetch(
          `${API_BASE}/${encodeURIComponent(repo)}/blobs/${subManifest.config.digest}`
        );
        const config = await configResp.json();

        const osArch = `${config.os || '?'}/${config.architecture || '?'}`;
        const osEl = $(`#os-${escapeAttr(parentTag)}`);
        const archEl = $(`#arch-${escapeAttr(parentTag)}`);
        if (osEl && index === 0) osEl.textContent = config.os || '?';
        if (archEl && index === 0) archEl.textContent = config.architecture || '?';

        if (index === 0) {
          $(`#metaOS-${escapeAttr(parentTag)}`).textContent = config.os || '?';
          $(`#metaArch-${escapeAttr(parentTag)}`).textContent = config.architecture || '?';
        }

        if (config.created && index === 0) {
          $(`#created-${escapeAttr(parentTag)}`).textContent = new Date(config.created).toLocaleString();
        }
      } catch {}
    }
  } catch {}
}

async function loadImageManifest(repo, manifest, tag) {
  let totalSize = 0;
  const layers = manifest.layers || [];
  const layerCount = layers.length;
  for (const layer of layers) {
    totalSize += layer.size || 0;
  }
  if (manifest.config && manifest.config.size) totalSize += manifest.config.size;

  $(`#metaSize-${escapeAttr(tag)}`).textContent = totalSize ? humanSize(totalSize) : '--';
  $(`#layers-${escapeAttr(tag)}`).textContent = `${layerCount} layer${layerCount !== 1 ? 's' : ''}`;

  if (layers.length) {
    let lhtml = '<div class="detail-section-title">Layers</div>';
    for (const layer of layers) {
      const shortDigest = layer.digest ? layer.digest.substring(0, 19) + '...' : '--';
      lhtml += `<div class="layer-item">
        <span class="layer-digest">${escapeHtml(shortDigest)}</span>
        <span class="layer-size">${humanSize(layer.size)}</span>
        <span class="layer-mediatype" style="color:#64748b;font-size:0.7rem;margin-left:auto">${escapeHtml((layer.mediaType || '').split('.').pop())}</span>
      </div>`;
    }
    $(`#layersDetail-${escapeAttr(tag)}`).innerHTML = lhtml;
  }

  if (manifest.config && manifest.config.digest) {
    await loadConfig(repo, manifest.config.digest, tag);
  }
}

async function loadConfig(repo, configDigest, tag) {
  try {
    const configUrl = `${API_BASE}/${encodeURIComponent(repo)}/blobs/${encodeURIComponent(configDigest)}`;
    const configResp = await fetch(configUrl);
    const config = await configResp.json();

    if (config.os) $(`#os-${escapeAttr(tag)}`).textContent = config.os;
    if (config.architecture) $(`#arch-${escapeAttr(tag)}`).textContent = config.architecture;
    $(`#metaOS-${escapeAttr(tag)}`).textContent = config.os || '?';
    $(`#metaArch-${escapeAttr(tag)}`).textContent = config.architecture || '?';

    if (config.created) {
      $(`#created-${escapeAttr(tag)}`).textContent = new Date(config.created).toLocaleString();
    }
    if (config.history) {
      dockerfileCache[`${repo}:${tag}`] = config.history;
    }
  } catch {}
}

function pullTag(repo, tag) {
  const cmd = `docker pull registry.test:5000/${repo}:${tag}`;
  copyToClipboard(cmd);
  showError(`Copied: ${cmd}`);
}

function toggleDockerfile(repo, tag) {
  const section = $(`#dockerfileSection-${escapeAttr(tag)}`);
  const content = $(`#dockerfileContent-${escapeAttr(tag)}`);

  if (!section.classList.contains('hidden')) {
    section.classList.add('hidden');
    return;
  }

  section.classList.remove('hidden');

  const key = `${repo}:${tag}`;
  if (dockerfileCache[key]) {
    content.textContent = buildDockerfile(dockerfileCache[key]);
  } else {
    content.textContent = '(Dockerfile history not available for this image.)';
  }
}

function buildDockerfile(history) {
  if (!history || !history.length) return '(No history found)';

  return history.map(entry => {
    if (!entry.created_by) return '';
    let line = entry.created_by;

    if (line.startsWith('/bin/sh -c #(nop) ')) {
      line = line.replace('/bin/sh -c #(nop) ', '');
    } else if (line.startsWith('/bin/sh -c ')) {
      line = 'RUN ' + line.replace('/bin/sh -c ', '');
    } else if (line.startsWith('/bin/sh -c')) {
      line = 'RUN ' + line.replace('/bin/sh -c', '').trim();
    } else if (line.startsWith('#(nop) ')) {
      line = line.replace('#(nop) ', '');
    }

    return line;
  }).filter(l => l).join('\n');
}

function toggleDetail(headerEl) {
  const detail = headerEl.parentElement.querySelector('.tag-detail');
  detail.classList.toggle('open');
}

function copyDigest(tag) {
  const el = $(`#digest-${escapeAttr(tag)}`);
  if (el && el.textContent && el.textContent !== 'loading...') {
    copyToClipboard(el.textContent);
  }
}

async function confirmDeleteTag(repo, tag) {
  const repoEnc = encodeURIComponent(repo);
  let digest = digestCache[dKey(repo, tag)];

  if (!digest) {
    try { digest = await resolveDigest(repo, tag); } catch {}
  }

  if (!digest) {
    showError(`Cannot delete: unable to resolve digest for ${escapeHtml(tag)}`);
    return;
  }

  const msg = `Delete tag <b>${escapeHtml(tag)}</b> (digest: ${escapeHtml(digest)}) from <b>${escapeHtml(repo)}</b>?`;

  showConfirm(msg, async () => {
    try {
      await apiFetch('DELETE', `${API_BASE}/${repoEnc}/manifests/${encodeURIComponent(digest)}`);
      showError(`Deleted ${escapeHtml(tag)} from ${escapeHtml(repo)}`);
      refreshAfterDelete(repo);
    } catch (err) {
      if (err.message.includes('DIGEST_INVALID')) {
        try {
          const fresh = await resolveDigest(repo, tag);
          if (fresh && fresh !== digest) {
            digestCache[dKey(repo, tag)] = fresh;
            await apiFetch('DELETE', `${API_BASE}/${repoEnc}/manifests/${encodeURIComponent(fresh)}`);
            showError(`Deleted ${escapeHtml(tag)} from ${escapeHtml(repo)}`);
            refreshAfterDelete(repo);
            return;
          }
        } catch {}
      }
      showError(`Delete failed: ${err.message}`);
    }
  });
}

function refreshAfterDelete(repo) {
  const idx = allRepos.indexOf(repo);
  if (idx !== -1) {
    allReposMeta[idx] = undefined;
  }
  const modal = $('#tagModal');
  if (!modal.classList.contains('hidden')) {
    modal.classList.add('hidden');
  }
  loadRepos();
}

searchInput.addEventListener('input', () => filterRepos(searchInput.value));
$('#refreshBtn').addEventListener('click', loadRepos);

$('#modalClose').addEventListener('click', () => $('#tagModal').classList.add('hidden'));
$('#tagModal').addEventListener('click', e => {
  if (e.target.closest('.modal-backdrop')) $('#tagModal').classList.add('hidden');
});
$('#confirmDialog').addEventListener('click', e => {
  if (e.target.closest('.modal-backdrop')) closeConfirm();
});
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    $('#tagModal').classList.add('hidden');
    closeConfirm();
  }
});

loadDashboard();
loadRepos();
