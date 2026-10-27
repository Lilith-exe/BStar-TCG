// One catalogue tile per card; physical copies stay inside its expandable row.
(() => {
  let active=null, revision=0, view=null;
  const resource=()=>GetParentResourceName();
  const categories=new Set(['Good','Played','Damaged']);
  const element=(tag,text,className)=>{const el=document.createElement(tag);if(text)el.textContent=text;if(className)el.className=className;return el;};
  function button(parent,text,action,label){const el=element('button',text);el.type='button';if(label)el.setAttribute('aria-label',label);el.addEventListener('click',action);parent.append(el);return el;}
  function close(focus=false){
    revision++;const previous=active;active=null;
    previous?.controller?.abort();previous?.drawer.remove();
    previous?.tile?.setAttribute('aria-expanded','false');previous?.tile?.removeAttribute('aria-controls');
    if(focus&&previous?.tile?.isConnected)previous.tile.focus();
  }
  function position(state){
    if(active!==state||!state.tile.isConnected)return;
    const scroll=view.container.scrollTop;state.drawer.remove();
    const tiles=[...view.container.children].filter(el=>el.classList.contains('builder-card'));
    let anchor=state.tile;const top=state.tile.offsetTop;
    for(let i=tiles.indexOf(state.tile)+1;i<tiles.length&&Math.abs(tiles[i].offsetTop-top)<2;i++)anchor=tiles[i];
    anchor.after(state.drawer);view.container.scrollTop=scroll;
  }
  function shield(protectedCard,unknown=false){
    const icon=element('span',null,'builder-copy-sleeve'+(protectedCard?' is-sleeved':''));
    const label=unknown?'Sleeve status untracked':protectedCard?'Sleeved':'Unsleeved';
    icon.title=label;icon.setAttribute('role','img');icon.setAttribute('aria-label',label);
    icon.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2 21 6v6c0 5-5 8-9 10-4-2-9-5-9-10V6Z"/>'+(unknown?'<path d="M12 7v6m0 3v1"/>':protectedCard?'<path d="m7 12 3 3 7-7"/>':'<path d="M7 12h10"/>')+'</svg>';
    return icon;
  }
  function actions(state,card,event){
    window.BStarSleeves?.menu(event,{card,context:state.context,actions:[{label:'Add to deck',run:()=>{setBuilderPreview(card);addCardToSelectedDeck(card.cardId);}}]});
  }
  function copyTile(state,copy,index){
    const card={...state.card,sleeveId:undefined,sleeve:undefined,conditionCategory:undefined,copyId:undefined,...copy,variants:undefined,amount:1,sleeveContext:state.context};
    const tile=element('article',null,'builder-copy');tile.setAttribute('role','listitem');
    tile.append(element('span',`Copy ${index+1}`,'builder-copy-number'));
    const preview=button(tile,'',()=>setBuilderPreview(card),`Preview copy ${index+1}`);preview.className='builder-copy-art';
    const image=element('img');image.src=getThumbImagePath(card);image.alt=card.name||'Card';image.loading='lazy';image.draggable=false;
    image.onerror=()=>{image.onerror=null;image.src=getFullImagePath(card);};preview.append(image);
    const status=element('div',null,'builder-copy-status');
    const category=categories.has(copy.conditionCategory)?copy.conditionCategory:'Untracked';
    const condition=element('span',category,'builder-copy-condition');condition.dataset.condition=category;
    status.append(condition,shield(!!copy.sleeveId,!!copy.sleeve?.legacy));tile.append(status);
    const controls=element('div',null,'builder-copy-actions');
    button(controls,'Inspect',()=>openFullViewer(card,false,true),`Inspect copy ${index+1}`);
    button(controls,'Actions',event=>actions(state,card,event),`Actions for copy ${index+1}`);tile.append(controls);
    tile.addEventListener('contextmenu',event=>actions(state,card,event));
    window.BStarSleeveVisuals?.bind(image,card);return tile;
  }
  function render(state){
    state.track.replaceChildren();
    state.rows.forEach((copy,index)=>state.track.append(copyTile(state,copy,index)));
    const legacyVariants=state.card.variants?.filter(v=>v.legacy)||[];
    const legacy=state.card.variants?legacyVariants.reduce((sum,v)=>sum+(v.amount||0),0):Math.max(0,(state.card.amount||0)-state.total);
    if(legacy>0){
      const tile=element('article',null,'builder-copy builder-copy-legacy');tile.setAttribute('role','listitem');
      tile.append(element('strong',`${legacy} older ${legacy===1?'copy':'copies'}`),shield(false,true),element('span','Condition untracked'),element('small','Withdraw these copies to track them individually.'));
      state.track.append(tile);
    }
    if(!state.rows.length&&!legacy)state.track.append(element('p','No matching physical copies. Refresh the collection if cards have moved.','builder-copy-empty'));
    if(state.page<state.pages){
      const more=button(state.track,'Load more copies',()=>load(state,true));more.className='builder-copy-more';more.disabled=state.loading;
    }
    state.note.textContent=`${state.total+legacy} ${state.total+legacy===1?'copy':'copies'}${state.status==='all'?'':' matching the sleeve filter'} · ${state.rows.length} individually tracked shown`;
    requestAnimationFrame(()=>updateArrows(state));
  }
  function updateArrows(state){
    const track=state.track;state.previous.disabled=track.scrollLeft<=1;state.next.disabled=track.scrollLeft+track.clientWidth>=track.scrollWidth-2;
  }
  async function load(state,more=false){
    if(active!==state||state.loading)return;
    state.loading=true;state.note.textContent='Loading copies…';
    if(more)state.track.querySelector('.builder-copy-more')?.setAttribute('disabled','');
    const stamp=revision,controller=new AbortController();state.controller=controller;
    const timer=setTimeout(()=>controller.abort(),15000);
    try{
      const response=await fetch(`https://${resource()}/sleeveList`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({context:state.context,cardIds:[state.card.cardId||state.card.id],sleeveStatus:state.status,page:more?state.page+1:1}),signal:controller.signal});
      if(!response.ok)throw Error('Copies unavailable');const result=await response.json();
      if(active!==state||stamp!==revision||!state.tile.isConnected)return;
      if(!result.ok)throw Error(result.error||'Copies unavailable');
      const scroll=state.track.scrollLeft;
      const seen=new Set(state.rows.map(row=>row.copyId));
      for(const row of result.cards||[]){
        if(row.cardId!==(state.card.cardId||state.card.id)||!row.copyId||seen.has(row.copyId))continue;
        seen.add(row.copyId);state.rows.push(row);
      }
      state.total=Number(result.total)||0;state.page=Number(result.page)||1;state.pages=Number(result.pages)||1;state.loading=false;
      render(state);state.track.scrollLeft=scroll;
    }catch(error){
      if(active!==state||stamp!==revision)return;
      state.loading=false;state.note.textContent=error.name==='AbortError'?'Copies took too long to load.':error.message;
      state.track.querySelector('.builder-copy-more')?.remove();
      const retry=button(state.track,'Retry',()=>{retry.remove();load(state,more);});retry.className='builder-copy-more';
    }finally{clearTimeout(timer);if(active===state)state.loading=false;}
  }
  function open(tile,card){
    close();const context={location:'box',id:view.box};
    const drawer=element('section',null,'builder-copy-drawer');drawer.id='builderPhysicalCopies';drawer.setAttribute('aria-label',`${card.name||'Card'} copies`);
    const header=element('div',null,'builder-copy-header');header.append(element('strong',card.name||'Card copies'));
    const navigation=element('div',null,'builder-copy-navigation');header.append(navigation);drawer.append(header);
    const track=element('div',null,'builder-copy-track');track.setAttribute('role','list');track.setAttribute('aria-label','Physical copies');track.tabIndex=0;
    const state={tile,card,context,drawer,track,status:view.status,rows:[],page:0,pages:1,total:0,loading:false};active=state;
    const scroll=direction=>track.scrollBy({left:direction*Math.max(120,track.clientWidth*.8),behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'instant':'smooth'});
    state.previous=button(navigation,'‹',()=>scroll(-1),'Previous copies');state.next=button(navigation,'›',()=>scroll(1),'Next copies');
    button(navigation,'×',()=>close(true),'Collapse copies');
    state.note=element('p','Loading copies…','builder-copy-note');state.note.setAttribute('role','status');drawer.append(state.note,track);
    track.addEventListener('scroll',()=>updateArrows(state),{passive:true});
    track.addEventListener('keydown',event=>{if(event.target===track&&['ArrowLeft','ArrowRight'].includes(event.key)){event.preventDefault();scroll(event.key==='ArrowLeft'?-1:1);}});
    tile.setAttribute('aria-expanded','true');tile.setAttribute('aria-controls',drawer.id);position(state);load(state);
  }
  function bindGrid(container,entries,options){
    const old=active&&view?.signature===options.signature&&view?.box===options.box?active.card.cardId||active.card.id:null;
    close();view={container,...options};
    const cards=new Map(entries.filter(Boolean).map(card=>[card.cardId||card.id,card]));
    for(const tile of container.querySelectorAll(':scope > .builder-card')){
      const card=cards.get(tile.dataset.cardId);if(!card)continue;
      tile.setAttribute('role','button');tile.tabIndex=0;tile.setAttribute('aria-expanded','false');tile.setAttribute('aria-label',`${card.name||card.cardId}: show copies`);
      tile.addEventListener('click',()=>{if(active?.tile===tile)close();else open(tile,card);});
      tile.addEventListener('keydown',event=>{if(['Enter',' '].includes(event.key)){event.preventDefault();tile.click();}});
      if(old===(card.cardId||card.id))open(tile,card);
    }
  }
  window.addEventListener('keydown',event=>{
    if(event.key!=='Escape'||!active||!active.drawer.isConnected||!document.getElementById('viewerWrap').classList.contains('hidden'))return;
    close(true);event.preventDefault();event.stopImmediatePropagation();
  },true);
  for(const id of ['deckboxCloseBtn','closeDeckBuilderBtn','deckHubCloseBtn'])document.getElementById(id)?.addEventListener('click',()=>close(),true);
  window.addEventListener('message',({data})=>{if(['forceCloseAll','hideCard','showCard','packPending','bulkOpen','openDeckBox','openDeckBuilder','openDuelUi','sleeveClosed'].includes(data?.action))close();});
  window.addEventListener('resize',()=>{if(active){position(active);updateArrows(active);}});
  window.BStarBuilderCopies={bindGrid,close};
})();

