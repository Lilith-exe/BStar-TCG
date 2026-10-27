(() => {
  const root=document.createElement('section'); root.className='pack-opening hidden'; root.id='bulkPile';
  root.setAttribute('role','dialog'); root.setAttribute('aria-label','Bulk Card Pile'); root.setAttribute('aria-modal','true');
  root.innerHTML=`<div class="bulk-panel"><header class="pack-header"><h2>Bulk Card Pile</h2><button data-close>Exit</button></header>
    <div class="bulk-toolbar"><input aria-label="Search pile" placeholder="Search cards"><select aria-label="Filter rarity"><option value="">All rarities</option>${['COMMON','RARE','SUPER','ULTRA','SECRET','GHOST'].map(r=>`<option>${r}</option>`).join('')}</select><select aria-label="Sort cards"><option value="name">Name</option><option value="rarity">Rarity</option></select></div>
    <p class="bulk-status" aria-live="polite"></p><div class="bulk-grid"></div><div class="bulk-pages"><button data-prev>Previous</button><span></span><button data-next>Next</button></div></div>`;
  document.body.appendChild(root);
  const grid=root.querySelector('.bulk-grid'), status=root.querySelector('.bulk-status'), search=root.querySelector('input');
  const [rarity,sort]=root.querySelectorAll('select'), previous=root.querySelector('[data-prev]'), next=root.querySelector('[data-next]');
  const pilePicker=document.createElement('select');pilePicker.setAttribute('aria-label','Carried card pile');root.querySelector('.bulk-toolbar').prepend(pilePicker);
  pilePicker.addEventListener('change',()=>{id=pilePicker.value;load(1);});

  let active=false, inspecting=false, id, token, page=1, pages=1, epoch=0, debounce, loading=false;
  async function post(name,data={}) {
    const controller=new AbortController(), timer=setTimeout(()=>controller.abort(),15000);
    try {
      const response=await fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data),signal:controller.signal});
      if(!response.ok) throw Error('Connection unavailable'); return await response.json();
    } finally { clearTimeout(timer); }
  }
  function hide(keepScene=false) {
    active=inspecting=loading=false;epoch++;clearTimeout(debounce);root.classList.add('hidden');grid.replaceChildren();
    document.body.classList.remove('pack-inspecting');
    if(!keepScene) { hideCard();app.classList.add('hidden'); }
  }
  function close() { const stamp=token;hide();post('bulkClose',{token:stamp}).catch(()=>{}); }
  async function inspect(card) {
    if(!active) return;
    const stamp=epoch;
    const result=await post('bulkCheck',{id}).catch(()=>({ok:false}));
    if(!active || stamp!==epoch) return;
    if(!result.ok) {close();return;}
    inspecting=true;root.classList.add('hidden');document.body.classList.add('pack-inspecting');openFullViewer(card);
  }
  function returnFromInspection() {
    if(!inspecting) return false;
    inspecting=false;document.body.classList.remove('pack-inspecting');app.classList.add('hidden');root.classList.remove('hidden');return true;
  }
  async function load(target=1) {
    const stamp=++epoch;loading=true;previous.disabled=next.disabled=true;status.textContent='Loading pile…';
    try {
      const result=await post('bulkPage',{id,page:target,search:search.value,rarity:rarity.value,sort:sort.value});
      if(!active || stamp!==epoch) return;
      if(!result.ok) throw Error(result.error || 'Pile unavailable');
      page=result.page;pages=result.pages;grid.replaceChildren();grid.scrollTop=0;
      status.textContent=`Contains ${Number(result.total).toLocaleString()} cards · ${Number(result.matched).toLocaleString()} matching`;
      root.querySelector('.bulk-pages span').textContent=`Page ${page} of ${pages}`;
      for(const card of result.cards) {
        const tile=document.createElement('button'), frame=document.createElement('div'), image=document.createElement('img'), label=document.createElement('div');
        frame.className='pack-thumb';frame.style.position='relative';image.src=getThumbImagePath(card);image.alt=card.name;image.loading='lazy';image.draggable=false;
        label.className='pack-card-label';label.textContent=card.name;
        frame.appendChild(image);tile.append(frame,label);tile.addEventListener('click',()=>inspect(card));tile.addEventListener('contextmenu',event=>window.BStarSleeves?.menu(event,{card,context:{location:'pile',id},actions:[{label:'Inspect card',run:()=>inspect(card)}]}));grid.appendChild(tile);
        // Existing visibility-managed renderer; never mount more than one 48-card page.
        window.BStarSleeveVisuals?.bind(image,card);
        window.BStarRarityRenderer?.attach(image,card);
      }
      previous.disabled=page<=1;next.disabled=page>=pages;
    } catch(error) { if(active && stamp===epoch) status.textContent=error.message; }
    finally { if(stamp===epoch) loading=false; }
  }
  search.addEventListener('input',()=>{clearTimeout(debounce);debounce=setTimeout(()=>load(1),220);});
  rarity.addEventListener('change',()=>load(1));sort.addEventListener('change',()=>load(1));
  previous.addEventListener('click',()=>{if(!loading)load(page-1);});next.addEventListener('click',()=>{if(!loading)load(page+1);});
  root.querySelector('[data-close]').addEventListener('click',close);
  document.addEventListener('keydown',e=>{if(active && ['Escape','Tab'].includes(e.key)){e.preventDefault();e.stopImmediatePropagation();close();}},true);
  window.addEventListener('message',({data})=>{
    if(data?.action==='bulkOpen') {
      hideAll();active=true;inspecting=false;id=data.id;token=data.token;search.value='';rarity.value='';sort.value='name';
      root.classList.remove('hidden');load(1);
      const opened=id;
      post('bulkList').then(result=>{
        if(!active || opened!==id || !result.ok) return;
        pilePicker.replaceChildren();
        for(const pile of result.piles) {
          const option=document.createElement('option');option.value=pile.id;option.textContent=`Pile ${pile.id.slice(-8)} · ${Number(pile.count).toLocaleString()} cards`;pilePicker.appendChild(option);
        }
        pilePicker.value=id;
      }).catch(()=>{});

    } else if(data?.action==='bulkClosed') {if(active)hide();}
    else if(active && ['forceCloseAll','hideCard','packPending','showCard','openDeckBox','openDeckBuilder','openDuelUi'].includes(data?.action)) { const stamp=token;hide(true);post('bulkClose',{token:stamp,keepFocus:true}).catch(()=>{}); }
  });
  setInterval(()=>{if(active)post('bulkHeartbeat').catch(()=>{});},3000);

  // Pile UI stays in BStar; the approved inventory adapter secures physical token transfers.
  const menu=document.createElement('div');menu.className='bulk-context hidden';
  const transfer=document.createElement('button');transfer.textContent='Add All Bulk Piles';menu.appendChild(transfer);document.body.appendChild(menu);
  let targetBox=null, transferring=false;
  function showMenu(event) {
    if(!currentDeckBoxId || deckHubMode==='tableSelect' || transferring) return;
    event.preventDefault();event.stopPropagation();targetBox=currentDeckBoxId;
    menu.classList.remove('hidden');
    menu.style.left=Math.max(4,Math.min(event.clientX,innerWidth-menu.offsetWidth-4))+'px';
    menu.style.top=Math.max(4,Math.min(event.clientY,innerHeight-menu.offsetHeight-4))+'px';
  }
  document.querySelector('.deckhub-topbar').addEventListener('contextmenu',showMenu);
  document.querySelector('.deckbox-header').addEventListener('contextmenu',showMenu);
  // Also offer a discoverable button in the box; same server endpoint, no second transfer path.
  const all=document.createElement('button');all.textContent='Add All Bulk Piles';
  document.querySelector('.deckhub-bottombar').appendChild(all);
  all.addEventListener('click',()=>transferToBox(currentDeckBoxId));
  function browseButton(parent) {
    const browse=document.createElement('button');browse.textContent='Browse Card Pile';parent.appendChild(browse);
    browse.addEventListener('click',()=>post('bulkOpen').catch(()=>{}));return browse;
  }
  const browse=browseButton(document.querySelector('.deckhub-bottombar'));
  browseButton(document.querySelector('.deckbox-panel-header'));

  document.addEventListener('pointerdown',event=>{if(!menu.contains(event.target))menu.classList.add('hidden');});
  document.addEventListener('keydown',event=>{if(['Escape','Tab'].includes(event.key))menu.classList.add('hidden');},true);
  transfer.addEventListener('click',()=>transferToBox(targetBox));
  async function transferToBox(box) {
    if(transferring || !box) return;
    transferring=true;all.disabled=transfer.disabled=true;menu.classList.add('hidden');
    let text;
    try {
      const result=await post('bulkToBox',{deckBoxId:box});
      if(!result.ok) throw Error(result.error || 'Transfer failed');
      text=`Moved ${Number(result.count).toLocaleString()} cards. ${result.cleanupPending ? 'Empty pile cleanup will retry automatically.' : 'Empty piles removed.'}`;
      if(currentDeckBoxId===box && !deckHubWrap.classList.contains('hidden')) refreshDeckHub();
      else if(currentDeckBoxId===box && !deckboxWrap.classList.contains('hidden')) refreshDeckBox();
    } catch(error) {text=error.message;}
    finally {transferring=false;all.disabled=transfer.disabled=false;}
    // Do not reopen a closed UI on a late response.
    if(currentDeckBoxId===box && (!deckHubWrap.classList.contains('hidden') || !deckboxWrap.classList.contains('hidden'))) {
      openModal({title:'Bulk Card Piles',text,showInput:false,confirmText:'OK'});
    }
  }
  const watch=new MutationObserver(()=>{all.classList.toggle('hidden',deckHubMode==='tableSelect');browse.classList.toggle('hidden',deckHubMode==='tableSelect');menu.classList.add('hidden');});
  watch.observe(deckHubWrap,{attributes:true,attributeFilter:['class']});
  window.BStarBulkUI={returnFromInspection,close,refresh:()=>{if(active&&!inspecting)load(page);},get currentPile(){return id;}};
})();
