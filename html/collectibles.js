// Physical collector UI. Identity/custody/condition/grading remain server-owned.
(() => {
  const observedLabels=new Set();
  const labelObserver=new ResizeObserver(entries=>{for(const {target,contentRect}of entries)target.style.setProperty('--hcg-label-font',Math.max(5,contentRect.width*.042)+'px');});
  const el=(tag,text,cls)=>{const n=document.createElement(tag);if(text!=null)n.textContent=text;if(cls)n.className=cls;return n;};
  function btn(parent,text,fn,cls){const b=el('button',text,cls);b.type='button';b.addEventListener('click',fn);parent.append(b);return b;}
  function decorate(frame,card,viewer=false){
    const slab=card?.slab;const previous=frame.querySelector(':scope > .hcg-shell');if(previous){labelObserver.unobserve(previous);observedLabels.delete(previous);previous.remove();}frame.classList.toggle('hcg-slab',!!slab);frame.classList.toggle('hcg-viewer',!!slab&&viewer);
    if(viewer)frame.parentElement?.classList.toggle('hcg-viewer-open',!!slab);
    if(!slab)return;
    const shell=el('div',null,'hcg-shell');shell.setAttribute('aria-label',`${slab.brand||'HARDCORE'} graded slab, ${slab.label||slab.grade}`);
    const label=el('div',null,'hcg-label');const brand=el('div',null,'hcg-brand');
    const mark=el('span','HC','hcg-mark');mark.setAttribute('aria-hidden','true');
    const wordmark=el('div',null,'hcg-wordmark');wordmark.append(el('strong',slab.brand||'HARDCORE'),el('small','COMICS · CARD GRADING'));brand.append(mark,wordmark);
    const grade=el('div',null,'hcg-grade');grade.append(el('strong',String(slab.grade)),el('small',slab.label==='Gem 10'?'GEM MINT':slab.grade===0?'DESTROYED':'GRADED'));
    label.append(brand,grade);const identity=el('div',null,'hcg-identity');identity.append(el('strong',card.name||'BStar collectible'),el('small',[card.setCode,card.edition,card.rarity].filter(Boolean).join(' · ')));
    const serial=String(slab.certificate||'');const barcode=el('div',null,'hcg-barcode');for(let i=0;i<48;i++){const bar=el('i');bar.style.width=(1+(serial.charCodeAt(i%Math.max(1,serial.length))||i)%3)+'px';barcode.append(bar);}
    label.append(identity,barcode,el('small',serial.slice(-12).toUpperCase(),'hcg-serial'));
    const stamp=el('span','HCG','hcg-case-stamp');stamp.setAttribute('aria-hidden','true');
    shell.append(label,el('div',null,'hcg-inner-lip'),stamp);frame.append(shell);labelObserver.observe(shell);observedLabels.add(shell);
  }
  new MutationObserver(()=>{for(const shell of observedLabels)if(!shell.isConnected){labelObserver.unobserve(shell);observedLabels.delete(shell);}}).observe(document.body,{childList:true,subtree:true});
  window.BStarSlabs={decorate};
  const root=el('section',null,'collector-overlay hidden');root.setAttribute('aria-label','Hardcore collector');document.body.append(root);
  let state=null,revision=0;
  const controllers=new Set();
  async function post(name,data){
    const controller=new AbortController();controllers.add(controller);const timer=setTimeout(()=>controller.abort(),20000);
    try{const response=await fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data||{}),signal:controller.signal});if(!response.ok)throw Error('Connection unavailable');const result=await response.json();if(!result.ok)throw Error(result.error||'Unavailable');return result;}
    finally{clearTimeout(timer);controllers.delete(controller);}
  }
  function close(notify=true){revision++;state=null;root.replaceChildren();root.classList.add('hidden');root.classList.remove('collector-inspecting');if(!viewerWrap.classList.contains('hidden'))closeFullViewer(false);for(const c of controllers)c.abort();window.BStarSleeves?.close();if(notify)post('collectorClose',{}).catch(()=>{});}
  function note(message){if(state)state.status.textContent=message;}
  function art(card,full=false){
    const frame=el('div',null,'collector-art');const img=el('img');img.src=full?getFullImagePath(card):getThumbImagePath(card);img.alt=card.name||'Card';img.draggable=false;
    img.onerror=()=>{img.onerror=null;img.src=getFullImagePath(card);};const well=el('div',null,'collector-art-well');well.append(img);frame.append(well);window.BStarSleeveVisuals?.bind(img,{...card,variants:undefined});decorate(frame,card);return frame;
  }
  function safeCard(card){return {...card,variants:undefined,amount:1};}
  function copySummary(card){return [card.conditionCategory||'Untracked',card.sleeveId?'Sleeved':'Unsleeved',card.slab?`Grade ${card.slab.label||card.slab.grade}`:null].filter(Boolean).join(' · ');}
  async function loadSource(more=false,preserve=false){
    const s=state;if(!s)return;
    if(s.loading){if(!more){s.reloadQueued=true;s.sourceToken=(s.sourceToken||0)+1;}return;}
    s.loading=true;const token=(s.sourceToken||0)+1;s.sourceToken=token;const source={...s.source};const scroll=s.tray.scrollTop;
    s.sidebar?.classList.add('library-loading');
    const query={context:source,page:more?s.sourcePage+1:1,...(s.binderView?s.filters:{})};
    if(s.binderView)s.libraryCount.textContent='Loading cards…';
    try{let result=await post(s.binderView?'collectorLibrary':'sleeveList',query);if(preserve&&s.binderView){const cards=[...result.cards];let page=1;for(;page<Math.min(s.sourcePage,result.pages);){const extra=await post('collectorLibrary',{...query,page:++page});cards.push(...extra.cards);}result={...result,cards,page};}if(state!==s||s.sourceToken!==token)return;s.sourcePage=result.page;s.sourcePages=result.pages;s.sourceTotal=result.total;s.sourceCards=more?s.sourceCards.concat(result.cards):result.cards;
      if(s.binderView){
        for(const [select,values]of [[s.typeSelect,result.cardTypes],[s.raritySelect,result.rarities]]){
          if(!values)continue;const value=select.value;select.replaceChildren(new Option('All '+(select===s.typeSelect?'types':'rarities'),'all'));
          for(const entry of values)select.append(new Option(entry,entry));select.value=[...select.options].some(o=>o.value===value)?value:'all';
        }
        s.libraryCount.textContent=`${result.total} ${result.total===1?'copy':'copies'} · ${s.sourceCards.length} shown`;
      }else note(`${result.total} individually tracked cards in this location. Older quantity-only cards must be withdrawn or converted first.`);
      renderTray();s.tray.scrollTop=more||preserve?scroll:0;
    }catch(error){if(state===s&&s.sourceToken===token){if(s.binderView)s.libraryCount.textContent='Could not load cards';note(error.name==='AbortError'?'Loading timed out. Close and reopen to reconcile.':error.message);}}finally{if(state===s){s.loading=false;s.sidebar?.classList.remove('library-loading');if(s.reloadQueued){s.reloadQueued=false;loadSource();}}}
  }
  function selectCard(card,context){
    const s=state;if(!s||s.busy||s.failed||s.loading||s.turning)return;
    s.selected={card:safeCard(card),context:{...context}};s.inspection?.remove();s.inspection=null;
    if(s.mode==='binder'){
      renderBook();renderTray();
      note(context.location==='binder'?'Click another card to swap, or an empty pocket to move.':'Click an empty pocket to add this copy.');
    }else{renderTray();renderGrading();}
  }
  function clearSelection(){if(!state)return;state.selected=null;renderBook();renderTray();note('Selection cleared.');}
  function renderTray(){
    const s=state;const scroll=s.tray.scrollTop;s.tray.replaceChildren();
    for(const raw of s.sourceCards){const card=safeCard(raw);const tile=btn(s.tray,'',()=>{if(s.busy||s.failed)return;if(s.binderView)inspect(card,s.source);else selectCard(card,s.source);},'collector-source-card');tile.setAttribute('aria-label',`Select ${card.name}: ${copySummary(card)}`);tile.classList.toggle('selected',s.selected?.card.copyId===card.copyId&&s.selected?.card.slot===card.slot);tile.append(art(card),el('span',card.name),el('small',copySummary(card)));
      tile.addEventListener('contextmenu',event=>{event.preventDefault();event.stopPropagation();selectCard(card,s.source);});
      tile.draggable=true;tile.addEventListener('dragstart',event=>{if(s.busy||s.failed||s.loading||s.turning){event.preventDefault();return;}s.selected={card,context:{...s.source}};if(s.binderView)renderBook();event.dataTransfer.setData('text/plain','bstar-card');});
    }
    if(!s.sourceCards.length)s.tray.append(el('p',s.binderView?'No matching copies. Try another source or change the filters.':'No individual cards here. Try another location.','collector-empty'));
    if(s.sourcePage<s.sourcePages)btn(s.tray,'Load more copies',()=>loadSource(true));s.tray.scrollTop=scroll;
  }
  function inspect(card,context){
    const s=state;if(!s||s.busy)return;
    s.inspecting=true;root.classList.add('collector-inspecting');
    openFullViewer({...safeCard(card),sleeveContext:context});
  }
  function returnFromInspection(){
    if(!state?.inspecting)return false;
    state.inspecting=false;root.classList.remove('collector-inspecting');app.classList.add('hidden');return true;
  }
  async function refreshBinder(){
    const s=state;const result=await post('binderPage',{id:s.result.id});if(state!==s)return;s.result=result;s.inspection?.remove();s.inspection=null;renderBook();
  }
  async function move(payload){
    const s=state;if(!s||s.busy||s.failed)return;s.busy=true;note('Saving this physical card…');
    s.sidebar?.querySelectorAll('input,select').forEach(input=>input.disabled=true);
    try{await post('binderMove',{id:s.result.id,...payload});if(state!==s)return;s.selected=null;await refreshBinder();await loadSource(false,true);note('Card saved in its new position.');}
    catch(error){if(state===s){s.failed=true;note(error.message+'. Close and reopen before retrying.');}}
    finally{if(state===s){s.busy=false;s.sidebar?.querySelectorAll('input,select').forEach(input=>input.disabled=false);}}
  }
  function choosePocket(slot,card){
    const s=state;if(s.busy||s.failed||s.turning)return;
    if(s.loading){note('Wait for the card library to finish loading.');return;}
    if(s.selected){
      if(card&&s.selected.context.location!=='binder'){note('Choose an empty pocket for the selected library card.');return;}
      if(card&&card.copyId===s.selected.card.copyId){clearSelection();return;}
      move({source:s.selected.context,copyId:s.selected.card.copyId,sourceSlot:s.selected.card.slot,pocket:slot});return;
    }
    if(card)inspect(card,{location:'binder',id:s.result.id});else note('Select a physical card from the tray, then choose this pocket.');
  }
  function pageSnapshot(page){
    if(!page)return null;const clone=page.cloneNode(true);clone.dataset.bstarFoilSnapshot='true';clone.setAttribute('aria-hidden','true');clone.inert=true;
    const originals=page.querySelectorAll('canvas');
    clone.querySelectorAll('canvas').forEach((canvas,index)=>{if(originals[index].width&&originals[index].height)canvas.getContext('2d').drawImage(originals[index],0,0);});
    return clone;
  }
  function turnPage(direction){
    const s=state;if(!s||s.busy||s.turning)return;
    const next=s.spread+direction;if(next<0||next*2>=s.result.pages)return;
    const animated=!matchMedia('(prefers-reduced-motion: reduce)').matches;
    const old=animated?pageSnapshot(s.content.querySelector(direction>0?'.collector-page.right':'.collector-page.left')):null;
    const covered=animated?pageSnapshot(s.content.querySelector(direction>0?'.collector-page.left':'.collector-page.right')):null;
    s.spread=next;s.turning=animated;renderBook();if(!old)return;
    const book=s.content.querySelector('.collector-book');const side=direction>0?'forward':'backward';
    old.className='collector-page collector-turn-leaf '+side;
    covered.className='collector-page collector-covered-page '+side;book.append(covered,old);
    const incoming=book.querySelector(direction>0?'.collector-page.left':'.collector-page.right');incoming.classList.add('collector-arriving-page',side);
    const finish=()=>{old.remove();covered.remove();incoming.classList.remove('collector-arriving-page',side);if(state===s){s.turning=false;s.previous.disabled=!!s.turning||s.spread===0;s.next.disabled=!!s.turning||(s.spread+1)*2>=s.result.pages;}};
    old.addEventListener('animationend',finish,{once:true});setTimeout(finish,850);
  }
  function returnCard(destination,box){
    const s=state;if(!s?.selected||s.selected.context.location!=='binder'||s.busy||s.turning)return;
    move({copyId:s.selected.card.copyId,source:s.selected.context,destination,box});
  }
  function bindReturnTarget(target,destination,box){
    target.addEventListener('dragover',event=>{if(state?.selected?.context.location==='binder'){event.preventDefault();target.classList.add('binder-drop-ready');}});
    target.addEventListener('dragleave',()=>target.classList.remove('binder-drop-ready'));
    target.addEventListener('drop',event=>{event.preventDefault();event.stopPropagation();target.classList.remove('binder-drop-ready');returnCard(destination,destination==='box'?state?.returnBox:box);});
  }
  function renderBook(){
    const s=state;s.content.replaceChildren();const book=el('div',null,'collector-book');s.content.append(book);const start=s.spread*2;
    for(let side=0;side<2;side++){
      const page=el('section',null,'collector-page '+(side?'right':'left'));page.setAttribute('aria-label',`Binder page ${start+side+1}`);const grid=el('div',null,'collector-pockets');page.append(grid);
      for(let pocket=1;pocket<=s.result.pocketsPerPage;pocket++){
        const slot=(start+side)*s.result.pocketsPerPage+pocket;const card=s.result.cards.find(c=>c.binderSlot===slot);
        const target=btn(grid,'',()=>choosePocket(slot,card),'collector-pocket');target.setAttribute('aria-label',`Pocket ${slot}${card?': '+card.name:': empty'}`);target.append(el('small',String(slot),'collector-pocket-number'));
        target.classList.toggle('binder-occupied',!!card);
        target.classList.toggle('binder-pocket-selected',!!card&&s.selected?.context.location==='binder'&&s.selected.card.copyId===card.copyId);
        target.setAttribute('aria-pressed',String(!!card&&s.selected?.card.copyId===card.copyId));
        if(card){target.append(art(card));target.draggable=true;
          target.addEventListener('contextmenu',event=>{event.preventDefault();event.stopPropagation();selectCard(card,{location:'binder',id:s.result.id});});
          target.addEventListener('dragstart',event=>{if(s.busy||s.failed||s.loading||s.turning){event.preventDefault();return;}s.selected={card,context:{location:'binder',id:s.result.id}};root.classList.add('binder-has-selection');event.dataTransfer.setData('text/plain','bstar-card');});
          target.addEventListener('dragend',()=>{if(state===s&&!s.busy)renderBook();});
        }
        target.addEventListener('dragover',event=>{if(s.selected)event.preventDefault();});target.addEventListener('drop',event=>{event.preventDefault();choosePocket(slot,card);});
      }
      page.append(el('span',String(start+side+1),'collector-page-number'));book.append(page);
    }
    const spine=el('div',null,'collector-spine');for(let i=0;i<3;i++)spine.append(el('i'));book.append(spine);
    if(s.binderView){
      const toolbar=el('div',null,'binder-corner-controls');book.append(toolbar);
      const add=btn(toolbar,'+',()=>toggleLibrary(!s.libraryOpen),'binder-add-button');add.title='Add to binder';add.setAttribute('aria-label','Add to binder');add.setAttribute('aria-expanded',String(s.libraryOpen));add.dataset.tooltip='Add to binder';s.addButton=add;
      const returns=el('div',null,'binder-return-controls');book.append(returns);
      const pockets=btn(returns,'Pockets',()=>returnCard('pocket'));pockets.title='Move selected binder card to pockets';bindReturnTarget(pockets,'pocket');
      const boxes=s.result.sources.filter(c=>c.location==='box');
      if(boxes.length){const boxSelect=el('select');boxSelect.setAttribute('aria-label','Return Deck Box');for(const box of boxes)boxSelect.append(new Option(box.label,box.id));boxSelect.value=s.returnBox||boxes[0].id;s.returnBox=boxSelect.value;boxSelect.addEventListener('change',()=>s.returnBox=boxSelect.value);if(boxes.length>1)returns.append(boxSelect);
        const box=btn(returns,'Deck Box',()=>returnCard('box',s.returnBox));bindReturnTarget(box,'box',s.returnBox);
      }
      if(s.selected){const cancel=btn(toolbar,'↶',clearSelection);cancel.title='Cancel selection';cancel.setAttribute('aria-label','Cancel card selection');}
      const exit=btn(toolbar,'×',()=>close());exit.title='Close binder';exit.setAttribute('aria-label','Close binder');
      const navigation=el('div',null,'binder-page-controls');book.append(navigation);
      s.previous=btn(navigation,'‹',()=>turnPage(-1));s.previous.title='Previous spread';s.previous.setAttribute('aria-label','Previous spread');
      s.pageLabel=el('span');navigation.append(s.pageLabel);
      s.next=btn(navigation,'›',()=>turnPage(1));s.next.title='Next spread';s.next.setAttribute('aria-label','Next spread');
      if(s.selected)book.append(el('span',s.selected.card.name||'Card selected','binder-selection-caption'));
      root.classList.toggle('binder-has-selection',!!s.selected);
    }
    s.pageLabel.textContent=`Pages ${start+1}–${start+2} / ${s.result.pages} · ${s.result.cards.length}/${s.result.pages*s.result.pocketsPerPage} cards`;
    s.previous.disabled=!!s.turning||s.spread===0;s.next.disabled=!!s.turning||(s.spread+1)*2>=s.result.pages;
  }
  function renderGrading(){
    const s=state;s.content.replaceChildren();const panel=el('div',null,'collector-grading');s.content.append(panel);
    panel.append(el('span','HARDCORE COMICS','collector-eyebrow'),el('h2','Card grading'),el('p','Select one physical copy. The bench assesses its current condition and seals it in a certified Hardcore slab.','collector-intro'));
    if(s.selected){const card=s.selected.card;panel.append(art(card,true),el('h3',card.name),el('p',copySummary(card)));
      if(card.slab)panel.append(el('p','Already graded. This slab protects the card from further wear.'));
      else {const button=btn(panel,'Grade and seal this copy · Free test',async()=>{
        if(s.busy||s.failed)return;s.busy=true;button.disabled=true;note('Assessing and sealing this copy…');
        try{const result=await post('gradeCard',{context:s.selected.context,copyId:card.copyId,slot:card.slot});if(state!==s)return;await loadSource();const updated=s.sourceCards.find(c=>c.copyId===card.copyId||(card.slot!=null&&c.slot===card.slot));if(updated)s.selected={card:safeCard(updated),context:s.source};renderGrading();note(result.message||'Card graded.');}
        catch(error){if(state===s){s.failed=true;note(error.message+'. Close and reopen before retrying.');}}
        finally{if(state===s)s.busy=false;}
      });button.disabled=s.busy||s.failed;}
    }else panel.append(el('div','Choose a copy from the card tray.','collector-grading-placeholder'));
    panel.append(el('small','Temporary test bench · no Hardcore Comics job required · grading is free'));
  }
  function toggleLibrary(open){
    const s=state;if(!s?.binderView)return;
    s.libraryOpen=open;root.classList.toggle('binder-library-open',open);s.sidebar.classList.toggle('hidden',!open);s.addButton?.setAttribute('aria-expanded',String(open));
    if(open){loadSource();s.search.focus();}else s.addButton?.focus();
  }
  function binderView(s){
    s.binderView=true;s.libraryOpen=false;s.filters={search:'',cardType:'all',rarity:'all',sleeveStatus:'all',sort:'name-asc'};
    const workspace=el('div',null,'binder-workspace');root.append(workspace);s.content=el('main',null,'collector-content binder-canvas');workspace.append(s.content);
    const sidebar=el('aside',null,'collector-sidebar binder-library hidden');s.sidebar=sidebar;workspace.append(sidebar);sidebar.setAttribute('aria-label','Add cards to binder');
    const heading=el('div',null,'binder-library-heading');heading.append(el('h2','Add to binder'));const dismiss=btn(heading,'×',()=>toggleLibrary(false));dismiss.setAttribute('aria-label','Close card library');sidebar.append(heading);
    const source=el('select');source.setAttribute('aria-label','Card source');for(let i=0;i<s.result.sources.length;i++)source.append(new Option(s.result.sources[i].label,String(i)));sidebar.append(source);
    s.search=el('input');s.search.type='search';s.search.maxLength=80;s.search.placeholder='Search cards…';s.search.setAttribute('aria-label','Search cards');sidebar.append(s.search);
    const filters=el('div',null,'binder-library-filters');sidebar.append(filters);
    function select(label,options,key){const n=el('select');n.setAttribute('aria-label',label);for(const [value,text]of options)n.append(new Option(text,value));filters.append(n);n.addEventListener('change',()=>{s.filters[key]=n.value;loadSource();});return n;}
    s.typeSelect=select('Filter card type',[['all','All types']],'cardType');s.raritySelect=select('Filter rarity',[['all','All rarities']],'rarity');
    select('Filter sleeves',[['all','All sleeves'],['sleeved','Sleeved'],['unsleeved','Unsleeved']],'sleeveStatus');select('Sort cards',[['name-asc','Name A–Z'],['name-desc','Name Z–A'],['rarity','Rarity'],['number','Card number']],'sort');
    let searchTimer;s.search.addEventListener('input',()=>{clearTimeout(searchTimer);searchTimer=setTimeout(()=>{if(state!==s)return;s.filters.search=s.search.value.trim();loadSource();},180);});
    sidebar.addEventListener('dragover',event=>{if(s.selected?.context.location==='binder'&&['pocket','box'].includes(s.source.location))event.preventDefault();});sidebar.addEventListener('drop',event=>{if(event.target.closest('input,select'))return;event.preventDefault();returnCard(s.source.location,s.source.id);});
    source.addEventListener('change',()=>{if(s.busy)return;s.source=s.result.sources[Number(source.value)];s.selected=null;renderBook();loadSource();});
    s.libraryCount=el('p','Choose a card source.','binder-library-count');sidebar.append(s.libraryCount);s.tray=el('div',null,'collector-tray');sidebar.append(s.tray);sidebar.append(el('small','Drag a copy, or right-click it then choose an empty pocket.','binder-library-help'));
    s.status=el('p','', 'binder-floating-status');s.status.setAttribute('role','status');root.append(s.status);renderBook();
  }
  function open(mode,result){
    close(false);hideAll();currentDuelState=null;root.classList.remove('hidden');const s={mode,result,spread:0,selected:null,sourceCards:[],source:result.sources[0],sourcePage:0,sourcePages:1,busy:false,failed:false,loading:false};state=s;
    root.classList.toggle('collector-binder-mode',mode==='binder');root.classList.remove('binder-library-open','binder-has-selection');
    if(mode==='binder'){binderView(s);return;}
    const shell=el('div',null,'collector-shell');root.append(shell);const header=el('header');shell.append(header);const brand=el('div');brand.append(el('span','HARDCORE COLLECTIBLES','collector-eyebrow'),el('h1',mode==='binder'?'Collector Binder':'Grading Bench'));header.append(brand);btn(header,'Close',()=>close());
    const controls=el('div',null,'collector-controls');shell.append(controls);s.pageLabel=el('span');controls.append(s.pageLabel);
    if(mode==='binder'){s.previous=btn(controls,'‹ Previous spread',()=>turnPage(-1));s.next=btn(controls,'Next spread ›',()=>turnPage(1));btn(controls,'Clear selection',()=>{s.selected=null;renderTray();note('Selection cleared.');});}
    else s.pageLabel.textContent='Free test station · one physical copy at a time';
    const body=el('div',null,'collector-body');shell.append(body);s.content=el('main',null,'collector-content');body.append(s.content);
    const sidebar=el('aside',null,'collector-sidebar');sidebar.append(el('h2','Your cards'));const select=el('select');select.setAttribute('aria-label','Card source');
    const available=result.sources.filter(c=>mode!=='grading'||c.location==='pocket'||c.location==='box');s.source=available[0];for(let i=0;i<available.length;i++)select.append(new Option(available[i].label,String(i)));sidebar.append(select);
    select.addEventListener('change',()=>{if(s.busy)return;s.source=available[Number(select.value)];s.selected=null;s.sourceCards=[];loadSource();if(mode==='grading')renderGrading();});
    s.tray=el('div',null,'collector-tray');sidebar.append(s.tray);body.append(sidebar);s.status=el('p',null,'collector-status');s.status.setAttribute('role','status');shell.append(s.status);
    if(mode==='binder')renderBook();else renderGrading();loadSource();
  }
  window.addEventListener('message',({data})=>{if(data?.action==='openBinder'&&data.result?.ok)open('binder',data.result);if(data?.action==='openGrading'&&data.result?.ok)open('grading',data.result);if(['collectorClosed','forceCloseAll','hideCard','packPending','openDuelUi','openDeckBox','openDeckBuilder','sleeveClosed'].includes(data?.action))close(false);});
  window.addEventListener('keydown',event=>{if(!state||event.key!=='Escape')return;if(state.inspecting||document.querySelector('.sleeve-context:not(.hidden)'))return;if(state.inspection){state.inspection.remove();state.inspection=null;}else if(state.binderView&&state.selected)clearSelection();else if(state.binderView&&state.libraryOpen)toggleLibrary(false);else close();event.preventDefault();event.stopImmediatePropagation();},true);
  root.addEventListener('click',event=>{if(state?.binderView&&state.selected&&!state.busy&&!event.target.closest('.collector-book,.collector-source-card'))clearSelection();});
  window.BStarCollectors={open,close,returnFromInspection,refresh:()=>state?.mode==='binder'?refreshBinder():loadSource()};
})();
