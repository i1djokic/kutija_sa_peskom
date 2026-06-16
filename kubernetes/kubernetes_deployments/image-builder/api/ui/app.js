const API = '/api';

const $ = (s, p) => (p || document).querySelector(s);
const $$ = (s, p) => [...(p || document).querySelectorAll(s)];

// State
let jobs = [];
let selectedJobId = null;
let selectedBuildId = null;
let pollTimer = null;

// Refs
const jobList = $('#jobList');
const jobListEmpty = $('#jobListEmpty');
const editorEmpty = $('#editorEmpty');
const editorForm = $('#editorForm');
const jobName = $('#jobName');
const imageName = $('#imageName');
const imageTag = $('#imageTag');
const dockerfileContent = $('#dockerfileContent');
const saveBtn = $('#saveBtn');
const buildBtn = $('#buildBtn');
const deleteBtn = $('#deleteBtn');
const savedIndicator = $('#savedIndicator');
const buildSection = $('#buildSection');
const buildList = $('#buildList');
const buildLog = $('#buildLog');
const buildLogContent = $('#buildLogContent');
const buildLogTitle = $('#buildLogTitle');
const closeLogBtn = $('#closeLogBtn');
const refreshBuildsBtn = $('#refreshBuildsBtn');

// ---- Helpers ----

function esc(s) {
  const d = document.createElement('div');
  d.textContent = s;
  return d.innerHTML;
}

