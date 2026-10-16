// Indexed classification is integer/nearest; sparse edge coverage preserves antialiasing.
(() => {
  const registry = window.BSTAR_TEN_MASKS, outputs = new Map(), preparations = new Map(), queue = [];
  let worker, running = null, serial = 0, analyses = 0;
  const abort = () => new DOMException('Card no longer visible', 'AbortError');
  function resolve(source, card) {
    let file;
    try { file = decodeURIComponent(String(source).split(/[?#]/)[0].split('/').pop()); } catch { return null; }
    const entry = registry.cards[file];
    if (!entry || entry.live === false) return null;
    if (card && ((card.name && card.name !== entry.metadata.name) || (card.id && card.id !== entry.id) || (card.cardId && card.cardId !== entry.id))) return null;
    return entry;
  }
  function trim() {
    let bytes = 0;
    for (const record of outputs.values()) if (record.value) bytes += record.value.width * record.value.height * 4;
    for (const [key, record] of outputs) {
      if (bytes <= 48 * 1024 * 1024 && outputs.size <= 24) break;
      if (!record.value) continue;
      record.value.cached = false;
      if (!record.value.refs) URL.revokeObjectURL(record.value.url);
      bytes -= record.value.width * record.value.height * 4; outputs.delete(key);
    }
  }
  function pump() {
    if (running || !queue.length) return;
    queue.sort((a, b) => b.priority - a.priority);
    const job = queue.shift();
    if (!job.alive()) { job.reject(abort()); pump(); return; }
    try {
      if (!worker) {
        worker = new Worker(new URL('foil-regions-worker.js?v=foil3', document.baseURI));
        worker.onmessage = ({ data }) => {
          if (!running || data.id !== running.id) return;
          const current = running; running = null;
          data.error ? current.reject(new Error(data.error)) : current.resolve(data.result);
          pump();
        };
        worker.onerror = event => {
          worker.terminate(); worker = null;
          const current = running; running = null; current?.reject(new Error(event.message || 'Region worker failed')); pump();
        };
      }
      running = job; worker.postMessage({ ...job.message, id: job.id });
    } catch (error) { running = null; job.reject(error); pump(); }
  }
  function request(message, priority, alive = () => true) {
    return new Promise((resolve, reject) => { queue.push({ message, priority, alive, resolve, reject, id: ++serial }); pump(); });
  }
  function prepare(entry, profile, signal) {
    const key = entry.indexed?.[profile]?.url;
    if (!key) return;
    if (!preparations.has(key)) {
      const task = request({ kind: 'prepare', entry, profile }, profile === 'full' ? 2 : 1, () => !signal?.aborted)
        .catch(() => {}).finally(() => preparations.delete(key));
      preparations.set(key, task);
    }
  }
  async function compose(entry, regions, mode = 'DARK', threshold = .11, feather = .33, profile = 'full', signal) {
    if (!entry.indexed?.[profile]) throw new Error('Indexed map unavailable; Sync to FiveM is required');
    if (!regions.every(name => registry.regionIds?.[name]) || !['DARK','LIGHT','FULL'].includes(mode)) throw new Error('Invalid region selection');
    const key = JSON.stringify([entry.indexed[profile].url, regions, mode, threshold, feather]);
    let record = outputs.get(key);
    if (record) { outputs.delete(key); outputs.set(key, record); }
    if (!record) {
      record = { signals: new Set() }; outputs.set(key, record);
      record.promise = new Promise(resolve => setTimeout(resolve, 0)).then(() => request({ kind: 'compose', entry, profile,
        regionIds: regions.map(name => registry.regionIds[name]), mode, threshold, feather }, profile === 'full' ? 2 : 1,
        () => [...record.signals].some(item => !item?.aborted))).then(result => {
          analyses++; record.value = { ...result, url: URL.createObjectURL(result.blob), refs: 0, cached: true }; return record.value;
        }).catch(error => { outputs.delete(key); throw error; });
    }
    record.signals.add(signal);
    try {
      const value = await record.promise;
      if (signal?.aborted) { trim(); throw abort(); }
      value.refs++; trim(); return value;
    } finally { record.signals.delete(signal); }
  }
  function release(mask) {
    if (mask) { mask.refs = Math.max(0, mask.refs - 1); if (!mask.refs && !mask.cached) URL.revokeObjectURL(mask.url); }
    trim();
  }
  window.BStarTenRegions = { resolve, compose, release, prepare,
    imageSource(source) { const entry = resolve(source); if (!entry) return source;
      return new URL(/images\/thumbs\//.test(source) ? entry.thumbnail : entry.image, document.baseURI).href; },
    getStats: () => ({ analyses, outputs: outputs.size, queued: queue.length, active: running ? 1 : 0 }),
    workerStats: () => request({ kind: 'stats' }, 3) };
  const warm = () => request({ kind: 'warm' }, 0).catch(() => {});
  if (window.requestIdleCallback) requestIdleCallback(warm, { timeout: 1000 }); else setTimeout(warm, 50);
})();
