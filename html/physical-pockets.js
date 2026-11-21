// Physical pocket copies within the existing Deck Box NUI. No inventory focus owner here.
(() => {
  const el=(tag,text,cls)=>{const n=document.createElement(tag);if(text)n.textContent=text;if(cls)n.className=cls;return n;};
  const root=el('section',null,'pocket-overlay hidden');root.setAttribute('aria-label','Cards in Pockets');root.setAttribute('role','dialog');root.dataset.bstarFoilManaged='true';
  const panel=el('div',null,'pocket-panel'),header=el('header',null,'pocket-header'),title=el('h2','Cards in Pockets');
  const dismiss=el('button','\xd7');dismiss.type='button';dismiss.setAttribute('aria-label','Close Cards in Pockets');header.append(title,dismiss);
  const destination=el('p','', 'pocket-destination');const filters=el('div',null,'pocket-filters');
  const search=el('input');search.type='search';search.placeholder='Search cards';search.setAttribute('aria-label','Search pocket cards');
  const rarity=el('select'),protection=el('select');rarity.setAttribute('aria-label','Pocket rarity');protection.setAttribute('aria-label','Pocket protection');
  for(const [value,label]of [['','All rarities'],...['COMMON','RARE','SUPER','ULTRA','SECRET','GHOST'].map(v=>[v,v])])rarity.append(new Option(label,value));
  for(const [value,label]of [['','All protection'],['yes','Sleeved'],['no','Unsleeved'],['graded','Graded']])protection.append(new Option(label,value));
  const refresh=el('button','Refresh');refresh.type='button';filters.append(search,rarity,protection,refresh);
  const content=el('div',null,'pocket-content'),grid=el('div',null,'pocket-grid'),detail=el('aside',null,'pocket-detail');grid.setAttribute('role','list');content.append(grid,detail);
  const status=el('p','', 'pocket-status');status.setAttribute('role','status');status.setAttribute('aria-live','polite');
  const check=el('button','Check transfer outcome');check.type='button';check.hidden=true;
  panel.append(header,destination,filters,content,status,check);root.append(panel);document.body.append(root);
  let opened=false,context=null,launch=null,cards=[],selected=null,loading=false,sending=false,inspecting=false,revision=0,pending=null;
  const storageKey='bstar:physical-deposit:'+GetParentResourceName();
  try{const saved=JSON.parse(localStorage.getItem(storageKey)||'null');if(saved?.operationId&&saved?.copyId&&saved?.box)pending=saved;}catch{}
  const controllers=new Map();let observer=null;const visible=new Map();
  const host=()=>window.BStarPocketHost;
  const same=ctx=>{const current=host()?.context();return current&&ctx&&current.box===ctx.box&&current.revision===ctx.revision;};
  async function post(name,data){
    const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),15000);
    try{const r=await fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data),signal:controller.signal});if(!r.ok)throw Error('Connection unavailable');return await r.json();}finally{clearTimeout(timer);}
  }
  function stopArt(){observer?.disconnect();observer=null;for(const api of controllers.values())api.destroy();controllers.clear();visible.clear();}
  function syncArt(){
    for(const [image,api]of controllers)if(!visible.has(image)||!image.isConnected){api.destroy();controllers.delete(image);}
    for(const [image,card]of visible){if(controllers.size>=6)break;if(!controllers.has(image)&&image.isConnected){const api=window.BStarRarityRenderer?.attach(image,card);if(api)controllers.set(image,api);}}
  }
  function startArt(){
    stopArt();observer=new IntersectionObserver(entries=>{for(const e of entries){if(e.isIntersecting)visible.set(e.target,e.target._pocketCard);else visible.delete(e.target);}syncArt();},{root:panel,threshold:.1});
    for(const image of root.querySelectorAll('img'))observer.observe(image);
  }
  function artwork(card){const frame=el('div',null,'pocket-art'),image=el('img');image.src=getThumbImagePath(card);image.alt=card.name||'Card';image.loading='lazy';image.draggable=false;image._pocketCard=card;image.onerror=()=>{image.onerror=null;image.src=getFullImagePath(card);};frame.append(image);window.BStarSlabs?.decorate(frame,card);return frame;}
  function summary(card){return [card.slab?`Graded: ${card.slab.label||card.slab.grade}`:card.conditionCategory||'Condition unavailable',card.slab?'Slab protected':card.sleeveId?'Sleeved':'Unsleeved'].join(' \xb7 ');}
  function select(card){if(sending)return;selected=card;paint();}
  const hasValue=value=>value!==null&&value!==undefined&&!['','-','\u2014','\u2013','N/A'].includes(String(value).trim());
  function details(){
    detail.replaceChildren();detail.classList.remove('is-slabbed');if(!selected){detail.append(el('p','Select a physical copy.'));return;}
    const card=selected,art=artwork(card),copy=el('div',null,'pocket-detail-copy'),actions=el('div',null,'pocket-detail-actions');
    art.classList.add('pocket-detail-art');if(card.slab)detail.classList.add('is-slabbed');
    copy.append(el('h3',card.name||card.cardId));
    const paragraph=values=>{const text=values.filter(hasValue).join(' \xb7 ');if(text)copy.append(el('p',text));};
    paragraph([card.rarity,card.setCode,card.edition]);const protection=el('p',null,'pocket-protection');const badge=window.BStarSlabs?.protectionBadge?.(card);if(badge)protection.append(badge);protection.append(el('span',summary(card)));copy.append(protection);
    paragraph([card.type,card.job,hasValue(card.level)?'Level '+String(card.level).replace(/^level\s*/i,''):null]);
    paragraph([hasValue(card.attack)?'ATK: '+card.attack:null,hasValue(card.health)?'HP: '+String(card.health).replace(/^HP\s*:?\s*/i,''):null,hasValue(card.speed)?'SPD: '+card.speed:null]);
    if(hasValue(card.effectTitle))copy.append(el('h4',card.effectTitle));
    if(hasValue(card.effectText))copy.append(el('p',card.effectText,'pocket-effect-text'));
    const inspect=el('button','Inspect');inspect.type='button';inspect.addEventListener('click',()=>{if(same(context)){inspecting=true;openFullViewer(card,false,false);}});actions.append(inspect);
    const add=el('button','Add to Deck Box','pocket-add');add.type='button';add.disabled=!!pending||sending||loading;add.addEventListener('click',deposit);actions.append(add);
    detail.append(art,copy,actions);
  }
  function paint(){
    const scroll=grid.scrollTop;stopArt();grid.replaceChildren();const query=search.value.trim().toLowerCase();
    const filtered=cards.filter(c=>(!query||[c.name,c.cardId,c.setCode].join(' ').toLowerCase().includes(query))&&(!rarity.value||c.rarity===rarity.value)&&(!protection.value||(protection.value==='yes'?!!c.sleeveId:protection.value==='no'?!c.sleeveId:!!c.slab)));
    for(const card of filtered){const tile=el('button',null,'pocket-copy');tile.type='button';if(card.slab)tile.classList.add('is-slabbed');tile.setAttribute('aria-pressed',String(selected?.copyId===card.copyId));tile.setAttribute('aria-label',`${card.name}: ${summary(card)}`);tile.append(artwork(card),el('strong',card.name),el('small',summary(card)));const badge=window.BStarSlabs?.protectionBadge?.(card);if(badge)tile.append(badge);tile.addEventListener('click',()=>select(card));grid.append(tile);}
    if(!filtered.length)grid.append(el('p',cards.length?'No matching pocket cards.':'No physical cards in pockets.'));
    details();grid.scrollTop=scroll;check.hidden=!pending;refresh.disabled=loading||sending;startArt();
  }
  let activeRead=Promise.resolve(false);
  function load(){
    if(!opened||!same(context))return Promise.resolve(false);
    if(loading)return activeRead;
    loading=true;const stamp=revision,ctx={...context};status.textContent='Loading pocket cards...';paint();
    activeRead=(async()=>{
      let loaded=false;
      try{const data=await post('pocketCards',{box:ctx.box});if(!opened||stamp!==revision||!same(ctx))return false;if(!data.ok)throw Error(data.error||'Pocket cards unavailable');cards=(data.cards||[]).filter(c=>typeof c.copyId==='string'&&c.sleeveContext?.location==='pocket');selected=cards.find(c=>c.copyId===selected?.copyId)||null;status.textContent=`${cards.length} physical copies${data.excluded?' - Unavailable or unidentified cards excluded':''}`;loaded=true;}
      catch(error){if(opened&&stamp===revision)status.textContent=error.message+' Use Refresh to try reading again.';}
      finally{if(stamp===revision){loading=false;if(opened)paint();}}
      return loaded;
    })();
    return activeRead;
  }
  async function stock(ctx){const data=await post('physicalBoxStock',{box:ctx.box});if(data.ok&&same(ctx))host().applyStock(data,ctx);else if(!data.ok)throw Error(data.error||'Box stock unavailable');}
  function persist(value){if(value)localStorage.setItem(storageKey,JSON.stringify(value));else localStorage.removeItem(storageKey);pending=value;}
  function operationId(){if(crypto.randomUUID)return crypto.randomUUID();const bytes=crypto.getRandomValues(new Uint8Array(16));bytes[6]=(bytes[6]&15)|64;bytes[8]=(bytes[8]&63)|128;const h=[...bytes].map(b=>b.toString(16).padStart(2,'0')).join('');return `${h.slice(0,8)}-${h.slice(8,12)}-${h.slice(12,16)}-${h.slice(16,20)}-${h.slice(20)}`;}
  async function acknowledge(response,request,ctx){
    if(['complete','rejected'].includes(response.state)&&response.operationId!==request.operationId)throw Error('Transfer response mismatch; check outcome');
    if(response.state==='complete'&&response.ok){
      if(response.copyId!==request.copyId||response.box!==request.box)throw Error('Transfer identity response mismatch');
      persist(null);
      // A complete receipt proves this exact token left pockets, even if a later read fails.
      if(opened&&same(ctx)){cards=cards.filter(card=>card.copyId!==request.copyId);if(selected?.copyId===request.copyId)selected=null;paint();}
      let refreshed=true;
      // Both read endpoints use the character storage mutex. Never race them.
      if(opened&&same(ctx)){
        if(loading)await activeRead;
        if(opened&&same(ctx)){
          cards=cards.filter(card=>card.copyId!==request.copyId);if(selected?.copyId===request.copyId)selected=null;paint();
          refreshed=await load();
        }
      }
      if(same(ctx)){try{await stock(ctx);}catch{refreshed=false;}}
      if(opened&&same(ctx))status.textContent=!refreshed?'Card stored. Some collection details still need refreshing.':('Card stored. '+(host().notice()||''));
    }else if(response.state==='rejected'){
      persist(null);if(opened&&same(ctx))status.textContent=response.error||'No transfer completed.';
    }else if(opened){status.textContent=response.error||'Outcome unconfirmed. Check this operation; do not submit again.';}
  }
  async function deposit(){
    if(pending||sending||loading||!selected||!same(context))return;
    let request;const ctx={...context};
    try{request={operationId:operationId(),copyId:selected.copyId,box:context.box};persist(request);}catch{status.textContent='Cannot retain the operation ID safely; no transfer sent.';return;}
    sending=true;status.textContent='Storing this physical copy\u2026';paint();
    try{await acknowledge(await post('physicalDeposit',request),request,ctx);}catch{if(opened)status.textContent='Outcome unconfirmed. Use Check transfer outcome; do not submit again.';}
    finally{sending=false;if(opened){paint();}}
  }
  async function outcome(){
    if(!pending||sending)return;const request={...pending},ctx={...context};sending=true;check.disabled=true;status.textContent='Checking durable transfer record\u2026';
    try{await acknowledge(await post('physicalDepositStatus',request),request,{...ctx,box:request.box});}catch{if(opened)status.textContent='Cannot confirm the ledger. Operation retained; do not submit again.';}
    finally{sending=false;check.disabled=false;if(opened)paint();}
  }
  function close(){if(!opened)return;opened=false;inspecting=false;revision++;loading=false;root.classList.add('hidden');stopArt();launch?.focus();}
  function open(button){
    const ctx=host()?.context();if(!ctx)return;close();opened=true;context=ctx;launch=button;revision++;root.classList.remove('hidden');destination.textContent='Destination: Deck Box '+ctx.box;cards=[];selected=null;search.focus();load();if(pending){check.hidden=false;status.textContent='A previous transfer is unconfirmed. Check its outcome before depositing another copy.';}
  }
  dismiss.addEventListener('click',close);refresh.addEventListener('click',async()=>{const ctx=context;if(!ctx)return;await load();if(same(ctx))stock(ctx).catch(error=>{if(opened&&same(ctx))status.textContent=error.message;});});check.addEventListener('click',outcome);
  search.addEventListener('input',paint);rarity.addEventListener('change',paint);protection.addEventListener('change',paint);
  for(const button of document.querySelectorAll('[data-pocket-cards]'))button.addEventListener('click',()=>open(button));
  window.addEventListener('keydown',event=>{
    if(!opened||!document.getElementById('viewerWrap').classList.contains('hidden')||!document.getElementById('uiModalWrap').classList.contains('hidden'))return;
    if(event.key==='Escape'){event.preventDefault();event.stopImmediatePropagation();close();}
    else if(event.key==='Tab'){const controls=[...panel.querySelectorAll('button,input,select')].filter(n=>!n.disabled&&!n.hidden);const index=controls.indexOf(document.activeElement);event.preventDefault();event.stopImmediatePropagation();controls[index<0?(event.shiftKey?controls.length-1:0):(index+(event.shiftKey?-1:1)+controls.length)%controls.length]?.focus();}
  },true);
  let drag=null;header.addEventListener('pointerdown',event=>{if(event.target.closest('button'))return;const rect=panel.getBoundingClientRect();drag={x:event.clientX-rect.left,y:event.clientY-rect.top};header.setPointerCapture(event.pointerId);});
  header.addEventListener('pointermove',event=>{if(!drag)return;panel.style.position='fixed';panel.style.left=Math.max(8,Math.min(event.clientX-drag.x,innerWidth-panel.offsetWidth-8))+'px';panel.style.top=Math.max(8,Math.min(event.clientY-drag.y,innerHeight-panel.offsetHeight-8))+'px';panel.style.margin='0';});header.addEventListener('pointerup',()=>{drag=null;});header.addEventListener('lostpointercapture',()=>{drag=null;});
  window.addEventListener('message',({data})=>{if(['forceCloseAll','openDeckBuilder','openDeckBox','openDuelUi','packPending','bulkOpen','showCard','openBinder','openGrading'].includes(data?.action))close();});
  window.addEventListener('resize',()=>{if(panel.style.position==='fixed'){const r=panel.getBoundingClientRect();panel.style.left=Math.max(8,Math.min(r.left,innerWidth-panel.offsetWidth-8))+'px';panel.style.top=Math.max(8,Math.min(r.top,innerHeight-panel.offsetHeight-8))+'px';}});
  window.BStarPhysicalPockets={close,returnFromInspection(){if(!opened||!inspecting||!same(context))return false;inspecting=false;return true;}};
})();
