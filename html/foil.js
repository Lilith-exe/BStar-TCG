// One inspected-card surface; rarity controls appearance, artwork masks control coverage.
(() => {
 function createLegacy(window, document) {
  const surface = document.getElementById('cardSurface');
  const layer = document.getElementById('cardFoil');
  const modeButton = document.getElementById('foilModeBtn');
  const modern = window === globalThis && window.BStarRarityRenderer
    ? window.BStarRarityRenderer.create(surface, document.getElementById('cardImage')) : null;
  let currentDefinition = null;
  const catalog = window.BSTAR_FOIL_SAMPLES || { cards: {} };
  // Enabled for local testing. Set false before release; also requires Config.Debug.
  const DEV_GHOST_ARTWORK_PREVIEW = true;
  let previewCard = null;
  const previewControl = document.getElementById('ghostPreviewControl');
  const previewSelect = document.getElementById('ghostPreviewSelect');
  let previewCards = [];
  let previewCatalogRequest;
  const DEFAULT_INTENSITY = 0.55; // Existing silver border and unaffected rarity baseline.
  const settings = { enabled: true, mode: 'FULL', intensity: DEFAULT_INTENSITY, rarity: null, maskSource: 'live', threshold: 0.11, feather: 0.33 };
  let explicitMode = false;
  let explicitIntensity = false;
  let artworkPoints;
  const ghostSettings = { metallic: 0.9, diffraction: 0.7, visibility: 0.85 };
  let specialtyTilt = [0, 0];
  const cachedMasks = new Map();
  let currentFile = '';
  let currentSource = '';
  let revision = 0;
  let cardRarity = 'COMMON';
  let lastTilt = '';
  const makeLayer = className => {
    const element = document.createElement('div');
    element.className = className;
    element.setAttribute('aria-hidden', 'true');
    surface.appendChild(element);
    return element;
  };
  const preview = makeLayer('ghost-artwork-preview');
  const previewImage = document.createElement('img');
  previewImage.alt = '';
  preview.appendChild(previewImage);
  surface.insertBefore(preview, layer); // Above the base image, below every finish.
  const ghost = makeLayer('rarity-ghost-art');
  const ghostImage = document.createElement('img');
  ghostImage.alt = '';
  ghost.appendChild(ghostImage);
  const edges = makeLayer('rarity-ghost-edges');
  const full = makeLayer('rarity-full');
  const stars = makeLayer('rarity-starlight');
  const facets = document.createElement('span');
  facets.className = 'secret-facets';
  stars.appendChild(facets);
  const border = makeLayer('rarity-border');
  // One reusable inline vector mask; avoids extra asset requests and lab MIME assumptions.
  const borderGeometry = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 1619">
  <!-- Shared template bevels; white strokes are foil alpha, not a replacement frame. -->
  <g fill="none" stroke="white" stroke-linejoin="round">
    <rect x="25" y="22" width="1150" height="1575" rx="48" stroke-width="12"/>
    <rect x="42" y="39" width="1116" height="1541" rx="34" stroke-width="7"/>
    <path d="M87 217H729L794 151H1117V1058H87Z" stroke-width="9"/>
    <path d="M218 150H854L963 42H1129L1149 64V116H898" stroke-width="7"/>
    <path d="M58 1192H1080L1165 1105V1405L1039 1484H101V1474L56 1442V1192" stroke-width="7"/>
    <path d="M794 1583L917 1441H1149V1544H997" stroke-width="7"/>
  </g>
</svg>`;
  surface.style.setProperty('--border-mask', `url("data:image/svg+xml,${encodeURIComponent(borderGeometry)}")`);
  const points = catalog.settings?.artworkPolygon;
  if (points?.length) surface.style.setProperty('--artwork-clip', `polygon(${points.map(([x, y]) => `${x * 100}% ${y * 100}%`).join(',')})`);

  function normalizeRarity(value) {
    const rarity = String(value || '').toUpperCase().replace(/[_-]/g, ' ').replace(/\s+RARE$/, '').trim();
    return ['COMMON', 'RARE', 'SUPER', 'ULTRA', 'SECRET', 'GHOST'].includes(rarity) ? rarity : 'COMMON';
  }

  function effectiveRarity() { return settings.rarity || cardRarity; }
  function regionalRarity() { return (modern ? ['RARE','SUPER','ULTRA','SECRET'] : ['SUPER','ULTRA','SECRET']).includes(effectiveRarity()); }
  function effectiveMode() { return regionalRarity() && settings.maskSource === 'live' && !explicitMode ? 'DARK' : settings.mode; }
  function effectiveIntensity() { return regionalRarity() && !explicitIntensity ? 1 : settings.intensity; }
  function updateSpecialty(rotateX, rotateY) {
    specialtyTilt = [rotateX, rotateY];
    if (effectiveRarity() === 'SECRET') {
      const phase = rotateY * 0.11 + rotateX * 0.045;
      const peaks = [-0.85, 0.30, 0.90].map(normal => {
        const alignment = Math.pow(Math.max(0, Math.cos(phase - normal)), 36);
        // Stronger catches with a quiet floor; no blanket foil opacity boost.
        return Math.min(1, Math.max(0, (alignment - 0.08) / 0.92) * 1.8);
      });
      ['a','b','c'].forEach((group, i) => surface.style.setProperty(`--secret-spec-${group}`, peaks[i].toFixed(4)));
      surface.style.setProperty('--secret-glint', Math.pow(Math.max(...peaks), 1.5).toFixed(4));
    } else if (effectiveRarity() === 'GHOST') {
      const phase = rotateY * 0.14 - rotateX * 0.08;
      const conceal = ghostSettings.visibility * Math.pow(Math.sin(phase * 1.7 + 0.45), 2);
      surface.style.setProperty('--ghost-metal', ghostSettings.metallic);
      surface.style.setProperty('--ghost-conceal', conceal.toFixed(4));
      surface.style.setProperty('--ghost-rainbow', (ghostSettings.diffraction * (0.15 + 0.85 * Math.pow(Math.sin(phase + 0.7), 2))).toFixed(4));
      surface.style.setProperty('--spectral-angle', `${115 + rotateY * 8 - rotateX * 4}deg`);
    }
  }

  function filename(source) {
    try { return decodeURIComponent(String(source).split(/[?#]/)[0].split('/').pop()); }
    catch { return ''; }
  }

  function loadMask(path) {
    if (!cachedMasks.has(path)) {
      // Bound retained entries when inspection uses changing CUSTOM/preview URLs.
      if (cachedMasks.size >= 32) cachedMasks.delete(cachedMasks.keys().next().value);
      cachedMasks.set(path, new Promise(resolve => {
        const image = new Image();
        image.onload = () => resolve(true);
        image.onerror = () => { cachedMasks.delete(path); resolve(false); };
        image.src = path;
      }));
    }
    return cachedMasks.get(path);
  }

  async function updatePreviewSelector() {
    const isLucian = () => currentFile === 'ALPH1-EN144_LUCIAN_LIGHTBRINGER.png';
    previewControl.classList.add('hidden');
    if (!DEV_GHOST_ARTWORK_PREVIEW || window.BSTAR_DISABLE_GHOST_PREVIEW || !isLucian()) return;
    if (!previewCatalogRequest) {
      previewCatalogRequest = fetch(`https://${GetParentResourceName()}/ghostPreviewCatalog`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
      }).then(response => response.json()).then(data => {
        if (!data.enabled) return false;
        previewCards = (data.cards || []).filter(card => card.name &&
          /^[^/\\]+\.png$/i.test(card.inventoryImage || '') &&
          card.inventoryImage !== 'ALPH1-EN144_LUCIAN_LIGHTBRINGER.png')
          .sort((a, b) => a.name.localeCompare(b.name) || a.id.localeCompare(b.id));
        for (const card of previewCards) {
          const option = document.createElement('option');
          option.value = card.id;
          option.textContent = card.name;
          previewSelect.appendChild(option);
        }
        return true;
      }).catch(error => { console.warn('[BStar preview] Catalog unavailable:', error.message); return false; });
    }
    if (await previewCatalogRequest && isLucian()) {
      previewSelect.value = previewCard?.id || '';
      previewControl.classList.remove('hidden');
    }
  }

  function previewGhostArtwork(identifier = null) {
    if (!DEV_GHOST_ARTWORK_PREVIEW) throw new Error('Ghost artwork preview is disabled');
    if (identifier === null) previewCard = null;
    else {
      const match = previewCards.find(card => [card.id, card.inventoryImage].includes(identifier)) ||
        Object.entries(window.BSTAR_CARD_DEFS || {}).find(([id, card]) =>
          [id, card.id, card.cardId, card.inventoryImage].includes(identifier))?.[1];
      if (!match?.inventoryImage) throw new Error('Unknown preview card');
      previewCard = match;
    }
    return refresh();
  }

  previewSelect.addEventListener('change', () => previewGhostArtwork(previewSelect.value || null));
  previewImage.addEventListener('error', () => {
    // Missing source assets restore the original rather than leave a broken preview.
    if (previewCard) { previewCard = null; refresh(); }
  });

  async function refresh() {
    const request = ++revision;
    modern?.clear();
    updatePreviewSelector();
    const previewSource = DEV_GHOST_ARTWORK_PREVIEW && previewCard && currentFile === 'ALPH1-EN144_LUCIAN_LIGHTBRINGER.png'
      ? `images/cards/${encodeURIComponent(previewCard.inventoryImage)}` : null;
    preview.classList.toggle('active', Boolean(previewSource));
    if (previewSource) previewImage.src = previewSource;
    else previewImage.removeAttribute('src');
    layer.classList.remove('active');
    layer.style.removeProperty('--foil-mask');
    ghost.style.removeProperty('--foil-mask');
    edges.style.removeProperty('--foil-mask');
    edges.style.removeProperty('--spectral-edge');
    full.style.removeProperty('--foil-mask');
    for (const element of [ghost, edges, full, stars, border]) element.classList.remove('active');
    surface.removeAttribute('data-rarity');
    surface.removeAttribute('data-regional');
    surface.style.removeProperty('--regional-mask');
    border.style.removeProperty('--foil-intensity');
    const sample = catalog.cards[currentFile];
    const rarity = effectiveRarity();
    const mode = effectiveMode();
    const visible = !!currentFile && rarity !== 'COMMON';
    modeButton.classList.toggle('hidden', !visible);
    modeButton.textContent = !settings.enabled ? 'Foil: off' : rarity === 'RARE' && !modern ? 'Foil: silver border' : `Foil: ${mode.toLowerCase()}`;
    modeButton.title = rarity === 'RARE' && !modern ? 'Toggle silver border reflection' : 'Cycle artwork coverage: FULL, available DARK/LIGHT, off';
    surface.style.setProperty('--foil-intensity', effectiveIntensity());
    if (rarity === 'SUPER') border.style.setProperty('--foil-intensity', Math.min(DEFAULT_INTENSITY, effectiveIntensity()));
    if (!visible || !settings.enabled) return;

    if (modern && regionalRarity()) {
      await modern.set(currentSource, currentDefinition, { rarity, mode, threshold: settings.threshold,
        feather: settings.feather, intensity: effectiveIntensity(), enabled: settings.enabled });
      if (request !== revision) return;
      if (['missing', 'unavailable'].includes(modern.getState().status)) {
        modeButton.textContent = 'Foil: masks unavailable';
        modeButton.title = 'No verified ten-region mask set is available; displaying the original card without foil.';
      }
      return;
    }
    surface.dataset.rarity = rarity.toLowerCase();
    if (regionalRarity()) {
      const cachedPath = mode === 'CUSTOM' || settings.maskSource === 'cached' ? sample?.[mode] : null;
      if ((mode === 'CUSTOM' || (settings.maskSource === 'cached' && mode !== 'FULL')) && !cachedPath) return;
      try {
        const masks = await window.BStarArtworkMasks.build(`images/cards/${encodeURIComponent(currentFile)}`, artworkPoints || points, settings.threshold, settings.feather, mode, cachedPath);
        if (request !== revision) return;
        surface.dataset.regional = 'true';
        surface.style.setProperty('--regional-mask', `url("${masks.regional}")`);
        // Super's rainbow artwork layer must never use the FULL exterior field.
        layer.style.setProperty('--foil-mask', `url("${masks.artwork}")`);
        border.classList.add('active');
        if (rarity !== 'SUPER') full.classList.add('active');
        if (rarity === 'SECRET') stars.classList.add('active');
        layer.classList.add('active');
      } catch (error) {
        if (request === revision) console.warn('[BStar foil] Artwork mask unavailable:', error.message);
      }
      return;
    }
    border.classList.add('active');
    if (['ULTRA', 'SECRET'].includes(rarity)) full.classList.add('active');
    if (rarity === 'SECRET') stars.classList.add('active');
    if (rarity === 'RARE') return; // Never apply an artwork treatment to Rare.

    // FULL is a reusable geometric artwork clip. DARK/LIGHT/CUSTOM consume existing
    // cached masks (including lab-supplied previews) without knowing their threshold.
    const path = sample?.[settings.mode];
    if (settings.mode !== 'FULL' && !path) return;
    if (path && (!await loadMask(path) || request !== revision)) return;
    if (path) {
      layer.style.setProperty('--foil-mask', `url("${path}")`);
      ghost.style.setProperty('--foil-mask', `url("${path}")`);
      edges.style.setProperty('--foil-mask', `url("${path}")`);
      full.style.setProperty('--foil-mask', `url("${path}")`);
    }
    layer.classList.add('active');
    if (rarity === 'GHOST') {
      full.classList.add('active');
      if (ghostImage.getAttribute('src') !== (previewSource || currentSource)) ghostImage.src = previewSource || currentSource;
      ghost.classList.add('active');
      // An exported soft edge alpha can bypass analysis entirely; SUBJECT supplies a
      // precise silhouette for cached contour extraction instead of the approximation.
      let edge = previewSource ? null : sample?.SUBJECT_EDGE;
      if (edge) {
        if (!await loadMask(edge) || request !== revision) return;
      } else edge = await window.BStarSpectralEdges?.get(previewSource || `images/cards/${encodeURIComponent(currentFile)}`, artworkPoints || points, previewSource ? null : sample?.SUBJECT);
      if (request !== revision || !edge) return;
      edges.style.setProperty('--spectral-edge', `url("${edge}")`);
      edges.classList.add('active');
    }
  }

  function configure(options = {}) {
    if (options.mode !== undefined) {
      const mode = options.mode === null ? 'FULL' : String(options.mode).toUpperCase();
      if (!['DARK', 'LIGHT', 'FULL', 'CUSTOM'].includes(mode)) throw new Error('Unknown foil mode');
      settings.mode = mode;
      explicitMode = options.mode !== null;
    }
    if (options.enabled !== undefined) settings.enabled = Boolean(options.enabled);
    if (options.ghost !== undefined) {
      for (const key of ['metallic','diffraction','visibility']) if (options.ghost[key] !== undefined) {
        const value = Number(options.ghost[key]);
        if (!Number.isFinite(value) || value < 0 || value > 1) throw new Error(`Invalid Ghost ${key}`);
        ghostSettings[key] = value;
      }
    }
    if (options.maskSource !== undefined) {
      if (!['live','cached'].includes(options.maskSource)) throw new Error('Unknown artwork mask source');
      settings.maskSource = options.maskSource;
    }
    for (const key of ['threshold','feather']) if (options[key] !== undefined) {
      const value = Number(options[key]);
      if (!Number.isFinite(value) || value < 0 || value > 1) throw new Error(`Invalid artwork ${key}`);
      settings[key] = value;
    }
    // Inspection-only override, useful for comparing all finishes on the same artwork.
    // Normal production calls use the existing server/catalog rarity metadata.
    if (options.rarity !== undefined) settings.rarity = options.rarity === null ? null : normalizeRarity(options.rarity);
    if (options.intensity !== undefined) {
      const value = options.intensity === null ? DEFAULT_INTENSITY : Number(options.intensity);
      if (!Number.isFinite(value)) throw new Error('Foil intensity must be finite');
      settings.intensity = Math.max(0, Math.min(1, value));
      explicitIntensity = options.intensity !== null;
    }
    updateSpecialty(...specialtyTilt);
    refresh();
    return { ...settings, intensity: effectiveIntensity() };
  }

  modeButton.addEventListener('click', () => {
    if (!settings.enabled) configure({ enabled: true, mode: null });
    else if (effectiveRarity() === 'RARE' && !modern) configure({ enabled: false });
    else {
      const available = ['FULL', 'DARK', 'LIGHT'].filter(mode => mode === 'FULL' || (regionalRarity() && settings.maskSource === 'live') || catalog.cards[currentFile]?.[mode]);
      const next = available[available.indexOf(effectiveMode()) + 1];
      configure(next ? { mode: next } : { enabled: false });
    }
  });

  window.BStarFoil = {
    configure,
    previewGhostArtwork,
    setSource(source, card = null) {
      currentFile = filename(source);
      currentSource = source || '';
      const definition = card || Object.values(window.BSTAR_CARD_DEFS || {}).find(item => item.inventoryImage === currentFile);
      currentDefinition = definition;
      cardRarity = normalizeRarity(definition?.rarity);
      artworkPoints = definition?.artworkPolygon || catalog.cards[currentFile]?.artworkPolygon || catalog.templates?.[definition?.template || definition?.type]?.artworkPolygon || points;
      ghostImage.removeAttribute('src');
      surface.style.setProperty('--foil-x', '50%');
      surface.style.setProperty('--foil-y', '50%');
      surface.style.setProperty('--foil-energy', '0.18');
      surface.style.setProperty('--ghost-strength', '0.08');
      surface.style.setProperty('--ghost-desaturation', '0.35');
      surface.style.setProperty('--ghost-contrast', '1');
      surface.style.setProperty('--ghost-brightness', '1');
      surface.style.setProperty('--spectral-angle', '120deg');
      lastTilt = '';
      updateSpecialty(0, 0);
      refresh();
    },
    updateTilt(rotateX, rotateY) {
      if (!settings.enabled || !currentFile || effectiveRarity() === 'COMMON') return;
      const key = `${rotateX.toFixed(2)},${rotateY.toFixed(2)}`;
      if (key === lastTilt) return;
      lastTilt = key;
      const angle = Math.min(1, Math.hypot(rotateX, rotateY) / 9);
      surface.style.setProperty('--foil-x', `${50 + rotateY * 4}%`);
      surface.style.setProperty('--foil-y', `${50 - rotateX * 4}%`);
      surface.style.setProperty('--foil-angle', `${115 + rotateY * 3}deg`);
      surface.style.setProperty('--foil-energy', (0.18 + angle * 0.82).toFixed(3));
      surface.style.setProperty('--ghost-strength', (0.08 + angle * 0.84).toFixed(3));
      modern?.updateTilt(rotateX, rotateY);
      updateSpecialty(rotateX, rotateY);
    },
    getSettings: () => ({ ...settings, ghost: { ...ghostSettings }, intensity: effectiveIntensity(), mode: effectiveMode(), regionalCoverage: surface.dataset.regional === 'true', effectiveRarity: effectiveRarity(), artworkActive: layer.classList.contains('active') || modern?.getState().status === 'ready', tenMasks: modern?.getState(), maskGeneration: catalog.settings })
  };
  return window.BStarFoil;
 }
 window.BStarLegacyFoilFactory = createLegacy;
 if (document.getElementById('cardSurface')) createLegacy(window, document);
})();
