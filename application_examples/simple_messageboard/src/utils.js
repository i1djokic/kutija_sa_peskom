export function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

export function formatDate(dateStr) {
  const d = new Date(dateStr + 'Z');
  const mon = (d.getMonth() + 1).toString().padStart(2, '0');
  const day = d.getDate().toString().padStart(2, '0');
  const hour = d.getHours().toString().padStart(2, '0');
  const min = d.getMinutes().toString().padStart(2, '0');
  const sec = d.getSeconds().toString().padStart(2, '0');
  const dow = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.getDay()];
  return `${mon}/${day}/${d.getFullYear().toString().slice(2)}(${dow})${hour}:${min}:${sec}`;
}

export function makeQuoteLinks(text) {
  return text.replace(/>>(\d+)/g, '<a href="#" class="quote-link" data-post-id="$1">>>$1</a>');
}

export function highlightPost(el) {
  document.querySelectorAll('.highlight').forEach(h => h.classList.remove('highlight'));
  el.classList.add('highlight');
  el.scrollIntoView({ behavior: 'smooth', block: 'center' });
  setTimeout(() => el.classList.remove('highlight'), 2500);
}
