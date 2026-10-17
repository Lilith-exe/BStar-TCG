// Presentation only. All six rewards are persisted before this module receives them.

(() => {

  const root = document.createElement('section');

  root.id = 'packOpening'; root.className = 'pack-opening hidden';

  root.setAttribute('aria-label', 'BStar pack opening');

  root.setAttribute('role','dialog'); root.setAttribute('aria-modal','true');

  root.innerHTML = `<div class="pack-panel"><header class="pack-header"><button class="pack-exit" id="packExit">Exit</button></header><p class="pack-status" id="packStatus" aria-live="polite"></p><div class="pack-stage" id="packStage"></div><div class="pack-actions" id="packActions"></div></div>`;

  document.body.appendChild(root);

  const stage = root.querySelector('#packStage'), status = root.querySelector('#packStatus');

  const actions = root.querySelector('#packActions');

  let session, index = -1, active = false, busy = false, generation = 0, inspecting = false;

  async function post(name, data = {}) {

    const controller = new AbortController(), timer = setTimeout(() => controller.abort(), 15000);

    try {

      const response = await fetch(`https://${GetParentResourceName()}/${name}`, { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(data), signal:controller.signal });

      if (!response.ok) throw Error('Server connection unavailable');

      return await response.json();

    } finally { clearTimeout(timer); }

  }

  function button(text, action, secondary = false) {

    const node = document.createElement('button'); node.textContent = text;

    if (secondary) node.className = 'secondary'; node.addEventListener('click', action); actions.appendChild(node); return node;

  }

  function error(message) {
    console.error('[BStar packs] ' + message);
    post('packNotify', { message }).catch(() => {});
  }

  function hide(keepScene = false) {

    document.body.classList.remove('pack-inspecting');

    stage.getAnimations({subtree:true}).forEach(animation => animation.cancel());

    active = inspecting = busy = false; generation++; session = null;

    root.classList.add('hidden'); root.classList.remove('pack-sealed','pack-revealing'); stage.replaceChildren(); actions.replaceChildren();

    if (!keepScene) { hideCard(); app.classList.add('hidden'); }

  }

  function exit() { hide(); post('packClose').catch(() => {}); }

  function pending() {

    if (currentDuelState && (!duelWrap.classList.contains('hidden') || !tableDuelWrap.classList.contains('hidden'))) {

      post('packClose',{keepFocus:true}).catch(()=>{}); return;

    }

    hideAll(); active = true; inspecting = false; busy = true; generation++;

    root.classList.remove('hidden','pack-sealed','pack-revealing'); stage.replaceChildren(); actions.replaceChildren();

    status.textContent = 'Securing your six cards…';

  }

  function show(data) {

    if (!active) return;

    busy = false;

    if (data?.code === 'storage_unavailable') { hide(); return; }

    if (!data?.ok) { error(data?.error || 'Opening interrupted. Use /bstarpacks to resume.'); status.textContent = 'No new opening to display'; return; }

    if (!Array.isArray(data.cards) || data.cards.length !== 6) { error('Invalid presentation data. Rewards remain server-recorded; exit and resume.'); return; }

    generation++; session = data; index = -1;

    sealed();

  }

  function sealed() {
    root.classList.add('pack-sealed');
    stage.replaceChildren(); actions.replaceChildren();
    status.textContent = 'Drag across the top to tear open';
    const pack = document.createElement('button');
    pack.type = 'button'; pack.className = 'sealed-pack';
    pack.setAttribute('aria-label', 'Alpha Pack. Drag across the top to tear open, or press Enter.');
    // All three wrapper pieces share identical artwork registration. Nested
    // clips intersect the irregular seam with the moving tear front.
    const source = 'images/assets/bstar_alpha_pack.png';
    const piece = className => {
      const layer = document.createElement('span'); layer.className = className;
      const image = document.createElement('img');
      image.className = 'pack-wrapper-art'; image.alt = ''; image.draggable = false; image.src = source;
      layer.appendChild(image); return layer;
    };
    const peek = document.createElement('img');
    peek.className = 'pack-peek'; peek.alt = ''; peek.draggable = false;
    peek.src = getFullImagePath(session.cards[0]);
    const body = piece('pack-wrapper-body');
    const rest = document.createElement('span'); rest.className = 'pack-strip-rest';
    rest.appendChild(piece('pack-strip-art'));
    const loose = document.createElement('span'); loose.className = 'pack-strip-loose';
    loose.appendChild(piece('pack-strip-art'));
    pack.append(peek, body, rest, loose); stage.appendChild(pack);
    body.querySelector('img').addEventListener('error', () => {
      if (!pack.isConnected) return;
      root.classList.remove('pack-sealed');
      error('Wrapper artwork could not load. Exit and use /bstarpacks to resume safely.');
    });
    const stamp = generation, reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
    let drag = null, progress = 0, direction = 1, peelX = 0, peelY = 0;
    const valid = () => active && generation === stamp && pack.isConnected;
    function position(value, dx = 0, dy = 0) {
      progress = Math.max(0, Math.min(1, value));
      const front = progress * 100;
      rest.style.clipPath = direction > 0 ? `inset(0 0 0 ${front}%)` : `inset(0 ${front}% 0 0)`;
      loose.style.clipPath = direction > 0 ? `inset(0 ${100-front}% 0 0)` : `inset(0 0 0 ${100-front}%)`;
      loose.style.transformOrigin = direction > 0 ? '0 10%' : '100% 10%';
      peelX = dx * .16;
      peelY = Math.max(-70, Math.min(25, dy * .35)) - progress * pack.clientHeight * .08;
      loose.style.transform = `translate3d(${peelX}px,${peelY}px,0) rotate(${direction * -progress * 13}deg)`;
      pack.classList.toggle('is-tearing', progress > 0);
    }
    position(0);
    async function openWrapper(keyboard = false) {
      if (!valid() || busy) return;
      busy = true; drag = null;
      pack.classList.add('is-opening');
      try {
        if (keyboard) {
          const start = performance.now();
          // Keyboard activation uses the same physical strip, with no extra control.
          await new Promise(resolve => {
            const tick = now => {
              if (!valid()) { resolve(); return; }
              const t = reduced ? 1 : Math.min(1, (now-start)/180);
              position(t, t*pack.clientWidth, -t*25);
              if (t < 1) requestAnimationFrame(tick); else resolve();
            };
            requestAnimationFrame(tick);
          });
        }
        if (!valid()) return;
        const strip = loose.animate([
          { transform:loose.style.transform, opacity:1 },
          { transform:`translate3d(${direction*pack.clientWidth*.8}px,${-pack.clientHeight*.45}px,0) rotate(${direction*-55}deg)`, opacity:0 }
        ], { duration:reduced?0:240, easing:'cubic-bezier(.2,.65,.4,1)', fill:'forwards' });
        await strip.finished;
        if (!valid()) return;
        const opening = body.animate([
          { transform:'translateY(0) rotateX(0deg)', opacity:1 },
          { transform:'translateY(28%) rotateX(-16deg) scale(.98)', opacity:0 }
        ], { duration:reduced?0:300, easing:'cubic-bezier(.2,.7,.3,1)', fill:'forwards' });
        peek.animate([{transform:'translateY(0)'},{transform:'translateY(-5%)'}],
          {duration:reduced?0:300,easing:'ease-out',fill:'forwards'});
        await opening.finished;
        if (!valid()) return;
        busy = false; reveal(0);
      } catch { /* Exit cancels animations; persisted rewards remain recoverable. */ }
    }
    pack.addEventListener('pointerdown', e => {
      if (busy || !e.isPrimary || (e.pointerType === 'mouse' && e.button !== 0)) return;
      const rect = pack.getBoundingClientRect();
      // The visible crimp and the immediately adjacent seam are the hit area.
      if (e.clientY < rect.top || e.clientY > rect.top + rect.height*.16) return;
      direction = e.clientX < rect.left + rect.width/2 ? 1 : -1;
      drag = { id:e.pointerId, x:e.clientX, y:e.clientY };
      pack.classList.add('is-dragging'); position(0);
      pack.setPointerCapture(e.pointerId); e.preventDefault();
    });
    pack.addEventListener('pointermove', e => {
      if (!drag || drag.id !== e.pointerId || busy) return;
      const dx = e.clientX-drag.x, dy = e.clientY-drag.y;
      position(direction*dx/(pack.clientWidth*.65), dx, dy); e.preventDefault();
    });
    function release(e, cancelled = false) {
      if (!drag || drag.id !== e.pointerId) return;
      drag = null; pack.classList.remove('is-dragging');
      if (!cancelled && progress >= .98) { position(1, direction*pack.clientWidth*.65, peelY); openWrapper(); }
      else position(0);
    }
    pack.addEventListener('pointerup', e => release(e));
    pack.addEventListener('pointercancel', e => release(e,true));
    pack.addEventListener('lostpointercapture', e => release(e,true));
    pack.addEventListener('keydown', e => {
      if (['Enter',' '].includes(e.key)) { e.preventDefault(); openWrapper(true); }
    });
  }

  function inspect(card) {

    if (!active || busy) return;

    inspecting = true; document.body.classList.add('pack-inspecting'); root.classList.add('hidden'); openFullViewer(card);

  }

  function returnFromInspection() {

    if (!inspecting) return false;

    inspecting = false; document.body.classList.remove('pack-inspecting'); app.classList.add('hidden'); root.classList.remove('hidden'); return true;

  }

  function labels(card, parent) {

    const name = document.createElement('div'); name.className = 'pack-card-label'; name.textContent = card.name;

    const rarity = document.createElement('div'); rarity.className = 'pack-card-rarity'; rarity.textContent = card.rarity;

    parent.append(name, rarity);

  }

  function reveal(next) {

    if (!session || busy || !active) return;

    if (next >= 6) { overview(); return; }

    root.classList.remove('pack-sealed'); root.classList.add('pack-revealing');
    index = next; const card = session.cards[index], stamp = generation;
    actions.replaceChildren();
    status.textContent = `${index+1} / 6 \u00b7 Swipe to reveal`;

    // The stack and each card's frame/image/foil parent survive promotion.
    // Both layers occupy the exact same box; only the departing shell moves.
    let stack = stage.querySelector('.pack-swipe-stack');
    if (!stack) {
      stack = document.createElement('div'); stack.className = 'pack-swipe-stack';
      const caption = document.createElement('div'); caption.className = 'pack-reveal-labels';
      stage.replaceChildren(stack, caption);
    }
    const caption = stage.querySelector('.pack-reveal-labels');
    caption.replaceChildren(); labels(card, caption);
    function prepare(cardIndex, underneath) {
      let node = stack.querySelector(`[data-pack-index="${cardIndex}"]`);
      if (node) return node;
      node = document.createElement('div'); node.className = 'pack-swipe-card'; node.dataset.packIndex = cardIndex;
      if (underneath) { node.classList.add('pack-under-card'); node.setAttribute('aria-hidden','true'); }
      const surface = document.createElement('div'), artwork = document.createElement('img');
      surface.className = 'pack-frame'; artwork.alt = ''; artwork.draggable = false;
      artwork.src = getFullImagePath(session.cards[cardIndex]);
      surface.appendChild(artwork); node.appendChild(surface); stack.appendChild(node);
      window.BStarRarityRenderer?.attach(artwork,session.cards[cardIndex]);
      return node;
    }
    const shell = prepare(next,false), frame = shell.querySelector('.pack-frame'), image = frame.querySelector('img');
    shell.classList.remove('pack-under-card'); shell.removeAttribute('aria-hidden');
    image.alt = card.name;
    frame.tabIndex = 0; frame.setAttribute('role','button');
    frame.setAttribute('aria-label',`${card.name}. Click to inspect; arrow keys reveal the next card.`);
    const underneath = next < 5 ? prepare(next+1,true) : null;

    const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;

    let motion, drag, suppressClick = false;

    const valid = () => active && generation === stamp && index === next && shell.isConnected;

    function spring() {

      const from = getComputedStyle(shell).transform;

      motion?.cancel(); shell.style.transform = '';

      motion = shell.animate([{transform:from},{transform:'translate3d(0,0,0) rotate(0deg)'}],

        {duration:reduced?0:300,easing:'cubic-bezier(.18,.8,.25,1.15)'});

    }

    async function advance(direction = 1, velocity = 0) {

      if (!valid() || busy) return;

      busy = true; drag = null; suppressClick = true;

      for (const node of actions.querySelectorAll('button')) node.disabled = true;

      // An immediate swipe must not uncover an image still decoding. The foil
      // renderer already belongs to this same frame and is never reattached.
      if (underneath) {
        try { await underneath.querySelector('img').decode(); } catch { /* Existing artwork error handling remains available. */ }
        if (!valid()) return;
      }
      const from = getComputedStyle(shell).transform;

      motion?.cancel();

      const distance = Math.max(innerWidth*.75, shell.offsetWidth*2) * direction;

      motion = shell.animate([{transform:from,opacity:1},{transform:`translate3d(${distance}px,50px,0) rotate(${direction*22}deg)`,opacity:0}],

        {duration:reduced?0:Math.max(150,Math.min(270,260-Math.abs(velocity)*35)),easing:'cubic-bezier(.25,.65,.4,1)',fill:'forwards'});

      try { await motion.finished; } catch { return; }

      if (!valid()) return;

      shell.remove();
      busy = false; reveal(next+1);

    }

    frame.addEventListener('pointerdown', e => {

      if (busy || !e.isPrimary || (e.pointerType === 'mouse' && e.button !== 0)) return;

      const from = getComputedStyle(shell).transform;

      const matrix = new DOMMatrixReadOnly(from === 'none' ? undefined : from);

      motion?.cancel(); shell.style.transform = from;

      drag = {id:e.pointerId,startX:e.clientX,startY:e.clientY,baseX:matrix.m41,baseY:matrix.m42,x:matrix.m41,y:matrix.m42,lastX:e.clientX,time:performance.now(),velocity:0};

      suppressClick = false; frame.setPointerCapture(e.pointerId);

    });

    frame.addEventListener('pointermove', e => {

      if (!drag || drag.id !== e.pointerId || busy) return;

      const now = performance.now(), dt = now-drag.time;

      if (dt > 0) drag.velocity = drag.velocity*.3 + ((e.clientX-drag.lastX)/dt)*.7;

      drag.lastX=e.clientX; drag.time=now;

      drag.x=drag.baseX+e.clientX-drag.startX; drag.y=drag.baseY+(e.clientY-drag.startY)*.3;

      if (Math.abs(e.clientX-drag.startX)+Math.abs(e.clientY-drag.startY)>8) suppressClick=true;

      const rotation = Math.max(-18,Math.min(18,drag.x/Math.max(1,frame.offsetWidth)*24));

      shell.style.transform=`translate3d(${drag.x}px,${drag.y}px,0) rotate(${rotation}deg)`;

      e.preventDefault();

    });

    function release(e, cancelled = false) {

      if (!drag || drag.id !== e.pointerId) return;

      const {x,velocity,time} = drag; drag=null;

      const speed=performance.now()-time<100?velocity:0;

      const threshold=Math.max(65,Math.min(125,frame.offsetWidth*.25));

      if (!cancelled && (Math.abs(x)>=threshold || (Math.abs(x)>25 && Math.abs(speed)>.65))) advance(Math.sign(Math.abs(x)>=threshold?x:speed)||1,speed);

      else spring();

    }

    frame.addEventListener('pointerup', e => release(e));

    frame.addEventListener('pointercancel', e => release(e,true));

    frame.addEventListener('lostpointercapture', e => { if (drag) release(e,true); });

    frame.addEventListener('click', () => { if (!suppressClick && !busy) inspect(card); });

    image.addEventListener('error', () => { if(valid()) error('Artwork could not load. Rewards are safe; you can continue or exit.'); });

    button('Next Card', () => advance());

    frame.addEventListener('keydown', e => {
      if (['ArrowLeft','ArrowRight'].includes(e.key)) { e.preventDefault(); advance(e.key==='ArrowLeft'?-1:1); }
      else if (['Enter',' '].includes(e.key)) { e.preventDefault(); if (!busy) inspect(card); }
    });

  }

  async function overview() {

    root.classList.remove('pack-revealing');

    stage.replaceChildren(); actions.replaceChildren(); status.textContent = 'Your six pulls · Select any card to inspect';

    const grid = document.createElement('div'); grid.className = 'pack-overview';

    for (const card of session.cards) {

      const tile = document.createElement('button'), frame = document.createElement('div'), image = document.createElement('img');

      tile.className = 'pack-summary-card'; frame.className = 'pack-thumb'; image.alt = card.name; image.src = getThumbImagePath(card);

      frame.appendChild(image); tile.appendChild(frame); labels(card,tile); tile.addEventListener('click',()=>inspect(card)); grid.appendChild(tile);

    }

    stage.appendChild(grid);

    const next = button('Checking remaining packs…', openNext); next.disabled = true; button('Exit',exit,true);
    button('Browse Card Pile', async () => {
      hide();
      try { await post('packClose'); await post('bulkOpen'); } catch { /* Client reports storage errors. */ }
    }, true);


    const current = generation;

    try {

      const data = await post('packViewed',{id:session.id});

      if (!active || current !== generation) return;

      if (!data.ok) { error(data.error || 'Could not confirm the next pack. Exit and resume safely.'); return; }

      session.remaining = data.remaining; next.textContent = data.remaining > 0 ? `Open Next Pack (${data.remaining} remaining)` : 'No packs remaining'; next.disabled = data.remaining < 1;

    } catch { if (active && current === generation) error('Connection interrupted. Your cards are secured; exit and resume with /bstarpacks.'); }

  }

  async function openNext() {

    if (busy || !session || session.remaining < 1) return;

    busy = true; const current = ++generation, id = session.id;

    for (const node of actions.querySelectorAll('button')) node.disabled = true;

    status.textContent = 'Securing the next six cards…';

    try {

      const result = await post('packNext',{id});

      if (active && current === generation) show(result);

    } catch { if (active && current === generation) { error('Request interrupted. Exit and use /bstarpacks; do not retry an uncertain opening.'); busy = false; } }

  }

  root.querySelector('#packExit').addEventListener('click',exit);

  document.addEventListener('keydown', e => {

    if (active && ['Escape','Tab'].includes(e.key)) { e.preventDefault(); e.stopImmediatePropagation(); exit(); }

  },true);

  window.addEventListener('message',({data}) => {

    if (data?.action === 'packPending') pending();

    else if (data?.action === 'packResult') show(data.result);

    else if (data?.action === 'packClosed') { if (active || inspecting) hide(); }

    else if (active && ['forceCloseAll','hideCard'].includes(data?.action)) exit();

    else if (active && ['showCard','openDeckBox','openDeckBuilder','openDuelUi'].includes(data?.action)) { hide(true); post('packClose',{keepFocus:true}).catch(()=>{}); }

  });

  setInterval(() => { if (active) post('packHeartbeat').catch(()=>{}); },3000);

  window.BStarPackOpening = { get active() { return active; }, get inspecting() { return inspecting; }, returnFromInspection, close:exit };

})();

