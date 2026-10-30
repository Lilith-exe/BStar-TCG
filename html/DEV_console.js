// Development-only console. All mutations use explicit, server-validated actions.
(() => {
  const el=(tag,text,cls)=>{const n=document.createElement(tag);if(text!=null)n.textContent=text;if(cls)n.className=cls;return n;};
  const root=el('div',null,'DEV-console-overlay');root.hidden=true;
  const panel=el('section',null,'DEV-console');panel.setAttribute('role','dialog');panel.setAttribute('aria-label','BStar developer console');
  const header=el('header');const title=el('div');title.append(el('strong','B★STAR'),el('span','Developer Console · v1'));header.append(title);
  const closeButton=el('button','×','DEV-close');closeButton.type='button';closeButton.setAttribute('aria-label','Close developer console');header.append(closeButton);
  const tabs=el('nav',null,'DEV-tabs');tabs.setAttribute('aria-label','Developer tools');
  const toolbar=el('div',null,'DEV-toolbar');const search=el('input');search.type='search';search.placeholder='Search names or IDs…';search.setAttribute('aria-label','Search developer catalogue');
  const filter=el('select');filter.setAttribute('aria-label','Filter catalogue');const refresh=el('button','Refresh');refresh.type='button';toolbar.append(search,filter,refresh);
  const body=el('main',null,'DEV-body');const confirm=el('div',null,'DEV-confirm');confirm.hidden=true;confirm.setAttribute('role','alertdialog');confirm.setAttribute('aria-label','Confirm catalogue generation');
  const log=el('div',null,'DEV-log');log.setAttribute('role','log');log.setAttribute('aria-live','polite');
  const foot=el('footer','Development tools · actions can permanently change your collection.');panel.append(header,tabs,toolbar,body,confirm,log,foot);root.append(panel);document.body.append(root);
  let opened=false,busy=false,data=null,tab='Items',cardId='',boxId='',pending=null;
  const quantities=[1,5,10];
  let cardQuantity=1,actionSequence=0;
  const itemQuantities=new Map();
  const previewLimit=6,previewCards=new Map(),previewVisible=new Set(),previewControllers=new Map();
  let previewObserver=null;
  function stopPreviews(){
    previewObserver?.disconnect();previewObserver=null;
    for(const controller of previewControllers.values())controller.destroy();
    previewControllers.clear();previewVisible.clear();previewCards.clear();
  }
  function syncPreviews(){
    if(!opened||busy||tab!=='Cards')return;
    for(const [image,controller] of previewControllers){
      if(!previewVisible.has(image)||!image.isConnected){controller.destroy();previewControllers.delete(image);}
    }
    for(const image of previewVisible){
      if(previewControllers.size>=previewLimit)break;
      if(previewControllers.has(image)||!image.isConnected)continue;
      const card=previewCards.get(image);if(!card)continue;
      const controller=window.BStarRarityRenderer?.attach(image,{...card,cardId:card.id,inventoryImage:card.image});
      if(controller)previewControllers.set(image,controller);
    }
  }
  function startPreviews(){
    if(!opened||busy||tab!=='Cards'||!previewCards.size)return;
    previewObserver=new IntersectionObserver(entries=>{
      for(const entry of entries){if(entry.isIntersecting)previewVisible.add(entry.target);else previewVisible.delete(entry.target);}
      syncPreviews();
    },{root:body,threshold:.1});
    for(const image of previewCards.keys())previewObserver.observe(image);
  }

  const button=(parent,label,fn,cls)=>{const b=el('button',label,cls);b.type='button';b.disabled=busy;b.addEventListener('click',fn);parent.append(b);return b;};
  function output(text,ok=true){const line=el('div',`${new Date().toLocaleTimeString('en-GB')}  ${text}`,ok?'DEV-ok':'DEV-error');log.prepend(line);while(log.children.length>40)log.lastChild.remove();}
  async function post(name,value={}){
    const abort=new AbortController();const timer=setTimeout(()=>abort.abort(),30000);
    try{const response=await fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(value),signal:abort.signal});if(!response.ok)throw Error('Connection failed');return await response.json();}
    finally{clearTimeout(timer);}
  }
  function summary(result){
    if(result.generated!=null)return `${result.generated} generated · ${result.skipped||0} skipped · ${result.failed||0} failed · ${result.unconfirmed||0} unconfirmed${result.box?' · Box '+result.box:''}${result.cardId?' · '+result.cardId:''}${result.batchId?' · Batch '+result.batchId:''}${result.error?' · '+result.error:''}`;
    return (result.unconfirmed?'Outcome unconfirmed · ':'')+(result.cached?'Saved result · ':'')+(result.message||result.error||(result.ok?'Action completed.':'Action failed.'))+(result.id?' · '+result.id:'');
  }
  function accept(result){
    if(!result?.ok){output(result?.error||'Catalogue unavailable.',false);return;}
    data=result;if(!data.cards.some(c=>c.id===cardId))cardId=data.cards[0]?.id||'';
    if(!data.boxes.some(b=>b.id===boxId))boxId=data.boxes[0]?.id||'';
    updateFilters();render();
  }
  async function reload(){if(busy)return;busy=true;render();try{accept(await post('DEV_consoleData'));}catch(e){output(e.message,false);}finally{busy=false;render();}}
  async function act(request){
    if(busy)return;request={...request,requestId:Date.now().toString(36)+'-'+(++actionSequence).toString(36)+'-'+Math.random().toString(36).slice(2,10)};busy=true;pending=null;render();
    try{const result=await post('DEV_consoleAction',request);output(summary(result),result.ok===true);if(result.ok){
      if(result.box&&typeof currentDeckBoxId!=='undefined'&&currentDeckBoxId===result.box){
        if(!document.getElementById('deckBuilderWrap')?.classList.contains('hidden')&&typeof refreshDeckBuilder==='function')refreshDeckBuilder();
        else if(!document.getElementById('deckboxWrap')?.classList.contains('hidden')&&typeof refreshDeckBox==='function')refreshDeckBox();
      }
      if(request.action==='item'&&request.item==='deck_box'&&result.id)boxId=result.id;try{accept(await post('DEV_consoleData'));}catch(e){output('Action completed; refresh failed. '+e.message,false);}}}
    catch(e){output('Response unconfirmed. Check your inventory/box before retrying. '+e.message,false);}
    finally{busy=false;render();}
  }
  function select(options,value,change,label){const s=el('select');s.setAttribute('aria-label',label);s.disabled=busy;for(const o of options){const op=el('option',o.label??String(o));op.value=o.id??String(o);s.append(op);}s.value=value;s.addEventListener('change',()=>change(s.value));return s;}
  function destination(parent){
    const row=el('div',null,'DEV-row');row.append(el('span','Destination'));
    const boxes=data.boxes.length?data.boxes:[{id:'',label:'Grant a Deck Box first'}];row.append(select(boxes,boxId,v=>{boxId=v;render();},'Destination Deck Box'));parent.append(row);
  }
  const matches=v=>String(v||'').toLowerCase().includes(search.value.trim().toLowerCase());
  function updateFilters(){
    const old=filter.value;filter.replaceChildren(el('option','All categories'));
    filter.firstChild.value='';let values=[];
    if(data)values=tab==='Items'?[...data.items.map(i=>i.category),'Deck cosmetics']:data.cards.map(c=>c.rarity);
    for(const v of [...new Set(values)].sort()){const op=el('option',v);op.value=v;filter.append(op);}filter.value=[...filter.options].some(o=>o.value===old)?old:'';
  }
  function render(){
    const scroll=body.scrollTop;stopPreviews();body.replaceChildren();confirm.replaceChildren();confirm.hidden=!pending;
    refresh.disabled=busy;search.disabled=busy;filter.disabled=busy;
    for(const b of tabs.children){b.classList.toggle('DEV-selected',b.textContent===tab);b.disabled=busy;b.setAttribute('aria-current',b.textContent===tab?'page':'false');}
    toolbar.hidden=tab==='Decks';if(!data){body.append(el('p','Loading developer catalogue…'));return;}
    if(tab==='Items'){
      const grid=el('div',null,'DEV-items');
      for(const item of data.items.filter(i=>(matches(i.label)||matches(i.id))&&(!filter.value||i.category===filter.value))){
        const tile=el('article',null,'DEV-item');const text=el('div');text.append(el('strong',item.label),el('small',item.id),el('small',item.category));
        const quantity=itemQuantities.get(item.id)||1;const controls=el('div',null,'DEV-row');controls.append(select(item.quantities,String(quantity),v=>itemQuantities.set(item.id,Number(v)),'Quantity for '+item.label));button(controls,'Grant',()=>act({action:'item',item:item.id,quantity:itemQuantities.get(item.id)||1}));tile.append(text,controls);grid.append(tile);
      }
      if(!filter.value||filter.value==='Deck cosmetics')for(const design of Object.values(data.designs).filter(d=>matches(d.label)||matches(d.id))){
        const tile=el('article',null,'DEV-item');const text=el('div');text.append(el('strong',design.label),el('small','Deck cosmetic · permanent unlock'));
        tile.append(text);const b=button(tile,design.unlocked?'Unlocked':'Unlock',()=>act({action:'design',design:design.id}));b.disabled=busy||design.unlocked;grid.append(tile);
      }
      body.append(grid);if(!grid.children.length)body.append(el('p','No matching items.'));
    }else if(tab==='Cards'){
      body.append(el('p','Create physical copies in an empty carried Deck Box. Effects preview on up to six visible cards.','DEV-note'));destination(body);
      const action=el('div',null,'DEV-row');action.append(select(quantities,String(cardQuantity),v=>cardQuantity=Number(v),'Number of physical copies'));const chosen=data.cards.find(c=>c.id===cardId);
      action.append(el('span',chosen?.name||'Select a card'));const make=button(action,'Create copies',()=>act({action:'cards',cardId,quantity:cardQuantity,box:boxId}));make.disabled=busy||!cardId||!boxId;body.append(action);
      const grid=el('div',null,'DEV-cards');
      for(const card of data.cards.filter(c=>(matches(c.id)||matches(c.name))&&(!filter.value||c.rarity===filter.value))){
        const tile=el('button',null,'DEV-card'+(card.id===cardId?' DEV-selected':''));tile.type='button';tile.disabled=busy;const img=el('img');img.loading='lazy';img.alt=card.name;
        const file=String(card.image).split(/[\\/]/).pop();img.src='images/thumbs/'+file;
        img.onerror=()=>{img.onerror=null;img.src='images/cards/'+file;};
        const well=el('div',null,'DEV-card-art');well.dataset.bstarFoilManaged='true';well.append(img);
        tile.append(well,el('strong',card.name),el('small',card.id),el('small',card.rarity));
        if(['RARE','SUPER','ULTRA','SECRET','GHOST'].includes(String(card.rarity).toUpperCase().replace(/ RARE$/,'')))previewCards.set(img,card);tile.addEventListener('click',()=>{cardId=card.id;render();});grid.append(tile);
      }
      body.append(grid);if(!grid.children.length)body.append(el('p','No matching cards.'));
    }else if(tab==='Decks'){
      body.append(el('h3','Deck Box tools'));button(body,'Grant Deck Box',()=>act({action:'item',item:'deck_box',quantity:1}));destination(body);
      body.append(el('p',`Full catalogue: ${data.fillCount} independent copies · three per eligible card. ${data.skipped} potential copies excluded.`, 'DEV-note'));
      const fill=button(body,'Fill selected empty box',()=>{pending={box:boxId,count:data.fillCount};render();});fill.disabled=busy||!boxId;
    }else{
      body.append(el('h3','Duel testing'));
      const fighters=data.cards.filter(c=>String(c.type).toLowerCase()==='fighter'&&(matches(c.id)||matches(c.name))&&(!filter.value||c.rarity===filter.value));
      let fighter=fighters[0]?.id||'',zone=1,side=1;const row=el('div',null,'DEV-row');row.append(select(fighters.map(c=>({id:c.id,label:c.name})),fighter,v=>fighter=v,'Debug fighter'));
      row.append(select([{id:1,label:'Side 1'},{id:2,label:'Side 2'}],'1',v=>side=Number(v),'Duel side'));row.append(select([{id:1,label:'Zone 1'},{id:2,label:'Zone 2'},{id:3,label:'Zone 3'}],'1',v=>zone=Number(v),'Fighter zone'));body.append(row);
      const spawn=button(body,'Spawn fighter in current duel',()=>act({action:'fighter',cardId:fighter,side,zone}));spawn.disabled=busy||!fighter;
      body.append(el('h3','Collector tools'));button(body,'Grant test binder',()=>act({action:'item',item:data.binderItem,quantity:1}));
      body.append(el('p','Binder design unlocks are not configured in this version.','DEV-note'));
      body.append(el('h3','Permanent deck cosmetics'));const designs=el('div',null,'DEV-row');for(const d of Object.values(data.designs)){const b=button(designs,d.unlocked?d.label+' · unlocked':'Unlock '+d.label,()=>act({action:'design',design:d.id}));b.disabled=busy||d.unlocked;}body.append(designs);
    }
    if(pending){confirm.append(el('strong',`Generate ${pending.count} physical cards?`),el('p','The selected box must be empty. This creates permanent copies.'));
      button(confirm,'Confirm generation',()=>act({action:'fill',box:pending.box,confirm:true,expected:pending.count}),'DEV-primary');button(confirm,'Cancel',()=>{pending=null;render();});}
    body.scrollTop=scroll;startPreviews();
  }
  for(const name of ['Items','Cards','Decks','Debug'])button(tabs,name,()=>{tab=name;pending=null;filter.value='';body.scrollTop=0;updateFilters();render();});
  search.addEventListener('input',()=>{body.scrollTop=0;render();});filter.addEventListener('change',()=>{body.scrollTop=0;render();});refresh.addEventListener('click',reload);
  function close(){if(!opened)return;opened=false;root.hidden=true;pending=null;stopPreviews();post('DEV_consoleClose').catch(()=>{});}
  closeButton.addEventListener('click',close);
  window.addEventListener('keydown',event=>{if(!opened||event.key!=='Escape')return;event.preventDefault();event.stopImmediatePropagation();if(pending){pending=null;render();}else close();},true);
  window.addEventListener('message',({data:message})=>{
    if(message.action==='DEV_consoleOpen'){opened=true;root.hidden=false;render();search.focus();}
    if(message.action==='DEV_consoleClose'){opened=false;root.hidden=true;pending=null;stopPreviews();}
    if(message.action==='DEV_consoleData'&&opened)accept(message.result);
  });
  let drag=null;
  header.addEventListener('pointerdown',event=>{if(event.button!==0||event.target.closest('button'))return;const rect=panel.getBoundingClientRect();drag={id:event.pointerId,x:event.clientX-rect.left,y:event.clientY-rect.top};header.setPointerCapture(event.pointerId);});
  header.addEventListener('pointermove',event=>{if(!drag||event.pointerId!==drag.id)return;panel.style.right='auto';panel.style.left=Math.max(8,Math.min(innerWidth-panel.offsetWidth-8,event.clientX-drag.x))+'px';panel.style.top=Math.max(8,Math.min(innerHeight-panel.offsetHeight-8,event.clientY-drag.y))+'px';});
  const endDrag=()=>drag=null;header.addEventListener('pointerup',endDrag);header.addEventListener('pointercancel',endDrag);header.addEventListener('lostpointercapture',endDrag);
  window.addEventListener('resize',()=>{const rect=panel.getBoundingClientRect();if(panel.style.left)panel.style.left=Math.max(8,Math.min(innerWidth-panel.offsetWidth-8,rect.left))+'px';panel.style.top=Math.max(8,Math.min(innerHeight-panel.offsetHeight-8,rect.top))+'px';});
})();
