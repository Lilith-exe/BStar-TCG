// Contextual sleeve actions. The server retains all copy/inventory authority.
(() => {
  const pop=document.createElement('div');pop.className='sleeve-context hidden';pop.setAttribute('role','dialog');pop.setAttribute('aria-label','Card actions');document.body.appendChild(pop);
  const browsers=new Map();let revision=0,picker=null,viewed=null;
  const key=c=>c.copyId||`slot:${c.slot}`;
  const identity=c=>({copyId:c.copyId,slot:c.slot});
  const sleeve=c=>c.sleeveId|| (c.sleeve?.version===1&&c.sleeve.type)||null;
  const sleeveName=c=>sleeve(c)?'Protected':c.sleeve?.legacy?'Unrecognised sleeve':'Unprotected';
  const summary=c=>[sleeveName(c),c.conditionCategory,c.rarity].filter(Boolean).join(' · ');
  async function post(name,data){
    const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),15000);
    try{const response=await fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data),signal:controller.signal});if(!response.ok)throw Error('Connection unavailable');return await response.json();}finally{clearTimeout(timer);}
  }
  function node(tag,text,className){const el=document.createElement(tag);if(text)el.textContent=text;if(className)el.className=className;return el;}
  function button(parent,text,fn){const el=node('button',text);el.type='button';el.addEventListener('click',fn);parent.appendChild(el);return el;}
  function close(){revision++;picker=null;pop.classList.add('hidden');pop.replaceChildren();}
  function position(anchor){
    const r=anchor?.getBoundingClientRect?.();const x=anchor?.clientX||r?.right||innerWidth/2,y=anchor?.clientY||r?.top||innerHeight/2;
    pop.classList.remove('hidden');pop.style.left=Math.max(8,Math.min(x,innerWidth-pop.offsetWidth-8))+'px';pop.style.top=Math.max(8,Math.min(y,innerHeight-pop.offsetHeight-8))+'px';
  }
  function refresh(context){
    for(const b of browsers.values())if(b.context.location===context.location&&b.context.id===context.id){b.selected.clear();b.refresh?.();}
    if((context.location==='box'&&currentDeckBoxId===context.id)||context.location==='pocket'){if(!deckboxWrap.classList.contains('hidden'))refreshDeckBox();else if(!deckBuilderWrap.classList.contains('hidden'))refreshDeckBuilder(selectedDeck?.id);}
    if(context.location==='pile')window.BStarBulkUI?.refresh?.();
    if(context.location==='binder')window.BStarCollectors?.refresh?.();
  }
  function menu(event,options){
    if(currentDuelState||window.BStarSleeveVisuals?.hidden(options.card))return;
    event?.preventDefault?.();event?.stopPropagation?.();close();
    const card=options.card;pop.appendChild(node('strong',card.name||'Card'));
    for(const action of options.actions||[])button(pop,action.label,()=>{close();action.run();});
    const variants=card.variants||[card],hasSleeved=variants.some(c=>sleeve(c)||c.sleeve?.legacy),hasBare=variants.some(c=>!sleeve(c)&&!c.sleeve?.legacy);
    if(hasBare)button(pop,'Sleeve Card',()=>choose('apply',options,event));
    if(hasSleeved){button(pop,'Change Sleeve',()=>choose('replace',options,event));button(pop,'Remove Sleeve',()=>choose('remove',options,event));}
    button(pop,'Cancel',close);position(event||options.anchor);
  }
  async function choose(action,options,anchor){
    close();const stamp=revision;picker={action,options,rows:[],types:[],busy:false,failed:false};
    const title=node('strong',action==='replace'?'Change Sleeve':action==='remove'?'Remove Sleeve':'Sleeve Card');pop.append(title);
    const status=node('p','Checking available copies and sleeves…');status.setAttribute('role','status');pop.append(status);button(pop,'Cancel',close);position(anchor||options.anchor);
    try{
      const hint=options.card,exact=hint?.copyId&&(!hint.amount||hint.amount===1);
      let result=await post(options.copyListing||'sleeveList',{context:options.context,cardIds:(hint?.cardId||hint?.id)?[hint.cardId||hint.id]:undefined,copyId:exact?hint.copyId:undefined,page:1});
      if(stamp!==revision)return;if(!result.ok)throw Error(result.error||'Cards unavailable');
      const state=picker;state.types=result.types;state.maxBatch=result.maxBatch;
      pop.replaceChildren(title);const copyLabel=node('label','Physical copy');const copySelect=node('select');copySelect.setAttribute('aria-label','Physical copy');copyLabel.append(copySelect);
      let selected=options.selected||null;
      if(!selected){
        pop.append(copyLabel);copySelect.append(new Option('Choose a copy',''));
        function appendRows(rows){for(const row of rows){if(action==='apply'&&(sleeve(row)||row.sleeve?.legacy))continue;if(action!=='apply'&&!sleeve(row))continue;const index=state.rows.length;state.rows.push(row);copySelect.append(new Option(`Copy ${index+1} · ${summary(row)}`,String(index)));}}
        appendRows(result.cards);
        if(exact){const index=state.rows.findIndex(c=>c.copyId===hint.copyId);if(index>=0)copySelect.value=String(index);}
        else if(state.rows.length===1&&result.pages===1)copySelect.value='0';
        if(result.pages>1){let page=1;const more=button(pop,'More copies',async()=>{more.disabled=true;try{const response=await post(options.copyListing||'sleeveList',{context:options.context,cardIds:[hint.cardId||hint.id],page:page+1});if(stamp!==revision)return;if(!response.ok)throw Error(response.error);appendRows(response.cards);page=response.page;more.hidden=page>=response.pages;update();}catch(error){if(stamp===revision)status.textContent=error.message;}finally{more.disabled=false;}});}
      }
      const typeLabel=node('label','Protective sleeve'),types=node('select');types.setAttribute('aria-label','Protective sleeve');typeLabel.append(types);
      const preview=node('img',null,'sleeve-back-preview');preview.alt='Sleeve back';
      if(action!=='remove')pop.append(typeLabel);
      const note=node('p',action==='replace'?'Protective sleeves are invisible. Reusable sleeves return to inventory when replaced. Deck backs are chosen separately.':'Invisible protection for this physical card. Reusable sleeves return to inventory when removed.');note.className='sleeve-context-note';pop.append(note,status);
      const controls=node('div',null,'sleeve-context-actions');pop.append(controls);
      const confirm=button(controls,'Confirm',async()=>{
        if(state.busy||state.failed||(!selected&&copySelect.value===''))return;const cards=selected||[state.rows[Number(copySelect.value)]];if(!cards.length||!cards[0])return;
        state.busy=true;confirm.disabled=true;types.disabled=copySelect.disabled=true;status.textContent='Saving…';
        try{const response=await post('sleeveChange',{context:options.copyListing?cards[0].sleeveContext:options.context,action,sleeveType:types.value,cards:cards.map(identity)});
          if(response.ok){
            refresh(options.context);
            const updated=response.cards?.find(c=>c.copyId===viewed?.card?.copyId);
            if(updated&&!viewerWrap.classList.contains('hidden')){viewed.card={...viewed.card,...updated};setViewerImage(viewed.card.image||getFullImagePath(viewed.card),viewed.card);}
          }
          if(stamp!==revision)return;
          if(!response.ok)throw Error(response.error||'Operation could not complete');
          state.failed=true;status.textContent=`Updated ${response.count} ${response.count===1?'card':'cards'}.${response.skipped?' '+response.skipped+' already used this sleeve.':''}`;confirm.hidden=true;cancel.textContent='Done';
        }catch(error){if(stamp===revision){state.failed=true;status.textContent=error.message+'. Reopen card actions to reconcile before retrying.';confirm.disabled=true;}}
        finally{state.busy=false;}
      });const cancel=button(controls,'Cancel',close);
      function update(){
        const cards=selected||(copySelect.value!==''?[state.rows[Number(copySelect.value)]]:[]);const previous=types.value;types.replaceChildren();
        for(const t of state.types){const required=action==='replace'?cards.filter(c=>sleeve(c)!==t.id).length:cards.length;if(t.count<required||t.count<=0||(action==='replace'&&cards.length&&required===0))continue;types.append(new Option(`${t.label} · ${t.count} available`,t.id));}
        if([...types.options].some(o=>o.value===previous))types.value=previous;
        const back=window.BStarSleeveVisuals?.types[types.value]?.back;preview.hidden=!back;if(back)preview.src=back;
        confirm.disabled=!cards.length||cards.length>state.maxBatch||(action!=='remove'&&!types.value)||state.failed||state.busy;
        confirm.textContent=action==='replace'?`Replace sleeves (${cards.length})`:action==='remove'?`Remove sleeves (${cards.length})`:`Apply sleeves (${cards.length})`;
        status.textContent=!cards.length?'Choose the physical copy to change.':action!=='remove'&&!types.value?'No suitable sleeves available for this selection.':`${cards.length} ${cards.length===1?'copy selected':'copies selected'} · saved together`;
      }
      copySelect.addEventListener('change',update);types.addEventListener('change',()=>{const back=window.BStarSleeveVisuals?.types[types.value]?.back;preview.hidden=!back;if(back)preview.src=back;});update();position(anchor||options.anchor);
    }catch(error){if(stamp===revision)status.textContent=error.message;}
  }
  function browser(container,entries,context,options={}){
    let b=browsers.get(container);
    if(!b){
      const header=container.closest('.deckbox-panel,.deckbuilder-panel')?.querySelector('.deckbox-panel-header,.deckbuilder-owned-header');if(!header)return;
      b={container,selected:new Map(),active:false,revision:0,entries:[],context};browsers.set(container,b);
      b.toggle=button(header,'Select cards',()=>{b.active=!b.active;b.selected.clear();b.revision++;if(b.active)loadBrowser(b);else b.refresh?.();updateBar(b);});b.toggle.className='sleeve-select-toggle';
      b.bar=node('div',null,'sleeve-selection-bar hidden');container.before(b.bar);b.count=node('span');b.bar.append(b.count);
      b.all=button(b.bar,'Select visible',()=>{if(b.rows.length>b.maxBatch){b.count.textContent=`Select at most ${b.maxBatch} copies`;return;}for(const c of b.rows)b.selected.set(key(c),c);paintSelection(b);});
      button(b.bar,'Deselect',()=>{b.selected.clear();paintSelection(b);});
      b.apply=button(b.bar,'Sleeve selected',()=>choose('apply',{context:b.context,selected:[...b.selected.values()]},b.apply));
      b.replace=button(b.bar,'Change sleeves',()=>choose('replace',{context:b.context,selected:[...b.selected.values()]},b.replace));
      b.remove=button(b.bar,'Remove sleeves',()=>choose('remove',{context:b.context,selected:[...b.selected.values()]},b.remove));
    }
    const signature=JSON.stringify([context,entries.map(c=>c.cardId||c.id),options.status]);
    if(b.signature!==signature)b.selected.clear();b.signature=signature;b.entries=entries;b.context=context;b.options=options;b.refresh=options.refresh;
    updateBar(b);if(b.active)loadBrowser(b);
  }
  function updateBar(b){b.toggle.textContent=b.active?'Done selecting':'Select cards';b.bar.classList.toggle('hidden',!b.active);if(b.active)paintSelection(b);}
  function paintSelection(b){
    b.count.textContent=`${b.selected.size} selected${b.maxBatch?' · max '+b.maxBatch:''}`;
    for(const tile of b.container.querySelectorAll('[data-sleeve-copy]')){const c=b.tileCards.get(tile);const selected=b.selected.has(key(c));tile.classList.toggle('sleeve-selected',selected);tile.setAttribute('aria-pressed',String(selected));}
    const selected=[...b.selected.values()],sleeved=selected.filter(c=>sleeve(c)||c.sleeve?.legacy).length;
    b.apply.disabled=!selected.length||sleeved>0;b.replace.disabled=!selected.length||sleeved===0;b.remove.disabled=!selected.length||sleeved!==selected.length;
  }
  async function loadBrowser(b,more=false){
    const stamp=++b.revision;if(!more){b.rows=[];b.page=0;b.container.replaceChildren();b.selected.clear();}
    b.count.textContent='Loading individual copies…';b.all.disabled=true;
    const ids=[...new Set(b.entries.map(c=>c.cardId||c.id))];if(!ids.length){b.count.textContent='No matching cards';return;}
    try{const result=await post('sleeveList',{context:b.context,cardIds:ids,sleeveStatus:b.options.status||'all',page:b.page+1});if(stamp!==b.revision||!b.active)return;if(!result.ok)throw Error(result.error||'Copies unavailable');
      b.maxBatch=result.maxBatch;b.page=result.page;b.pages=result.pages;b.rows.push(...result.cards.slice(0,b.maxBatch-b.rows.length));
      const order=new Map(ids.map((id,i)=>[id,i]));b.rows.sort((a,c)=>(order.get(a.cardId)??0)-(order.get(c.cardId)??0));renderCopies(b);b.all.disabled=false;
    }catch(error){if(stamp===b.revision)b.count.textContent=error.message;}
  }
  function renderCopies(b){
    b.container.replaceChildren();b.tileCards=new WeakMap();
    for(const c of b.rows){const card={...b.entries.find(e=>(e.cardId||e.id)===c.cardId),sleeveId:undefined,sleeve:undefined,conditionCategory:undefined,copyId:undefined,...c,amount:1,variants:undefined,sleeveContext:b.context};
      const tile=node('div',null,b.options.builder?'builder-card':'deckbox-card');tile.dataset.sleeveCopy='';tile.setAttribute('role','button');tile.tabIndex=0;
      const frame=node('div',null,b.options.builder?'builder-card-image-wrap':'deckbox-card-image-wrap'),img=node('img');img.src=getThumbImagePath(card);img.loading='lazy';img.draggable=false;img.alt=card.name;frame.append(img);tile.append(frame,node('div',card.name,b.options.builder?'builder-card-name':'deckbox-card-name'),node('div',summary(card),'sleeve-copy-caption'));
      b.tileCards.set(tile,c);const toggle=()=>{if(b.selected.has(key(c)))b.selected.delete(key(c));else if(b.selected.size<b.maxBatch)b.selected.set(key(c),c);paintSelection(b);};
      tile.addEventListener('click',toggle);tile.addEventListener('keydown',event=>{if(['Enter',' '].includes(event.key)){event.preventDefault();toggle();}});tile.addEventListener('dblclick',()=>openFullViewer(card,!b.options.builder,!!b.options.builder));
      tile.addEventListener('contextmenu',event=>menu(event,{card,context:b.context}));b.container.append(tile);window.BStarSleeveVisuals?.bind(img,card);
    }
    if(!b.rows.length)b.container.append(node('p','No individual copies here. Withdraw legacy quantity-only cards first.'));
    if(b.page<b.pages&&b.rows.length<b.maxBatch)button(b.container,'Load more copies',()=>loadBrowser(b,true));
    paintSelection(b);
  }
  function handleEscape(event){
    if(!['Escape','Tab'].includes(event.key))return false;
    if(!pop.classList.contains('hidden')){if(event.key==='Escape')close();else return false;}
    else {const b=[...browsers.values()].find(b=>b.active&&b.container.getClientRects().length);if(!b||event.key!=='Escape')return false;b.active=false;b.selected.clear();b.revision++;b.refresh?.();updateBar(b);}
    event.preventDefault();event.stopImmediatePropagation();return true;
  }
  // Capture before the pack/pile Escape handlers, without taking NUI focus.
  window.addEventListener('keydown',handleEscape,true);
  document.addEventListener('pointerdown',event=>{if(!pop.classList.contains('hidden')&&!pop.contains(event.target))close();},true);
  window.addEventListener('resize',close);
  const viewerButton=button(document.querySelector('.viewer-controls'),'Card actions',event=>{if(!viewed?.card)return;menu(event,{card:viewed.card,context:viewed.card.sleeveContext||((viewed.fromDeckBox||viewed.fromDeckBuilder)?{location:'box',id:currentDeckBoxId}:{location:'pocket',id:''}),anchor:viewerButton});});
  viewerButton.classList.add('hidden');
  window.addEventListener('bstar:cardOpened',event=>{viewed=event.detail;viewerButton.classList.toggle('hidden',!!currentDuelState||(!viewed.card.copyId&&!viewed.card.cardId));});
  window.addEventListener('message',({data})=>{if(['sleeveClosed','forceCloseAll','hideCard','packClosed','bulkClosed','packPending','showCard','openDeckBox','openDeckBuilder','openDuelUi'].includes(data?.action)){close();for(const b of browsers.values()){b.active=false;b.revision++;b.selected.clear();updateBar(b);}}});
  for(const id of ['deckboxCloseBtn','closeDeckBuilderBtn','deckHubCloseBtn'])document.getElementById(id)?.addEventListener('click',()=>{close();for(const b of browsers.values()){b.active=false;b.revision++;b.selected.clear();updateBar(b);}},true);
  window.BStarSleeves={menu,browser,handleEscape,close,open:options=>choose('apply',options,options.anchor)};
})();
