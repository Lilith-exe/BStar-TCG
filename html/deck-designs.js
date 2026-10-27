// A saved deck chooses one back. This never changes physical card metadata.
(() => {
  const select=document.getElementById('deckSleeveDesign');let designs={};
  const preview=document.createElement('img');preview.className='deck-sleeve-swatch';preview.alt='Deck back preview';
  select.after(preview);
  function showPreview(){
    preview.src=designs[select.value]?.back||'images/assets/card_back_default.png';
    preview.alt=`${designs[select.value]?.label||'BStar Classic'} deck back`;
    preview.onerror=()=>{preview.onerror=null;preview.src='images/assets/card_back_default.png';};
  }
  function refresh(){
    const id=selectedDeck?.deck_data?.sleeveDesign||'default';
    select.replaceChildren();
    for(const [key,d] of Object.entries(designs).sort((a,b)=>a[1].label.localeCompare(b[1].label))){
      if(d.unlocked)select.append(new Option(d.label,key));
    }
    if(!select.options.length)select.append(new Option('BStar Classic','default'));
    select.value=[...select.options].some(o=>o.value===id)?id:'default';
    select.disabled=!selectedDeck;showPreview();
  }
  select.addEventListener('change',()=>{if(selectedDeck){normalizeDeck(selectedDeck);selectedDeck.deck_data.sleeveDesign=select.value;showPreview();}});
  async function load(){
    try{const res=await fetch(`https://${GetParentResourceName()}/sleeveCatalog`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
      const data=await res.json();if(data.ok){designs=data.designs||{};refresh();}
    }catch(error){console.warn('[BStar] Deck backs unavailable:',error);}
  }
  window.BStarDeckDesigns={refresh};
  window.addEventListener('message',({data})=>{if(['openDeckBuilder','openTableDeckSelect'].includes(data?.action))load();});
  load();
})();