async function api(method, path, body) {
  const opts = { method, headers: {} };
  if (body) {
    opts.headers['Content-Type'] = 'application/json';
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(`${API}${path}`, opts);
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || data.detail || `${res.status} ${res.statusText}`);
  return data;
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// ---- Job list ----

async function loadJobs() {
  try {
    jobs = await api('GET', '/jobs');
    renderJobList();
  } catch (e) {
    console.error('load jobs', e);
  }
}

function renderJobList() {
  if (!jobs.length) {
    jobListEmpty.classList.remove('hidden');
    jobList.innerHTML = '';
    return;
  }
  jobListEmpty.classList.add('hidden');
  jobList.innerHTML = jobs.map(j => {
    const active = j.id === selectedJobId ? 'active' : '';
    const lb = j.latest_build || {};
    let statusHtml = '';
    if (lb.status) {
      const cls = 'status-' + lb.status;
      statusHtml = `<span class="job-card-status ${cls}">${esc(lb.status)}</span>`;
    }
    return `<div class="job-card ${active}" data-id="${esc(j.id)}" onclick="selectJob('${esc(j.id)}')">
      <div class="job-card-name">${esc(j.name)}</div>
      <div class="job-card-image">${esc(j.image_name)}:${esc(j.image_tag)}</div>
      ${statusHtml}
    </div>`;
  }).join('');
}

// ---- Job selection / form ----

function selectJob(jid) {
  selectedJobId = jid;
  stopPolling();
  renderJobList();
  const j = jobs.find(x => x.id === jid);
  if (!j) return;
  editorEmpty.classList.add('hidden');
  editorForm.classList.remove('hidden');
  jobName.value = j.name;
  imageName.value = j.image_name;
  imageTag.value = j.image_tag;
  dockerfileContent.value = j.dockerfile_content;
  savedIndicator.classList.add('hidden');
  loadBuilds(jid);
}

async function saveJob() {
  const body = {
    name: jobName.value.trim(),
    image_name: imageName.value.trim(),
    image_tag: imageTag.value.trim() || 'latest',
    dockerfile_content: dockerfileContent.value,
  };
  if (!body.name || !body.image_name || !body.dockerfile_content) return;

  if (selectedJobId) {
    await api('PUT', `/jobs/${selectedJobId}`, body);
  } else {
    const j = await api('POST', '/jobs', body);
    selectedJobId = j.id;
  }
  savedIndicator.classList.remove('hidden');
  setTimeout(() => savedIndicator.classList.add('hidden'), 2000);
  await loadJobs();
  renderJobList();
}

async function deleteJob() {
  if (!selectedJobId) return;
  if (!confirm('Delete this job?')) return;
  await api('DELETE', `/jobs/${selectedJobId}`);
  selectedJobId = null;
  editorForm.classList.add('hidden');
  editorEmpty.classList.remove('hidden');
  await loadJobs();
}

function newJob() {
  selectedJobId = null;
  stopPolling();
  editorEmpty.classList.add('hidden');
  editorForm.classList.remove('hidden');
  jobName.value = '';
  imageName.value = '';
  imageTag.value = 'latest';
  dockerfileContent.value = `FROM python:3.12-slim\n\nWORKDIR /app\nCOPY requirements.txt .\nRUN pip install --no-cache-dir -r requirements.txt\n\nCOPY . .\n\nCMD ["python", "main.py"]`;
  savedIndicator.classList.add('hidden');
  buildSection.classList.add('hidden');
  buildLog.classList.add('hidden');
  renderJobList();
}

// ---- Builds ----

async function loadBuilds(jid) {
  buildSection.classList.remove('hidden');
  try {
    const builds = await api('GET', `/jobs/${jid}/builds`);
    renderBuildList(builds);
    // if a build is running, poll
    const running = builds.find(b => b.status === 'running' || b.status === 'pending');
    if (running) {
      startPolling(jid, running.id);
    }
  } catch (e) {
    buildList.innerHTML = '<div class="empty-state">Failed to load builds</div>';
  }
}

function renderBuildList(builds) {
  if (!builds.length) {
    buildList.innerHTML = '<div class="empty-state" style="padding:0.5rem 0">No builds yet</div>';
    return;
  }
  buildList.innerHTML = builds.map(b => {
    const cls = 'status-' + b.status;
    const time = b.started_at ? new Date(b.started_at).toLocaleString() : b.created_at ? new Date(b.created_at).toLocaleString() : '-';
    const active = b.id === selectedBuildId ? 'style="border-color:#3b82f6"' : '';
    return `<div class="build-item" ${active} onclick="showBuildLog('${esc(b.id)}')">
      <span class="build-time">${esc(time)}</span>
      <span class="build-status ${cls}">${esc(b.status)}</span>
    </div>`;
  }).join('');
}

async function showBuildLog(bid) {
  selectedBuildId = bid;
  buildLog.classList.remove('hidden');
  try {
    const b = await api('GET', `/builds/${bid}`);
    buildLogTitle.textContent = `Build ${bid.slice(0, 8)} — ${b.status}`;
    buildLogContent.textContent = b.log || '(empty log)';
    renderBuildList(await api('GET', `/jobs/${b.job_id}/builds`));
  } catch (e) {
    buildLogContent.textContent = `Error: ${e.message}`;
  }
}

async function triggerBuild() {
  if (!selectedJobId) return;
  buildBtn.disabled = true;
  buildBtn.textContent = 'Building...';
  try {
    // save first
    await saveJob();
    const result = await api('POST', `/jobs/${selectedJobId}/build`);
    selectedBuildId = result.build_id;
    await loadBuilds(selectedJobId);
    startPolling(selectedJobId, result.build_id);
  } catch (e) {
    console.error(e);
  } finally {
    buildBtn.disabled = false;
    buildBtn.textContent = 'Build';
  }
}

function startPolling(jid, bid) {
  stopPolling();
  pollTimer = setInterval(async () => {
    try {
      const b = await api('GET', `/builds/${bid}`);
      if (b.status === 'running' || b.status === 'pending') {
        if (bid === selectedBuildId) {
          buildLogContent.textContent = b.log || '';
        }
      } else {
        stopPolling();
        await loadBuilds(jid);
        if (bid === selectedBuildId) {
          buildLogTitle.textContent = `Build ${bid.slice(0, 8)} — ${b.status}`;
          buildLogContent.textContent = b.log || '';
        }
      }
    } catch {
      stopPolling();
    }
  }, 2000);
}

function stopPolling() {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
}

// ---- Event handlers ----

saveBtn.addEventListener('click', saveJob);
buildBtn.addEventListener('click', triggerBuild);
deleteBtn.addEventListener('click', deleteJob);
$('#newJobBtn').addEventListener('click', newJob);
$('#refreshBtn').addEventListener('click', () => { loadJobs(); if (selectedJobId) loadBuilds(selectedJobId); });
closeLogBtn.addEventListener('click', () => { buildLog.classList.add('hidden'); selectedBuildId = null; });
refreshBuildsBtn.addEventListener('click', () => { if (selectedJobId) loadBuilds(selectedJobId); });

// ---- Init ----

loadJobs();
