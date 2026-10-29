// Shared sleeve treatment; artwork and rarity renderers retain ownership of images.
(() => {
  const fallback='images/assets/card_back_default.png';
  let types={},designs={},catalogueLoading=false;const bindings=new Map();
  const hidden=card=>card?.hidden||card?.faceDown||card?.facedown||card?.faceUp===false;
  const back=card=>designs[card?.deckSleeveId]?.back||fallback;
  const tooltip=document.createElement('div');tooltip.className='bstar-card-tooltip hidden';tooltip.setAttribute('role','tooltip');document.body.appendChild(tooltip);
  function show(event){
    const card=bindings.get(event.target)?.card;if(!card)return;
    tooltip.replaceChildren();
    if(hidden(card)){tooltip.classList.add('hidden');return;}
    const variants=!hidden(card)&&card.variants?.length?card.variants:[card];
    for(const variant of variants){
      const label=document.createElement('div');label.textContent=(variants.length>1?variant.amount+' × ':'')+(variant.slab?'Graded slab · Grade '+(variant.slab.label||variant.slab.grade):(variant.sleeveId?'Protected':'Unprotected'));tooltip.appendChild(label);
      if(!hidden(card)&&['Good','Played','Damaged'].includes(variant.conditionCategory)){const condition=document.createElement('div');condition.dataset.condition=variant.conditionCategory;condition.textContent=variant.conditionCategory;tooltip.appendChild(condition);}
    }
    tooltip.classList.remove('hidden');tooltip.style.left=Math.max(4,Math.min(event.clientX+14,innerWidth-tooltip.offsetWidth-8))+'px';tooltip.style.top=Math.max(4,Math.min(event.clientY+14,innerHeight-tooltip.offsetHeight-8))+'px';
  }
  function layout(image){
    const binding=bindings.get(image);if(!binding)return;
    const parent=image.parentElement;if(!parent)return;
    binding.edge?.remove();binding.edge=null;image.classList.remove('bstar-sleeved-art');
    if(hidden(binding.card)){
      const selected=back(binding.card),path=binding.failedBack===selected?fallback:selected;
      if(image.getAttribute('src')!==path)image.src=path;
    }

  }
  const resize=new ResizeObserver(entries=>{for(const entry of entries)layout(entry.target);});
  function bind(image,card){
    if(!image)return;let binding=bindings.get(image);
    if(!binding){binding={};bindings.set(image,binding);resize.observe(image);image.addEventListener('load',()=>layout(image));image.addEventListener('pointermove',show);image.addEventListener('pointerleave',()=>tooltip.classList.add('hidden'));image.addEventListener('error',()=>{const b=bindings.get(image);if(hidden(b?.card)&&image.getAttribute('src')!==fallback){b.failedBack=image.getAttribute('src');image.src=fallback;}});}
    if(card?.variants?.length===1)card={...card,...card.variants[0]};
    else if(card?.variants?.length>1)card={...card,sleeveId:undefined,conditionCategory:undefined};
    binding.card=card||{};layout(image);requestAnimationFrame(()=>layout(image));
  }
  // Detach observers for removed stack/grid images; retain live nodes across reveals.
  let cleanupPending=false;
  new MutationObserver(()=>{if(cleanupPending)return;cleanupPending=true;requestAnimationFrame(()=>{cleanupPending=false;for(const [image,binding]of bindings)if(!image.isConnected){resize.unobserve(image);binding.edge?.remove();bindings.delete(image);}});}).observe(document.body,{childList:true,subtree:true});
  async function load(){
    if(catalogueLoading)return;catalogueLoading=true;
    const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),15000);
    try{const response=await fetch(`https://${GetParentResourceName()}/sleeveCatalog`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}',signal:controller.signal});if(!response.ok)throw Error('Catalogue unavailable');const result=await response.json();if(result.ok){types=result.types||{};designs=result.designs||{};for(const image of bindings.keys())layout(image);}}
    catch(error){console.warn('[BStar sleeves] Catalogue unavailable; using default appearance.');}
    finally{clearTimeout(timer);catalogueLoading=false;}
  }
  window.BStarSleeveVisuals={bind,back,hidden,get types(){return types;},get designs(){return designs;}};
  load();window.addEventListener('message',({data})=>{
    // Re-fetch on a new builder/duel session: a successful earlier stock request
    // must not keep an outdated design catalogue for the rest of the NUI session.
    if(['openDeckBuilder','openDuelUi'].includes(data?.action)||(['showCard','bulkOpen','openDeckBox','packOpen'].includes(data?.action)&&(!Object.keys(types).length||!Object.keys(designs).length)))load();
    tooltip.classList.add('hidden');
  });
})();
