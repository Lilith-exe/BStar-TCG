// One controller per visible image, one shared procedural GPU program for all cards.
(() => {
  const warnings = new Set();
  function warn(key, error) {
    if (warnings.has(key)) return;
    warnings.add(key); console.warn('[BStar ten masks] Foil disabled:', key, error.message);
  }
  function create(surface, image) {
    const host = document.createElement('div'); host.className = 'bstar-ten-effects'; host.hidden = true;
    host.setAttribute('aria-hidden', 'true'); surface.appendChild(host);
    let revision = 0, tilt = [0, 0], active = [], source = '', paired = '', status = 'idle';
    let controller;
    const unsubscribe = window.BStarFoilMaterials.subscribe(restored => {
      host.hidden = !restored || !active.length;
      if (restored) { active.forEach(item => { item.signature = ''; }); updateTilt(...tilt); }
    });
    function clear() {
      controller?.abort();
      active.forEach(item => window.BStarTenRegions.release(item.mask));
      revision++; host.hidden = true; active = []; host.replaceChildren(); status = 'idle';
      paired = ''; surface.dataset.tenMaskState = status;
      for (const key of ['left','top','width','height']) host.style.removeProperty(key);
    }
    async function set(nextSource, card, options = {}) {
      clear(); source = nextSource;
      controller = new AbortController();
      const signal = controller.signal, pending = [];
      const request = revision, rarity = options.rarity || String(card?.rarity || '').toUpperCase().replace(/ RARE$/, '');
      const definition = window.BStarRarityConfig.resolve(rarity);
      if (!definition.layers?.length || options.enabled === false) return;
      const entry = window.BStarTenRegions.resolve(source, card);
      if (!entry) { status = 'missing'; surface.dataset.tenMaskState = status; return; }
      status = 'loading'; surface.dataset.tenMaskState = status;
      try {
        if (!(CSS.supports('mask-image', 'url("")') || CSS.supports('-webkit-mask-image', 'url("")'))) throw new Error('CSS alpha masking unavailable');
        const mode = options.mode || window.BStarRarityConfig.defaults.mode;
        const threshold = options.threshold ?? .11, feather = options.feather ?? .33;
        const thumbnail = image.id !== 'cardImage' && /images\/thumbs\//.test(nextSource);
        window.BStarTenRegions.prepare(entry, thumbnail ? 'thumb' : 'full', signal);
        if (definition.layers.some(layer => layer.kind === 'material')) window.BStarFoilMaterials.prepare();
        const results = await Promise.allSettled(definition.layers.map(async layer => {
          const mask = await window.BStarTenRegions.compose(entry, layer.regions, layer.kind === 'silver' ? 'FULL' : mode, threshold, feather, thumbnail ? 'thumb' : 'full', signal);
          pending.push(mask); return { ...layer, mask };
        }));
        if (request !== revision) { pending.forEach(window.BStarTenRegions.release); return; }
        const failed = results.find(result => result.status === 'rejected');
        if (failed) throw failed.reason;
        const layers = results.map(result => result.value);
        const fragment = document.createDocumentFragment();
        const globalIntensity = options.intensity ?? 1;
        for (const item of layers) {
          const node = document.createElement(item.kind === 'material' ? 'canvas' : 'div');
          node.className = 'bstar-ten-layer bstar-ten-' + item.kind;
          node.dataset.regions = item.regions.join(',');
          node.style.maskImage = `url("${item.mask.url}")`; node.style.webkitMaskImage = node.style.maskImage;
          item.node = node;
          if (item.kind === 'material') {
            node.width = 640; node.height = 864;
            item.settings = { ...item.options, intensity: item.options.intensity * globalIntensity };
            node.style.mixBlendMode = item.options.blend || 'screen';
            window.BStarFoilMaterials.draw(node, item.settings, tilt);
          } else {
            // native Lab Super does not interpret experimental brightness/glow/density.
            node.style.setProperty('--foil-intensity', (item.options?.intensity ?? item.intensity) * globalIntensity);
            node.style.mixBlendMode = item.options?.blend && item.options.blend !== 'native' ? item.options.blend : item.blend || 'screen';
          }
          fragment.appendChild(node);
        }
        if (request !== revision) { pending.forEach(window.BStarTenRegions.release); return; }
        active = layers; host.replaceChildren(fragment);
        pending.length = 0;
        // The base image owns its URL/lifecycle; foil never reloads or replaces it.
        paired = image.getAttribute('src') || nextSource;
        await image.decode();
        if (request !== revision) return;
        status = 'ready'; surface.dataset.tenMaskState = status; host.hidden = false;
        updateTilt(...tilt);
      } catch (error) {
        pending.forEach(window.BStarTenRegions.release);
        if (request !== revision) return;
        status = 'unavailable'; surface.dataset.tenMaskState = status; host.hidden = true;
        active.forEach(item => window.BStarTenRegions.release(item.mask));
        paired = ''; active = []; host.replaceChildren();
        if (error.name !== 'AbortError') warn(entry.image, error);
      }
    }
    function updateTilt(x, y) {
      tilt = [x, y];
      const angle = Math.min(1, Math.hypot(x, y) / 9);
      for (const item of active) {
        const sensitivity = item.options?.sensitivity ?? item.sensitivity ?? 1;
        const tx = x * sensitivity, ty = y * sensitivity;
        item.node.style.setProperty('--foil-x', `${50 + ty * 4}%`);
        item.node.style.setProperty('--foil-y', `${50 - tx * 4}%`);
        item.node.style.setProperty('--foil-angle', `${115 + ty * 3}deg`);
        item.node.style.setProperty('--foil-energy', (.18 + Math.min(1, angle * sensitivity) * .82).toFixed(3));
        if (item.kind === 'material' && !host.hidden) {
          const signature = `${x.toFixed(2)},${y.toFixed(2)}`;
          if (signature === item.signature) continue;
          try { window.BStarFoilMaterials.draw(item.node, item.settings, tilt); item.signature = signature; }
          catch (error) { host.hidden = true; warn('GPU', error); }
        }
      }
    }
    return { set, clear, updateTilt, getState: () => ({ status, source, displaySource: paired, layers: active.map(item => ({ kind: item.kind, regions: item.regions, settings: item.settings || item.options })) }),
      destroy() { clear(); unsubscribe(); host.remove(); } };
  }
  window.BStarRarityRenderer = { create };

  // Card image contexts share this adapter. No event handlers on gameplay controls,
  // no extra transforms, no animation loop, and no masks for offscreen cards.
  const instances = new Map();
  const observer = new IntersectionObserver(entries => {
    for (const event of entries) {
      const instance = instances.get(event.target);
      if (!instance) continue;
      instance.visible = event.isIntersecting;
      instance.clear();
      if (instance.visible) instance.refresh();
    }
  });
  function attach(image, card = null) {
    if (image.id === 'cardImage' || image.closest('.ghost-artwork-preview,.rarity-ghost-art')) return null;
    if (instances.has(image)) return instances.get(image);
    const parent = image.parentElement;
    if (!parent) return null;
    if (getComputedStyle(parent).position === 'static') parent.style.position = 'relative';
    const surface = document.createElement('div'); surface.className = 'bstar-card-effects'; parent.appendChild(surface);
    const api = create(surface, image);
    let legacy = null, original = '', applied = '', definition = card;
    function clear() { api.clear(); legacy?.configure({ enabled: false }); }
    function layout() {
      surface.style.left = image.offsetLeft + 'px'; surface.style.top = image.offsetTop + 'px';
      surface.style.width = image.offsetWidth + 'px'; surface.style.height = image.offsetHeight + 'px';
      surface.style.transform = getComputedStyle(image).transform;
    }
    function refresh() {
      const current = image.getAttribute('src') || '';
      if (current === applied) return;
      if (current === api.getState().displaySource) { applied = current; layout(); return; }
      if (!current.includes('images/foil-regions/')) original = current;
      const entry = window.BStarTenRegions.resolve(original);
      const file = decodeURIComponent(original.split(/[?#]/)[0].split('/').pop() || '');
      definition = card || Object.values(window.BSTAR_CARD_DEFS || {}).find(item => item.inventoryImage === file) || entry?.metadata;
      applied = current;
      if (!instance.visible) { clear(); return; }
      clear(); layout();
      const rarity = String(definition?.rarity || '').toUpperCase().replace(/ RARE$/, '');
      if (rarity === 'GHOST' && window.BStarLegacyFoilFactory) {
        if (!legacy) {
          surface.classList.add('card-surface');
          const foil = document.createElement('div'); foil.className = 'card-foil'; surface.appendChild(foil);
          const ids = {cardSurface:surface,cardFoil:foil};
          for (const id of ['foilModeBtn','ghostPreviewControl','ghostPreviewSelect']) ids[id] = document.createElement(id === 'ghostPreviewSelect' ? 'select' : 'div');
          const scope = Object.create(window); scope.BSTAR_DISABLE_GHOST_PREVIEW = true;
          const doc = {getElementById:id => ids[id],createElement:tag => document.createElement(tag)};
          legacy = window.BStarLegacyFoilFactory(scope, doc);
        }
        legacy.configure({enabled:true,rarity:'GHOST'}); legacy.setSource(original, definition);
      } else api.set(original, definition, { rarity }).then(() => { applied = image.getAttribute('src'); });
    }
    const move = event => {
      if (!instance.visible) return;
      const rect = image.getBoundingClientRect();
      const x = (0.5 - (event.clientY - rect.top) / Math.max(1, rect.height)) * 16;
      const y = ((event.clientX - rect.left) / Math.max(1, rect.width) - .5) * 16;
      api.updateTilt(x,y); legacy?.updateTilt(x,y);
    };
    const leave = () => { api.updateTilt(0,0); legacy?.updateTilt(0,0); };
    parent.addEventListener('pointermove', move); parent.addEventListener('pointerleave', leave);
    image.addEventListener('load', layout);
    const resize = new ResizeObserver(layout); resize.observe(image);
    const instance = {api,visible:false,refresh,clear() { applied = ''; clear(); },destroy() {
      observer.unobserve(image); resize.disconnect(); parent.removeEventListener('pointermove',move);
      parent.removeEventListener('pointerleave',leave); image.removeEventListener('load',layout);
      api.destroy(); legacy?.configure({enabled:false}); surface.remove(); instances.delete(image);
    }};
    instances.set(image, instance); observer.observe(image); layout(); return instance;
  }
  function scan() {
    for (const [image, instance] of instances) if (!image.isConnected) instance.destroy();
    for (const image of document.querySelectorAll('img[src*="images/cards/"],img[src*="images/thumbs/"]')) {
      const instance = attach(image); if (instance) instance.refresh();
    }
  }
  let scheduled = false;
  new MutationObserver(records => {
    if (!records.some(record => record.type === 'childList' || record.attributeName === 'src')) return;
    if (!scheduled) { scheduled = true; queueMicrotask(() => { scheduled = false; scan(); }); }
  }).observe(document.body, {childList:true,subtree:true,attributes:true,attributeFilter:['src']});
  window.BStarRarityRenderer.attach = attach;
  window.BStarRarityRenderer.getStats = () => ({ instances: instances.size, visible: [...instances.values()].filter(item => item.visible).length });
  scan();
})();
