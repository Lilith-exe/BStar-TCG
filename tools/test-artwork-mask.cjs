const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {once}=require('node:events');const {chromium}=require('playwright');
const {server,catalog}=require('./rarity-test-server.cjs');
const out=path.resolve(__dirname,'../.git/artwork-mask-1133');
(async()=>{
 if(!server.listening)await once(server,'listening');
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 try{
  const page=await browser.newPage({viewport:{width:1440,height:1000},reducedMotion:'reduce'});
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto('http://127.0.0.1:'+server.address().port);await page.waitForFunction(()=>window.rarityTest.ready);
  const reference=fs.readFileSync(path.join(out,'mask-reference.js'),'utf8');
  await page.evaluate(code=>document.getElementById('nui').contentWindow.eval(code),reference);
  const cases=['ALPH1-EN001_LAYLA_HART.png','ALPH1-EN002_MR_BSTAR.png','ALPH1-EN005_XENA_COUGAR_MIRANOVA.png','ALPH1-EN013_TOLL_BOOTH.png','ALPH1-EN041_AMNESTY.png','ALPH1-EN104_COMBAT_PDW.png'];
  for(const name of cases){
   const card=catalog().find(c=>c.inventoryImage===name);assert(card);
   await page.evaluate(c=>document.getElementById('nui').contentWindow.rarityFixture.show(c),card);
   await page.waitForFunction(()=>document.getElementById('nui').contentWindow.BStarFoil.getSettings().regionalCoverage);
   const result=await page.evaluate(async name=>{
    const w=document.getElementById('nui').contentWindow,p=w.BSTAR_FOIL_SAMPLES.settings.artworkPolygon;
    const source='images/cards/'+name;
    const a=await w.BStarArtworkMasks.build(source,p,.11,.33,'DARK');
    const b=await w.BStarMaskPreview.build(source,p,.11,'brightness',.33);
    const pixels=async url=>{const im=new w.Image();im.src=url;await im.decode();const c=w.document.createElement('canvas');c.width=a.width;c.height=a.height;const x=c.getContext('2d');x.drawImage(im,0,0);return x.getImageData(0,0,c.width,c.height).data;};
    const actual=await pixels(a.artwork),expected=await pixels(b.DARK),combined=await pixels(a.regional);
    const c=w.document.createElement('canvas');c.width=a.width;c.height=a.height;const x=c.getContext('2d',{willReadFrequently:true});x.beginPath();p.forEach(([u,v],i)=>x[i?'lineTo':'moveTo'](u*c.width,v*c.height));x.closePath();x.fillStyle='white';x.fill();const region=x.getImageData(0,0,c.width,c.height).data;
    let mismatches=0,boundaryErrors=0,exteriorErrors=0,darkPixels=0,clearPixels=0;
    for(let i=3;i<actual.length;i+=4){if(actual[i]!==expected[i])mismatches++;if(combined[i]!==255-region[i]+actual[i])boundaryErrors++;if(!region[i]&&combined[i]!==255)exteriorErrors++;if(region[i]===255){if(actual[i]>180)darkPixels++;if(actual[i]===0)clearPixels++;}}
    return {mismatches,boundaryErrors,exteriorErrors,darkPixels,clearPixels,settings:w.BStarFoil.getSettings()};
   },name);
   assert.equal(result.mismatches,0);assert.equal(result.boundaryErrors,0);assert.equal(result.exteriorErrors,0);assert(result.clearPixels>0);
   assert.equal(result.settings.intensity,1);assert.equal(result.settings.mode,'DARK');assert.equal(result.settings.threshold,.11);assert.equal(result.settings.feather,.33);
   console.log('PASS exact Lab alpha/complement/exterior:',name,'dark',result.darkPixels,'clear',result.clearPixels);
  }
  // Rendering check: no shader component may paint pixels fully suppressed by DARK.
  for(const rarity of ['SUPER','ULTRA','SECRET']){
    const card=catalog().find(c=>c.rarity===rarity);
    await page.evaluate(c=>{const w=document.getElementById('nui').contentWindow;w.BStarFoil.configure({mode:null,intensity:null,enabled:true});w.rarityFixture.show(c);w.rarityFixture.tilt(0,0);},card);
    await page.waitForFunction(()=>document.getElementById('nui').contentWindow.BStarFoil.getSettings().regionalCoverage);
    await page.waitForTimeout(350);
    const surface=page.frameLocator('#nui').locator('#cardSurface');
    const on=await surface.screenshot();
    const mask=await page.evaluate(()=>document.getElementById('nui').contentWindow.document.getElementById('cardFoil').style.getPropertyValue('--foil-mask').slice(5,-2));
    const fields=await page.evaluate(()=>{const w=document.getElementById('nui').contentWindow,d=w.document;return {intensity:Number(d.getElementById('cardSurface').style.getPropertyValue('--foil-intensity')),border:Number(w.getComputedStyle(d.querySelector('.rarity-border')).getPropertyValue('--foil-intensity')),fullMask:w.getComputedStyle(d.querySelector('.rarity-full')).maskImage,starsMask:w.getComputedStyle(d.querySelector('.rarity-starlight')).maskImage};});
    assert.equal(fields.intensity,1);if(rarity==='SUPER')assert.equal(fields.border,.55);else{assert.match(fields.fullMask,/data:image/);if(rarity==='SECRET')assert.equal(fields.fullMask,fields.starsMask);}
    await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarFoil.configure({enabled:false}));
    const off=await surface.screenshot();
    const diff=await page.evaluate(async({a,b,mask,rarity})=>{
      const w=document.getElementById('nui').contentWindow;
      const load=async src=>{const im=new w.Image();im.src=src;await im.decode();const c=w.document.createElement('canvas');c.width=im.naturalWidth;c.height=im.naturalHeight;const x=c.getContext('2d',{willReadFrequently:true});x.drawImage(im,0,0);return {data:x.getImageData(0,0,c.width,c.height).data,width:c.width,height:c.height};};
      const x=await load(a),y=await load(b),m=await load(mask);let checked=0,changed=0,outsideChanged=0;
      for(let v=0;v<x.height;v++)for(let u=0;u<x.width;u++){
        const px=Math.floor(u*m.width/x.width),py=Math.floor(v*m.height/x.height);let zero=true;
        for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++){const xx=px+dx,yy=py+dy;if(xx<0||yy<0||xx>=m.width||yy>=m.height||m.data[(yy*m.width+xx)*4+3])zero=false;}
        const i=(v*x.width+u)*4;const different=x.data[i]!==y.data[i]||x.data[i+1]!==y.data[i+1]||x.data[i+2]!==y.data[i+2];
        if(zero&&u/x.width>.15&&u/x.width<.85&&v/x.height>.20&&v/x.height<.60){checked++;if(different)changed++;}
        if(different&&v/x.height>.75&&v/x.height<.89&&u/x.width>.25&&u/x.width<.70)outsideChanged++;
      }
      return {checked,changed,outsideChanged};
    },{a:'data:image/png;base64,'+on.toString('base64'),b:'data:image/png;base64,'+off.toString('base64'),mask,rarity});
    assert(diff.checked>100);assert.equal(diff.changed,0,'No foil bypass in suppressed '+rarity+' artwork');if(rarity==='SUPER')assert.equal(diff.outsideChanged,0,'No Super rainbow in effect box');else assert(diff.outsideChanged>0,'Full exterior finish '+rarity);
    console.log('PASS all-layer exclusion/exterior/intensity:',rarity,diff);
  }
  const unchanged=['COMMON','RARE']; // Ghost is intentionally refined in the next optical pass.
  for(const rarity of unchanged){
   const card=catalog().find(c=>c.rarity===rarity);
   await page.evaluate(o=>window.rarityTest.set(o),{card:card.id,mode:'FULL',x:-5,y:5,intensity:.55});await page.waitForTimeout(450);
   const png=await page.frameLocator('#nui').locator('#cardSurface').screenshot({path:path.join(out,rarity.toLowerCase()+'.png')});
   assert(png.equals(fs.readFileSync(path.resolve(__dirname,'../.git/rarity-pass3/after',rarity.toLowerCase()+'.png'))),'Unchanged '+rarity);
   console.log('PASS unchanged captured appearance:',rarity);
  }
  const card=catalog().find(c=>c.inventoryImage===cases[0]);
  await page.evaluate(o=>window.rarityTest.set(o),{card:card.id,mode:'DARK',x:-5,y:5});await page.waitForFunction(()=>document.getElementById('nui').contentWindow.BStarFoil.getSettings().regionalCoverage);
  const before=await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarArtworkMasks.getStats());
  await page.evaluate(()=>{const w=document.getElementById('nui').contentWindow;for(let i=0;i<100;i++)w.BStarFoil.updateTilt(i/20,3-i/20);});
  assert.deepEqual(await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarArtworkMasks.getStats()),before);
  await page.frameLocator('#nui').locator('#cardSurface').screenshot({path:path.join(out,'secret-dark-1133.png')});
  await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarFoil.configure({maskSource:'cached',mode:'DARK'}));
  await page.waitForFunction(()=>document.getElementById('nui').contentWindow.BStarFoil.getSettings().regionalCoverage);
  await page.frameLocator('#nui').locator('#cardImage').click();assert(await page.frameLocator('#nui').locator('#cardImage').evaluate(e=>e.classList.contains('zoomed')));
  await page.frameLocator('#nui').locator('#closeBtn').click();assert(await page.frameLocator('#nui').locator('#viewerWrap').evaluate(e=>e.classList.contains('hidden')));
  assert.deepEqual(errors,[]);console.log('PASS cached-mask compatibility, unchanged analysis count on tilt, zoom/close, no JS errors');
 }finally{await browser.close();server.close();}
})().catch(e=>{console.error(e);process.exitCode=1;server.close();});
