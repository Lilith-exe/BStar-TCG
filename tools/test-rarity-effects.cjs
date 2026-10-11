// Production rarity checks in a minimal read-only fixture; independent of the evolving Lab.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const { chromium } = require('playwright');
process.env.BSTAR_LAB_PORT = '0';
const { server, catalog } = require(process.env.BSTAR_RARITY_LAB_SERVER || './rarity-test-server.cjs');
const output = path.resolve(process.env.BSTAR_RARITY_OUTPUT || path.join(__dirname, '../.git/rarity-pass2/screenshots'));
const executable = process.env.BSTAR_LAB_BROWSER || ['C:/Program Files/Google/Chrome/Application/chrome.exe','C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'].find(fs.existsSync);
let browser;
(async () => {
  if (!server.listening) await once(server,'listening');
  fs.mkdirSync(output,{recursive:true});
  browser = await chromium.launch({ executablePath: executable, headless:true });
  const page = await browser.newPage({viewport:{width:1440,height:1000},reducedMotion:'reduce'});
  const errors=[];
  page.on('pageerror',error=>errors.push(error.message));
  await page.goto('http://127.0.0.1:'+server.address().port);
  await page.waitForFunction(()=>window.rarityTest.ready===true);
  const all = catalog();
  const state = () => page.evaluate(()=>{
    const w=document.getElementById('nui').contentWindow,d=w.document;
    const visible=selector=>w.getComputedStyle(d.querySelector(selector)).display!=='none';
    return {settings:w.BStarFoil.getSettings(),border:visible('.rarity-border'),art:visible('#cardFoil'),full:visible('.rarity-full'),stars:visible('.rarity-starlight'),ghost:visible('.rarity-ghost-art'),glow:w.getComputedStyle(d.getElementById('cardSurface')).boxShadow,transform:d.getElementById('cardSurface').style.transform,ghostOpacity:Number(w.getComputedStyle(d.querySelector('.rarity-ghost-art')).opacity),mask:d.getElementById('cardFoil').style.getPropertyValue('--foil-mask')};
  });
  const set = async(card,mode='FULL',x=-5,y=5)=>{
    await page.evaluate(options=>window.rarityTest.set(options),{card:card.id,mode,pointer:false,freeze:true,intensity:0.55,x,y,rendering:'production',maskSource:'production'});
    await page.waitForTimeout(450);
  };
  const surface=page.frameLocator('#nui').locator('#cardSurface');
  const reports=[];
  for(const rarity of ['COMMON','RARE','SUPER','ULTRA','SECRET','GHOST']){
    const card=all.find(c=>c.rarity===rarity);assert(card,'real '+rarity+' sample exists');
    await set(card);const s=await state();
    assert.equal(s.settings.effectiveRarity,rarity);
    assert.equal(s.border,rarity!=='COMMON');
    assert.equal(s.art,!['COMMON','RARE'].includes(rarity));
    assert.equal(s.full,['ULTRA','SECRET','GHOST'].includes(rarity));
    assert.equal(s.stars,rarity==='SECRET');assert.equal(s.ghost,rarity==='GHOST');
    assert.equal(s.glow!=='none',rarity==='GHOST');
    const on=await surface.screenshot({path:path.join(output,rarity.toLowerCase()+'.png')});
    await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarFoil.configure({enabled:false}));
    const off=await surface.screenshot({path:path.join(output,rarity.toLowerCase()+'-off.png')});
    assert.equal(on.equals(off),rarity==='COMMON','Common must be pixel-identical; other finishes must render visible pixels');
    reports.push({rarity,card:card.id,...s});
  }
  if(process.env.BSTAR_RARITY_BASELINE){
    for(const rarity of ['common','rare','super','ultra']){
      assert(fs.readFileSync(path.join(output,rarity+'.png')).equals(fs.readFileSync(path.join(process.env.BSTAR_RARITY_BASELINE,rarity+'.png'))),'Pass 2 appearance unchanged: '+rarity);
    }
  }
  const sample=all.find(c=>c.inventoryImage==='ALPH1-EN001_LAYLA_HART.png');
  if(process.env.BSTAR_RARITY_PASS3==='1'){
    await set(sample,'FULL',0,0);
    const detail=()=>page.evaluate(()=>{
      const w=document.getElementById('nui').contentWindow,d=w.document,el=d.querySelector('.rarity-starlight');
      const a=w.getComputedStyle(el,'::before'),b=w.getComputedStyle(el,'::after');
      return {grain:[a.maskImage,a.maskPosition,a.maskSize,a.transform,a.animationName],glints:[b.maskImage,b.maskPosition,b.maskSize,b.transform,b.animationName],light:a.backgroundPosition};
    });
    const anchored=await detail();
    assert(anchored.grain[0].includes('secret-grain.png')&&anchored.glints[0].includes('secret-glints.png'));
    const variants=[['neutral',0,0],['left',-4,-6],['right',4,6]];
    for(const [label,x,y] of variants){
      await set(sample,'FULL',x,y);const pose=await detail();
      assert.deepEqual(pose.grain,anchored.grain,'grain geometry fixed at '+label);
      assert.deepEqual(pose.glints,anchored.glints,'glint geometry fixed at '+label);
      assert.equal(pose.grain[3],'none');assert.equal(pose.grain[4],'none');
      if(label!=='neutral')assert.notEqual(pose.light,anchored.light,'only reflected light moves');
      await surface.screenshot({path:path.join(output,'secret-'+label+'.png')});
    }
    await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarFoil.configure({rarity:'GHOST'}));
    for(const [label,x,y] of variants){
      await set(sample,'FULL',x,y);
      await page.waitForFunction(()=>document.getElementById('nui').contentWindow.BStarSpectralEdges.getStats().analyses>0);
      await surface.screenshot({path:path.join(output,'ghost-colour-'+label+'.png')});
    }
    const stats=await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarSpectralEdges.getStats());
    await page.evaluate(()=>{
      const w=document.getElementById('nui').contentWindow;
      for(let i=0;i<100;i++)w.BStarFoil.updateTilt(i/20-3,3-i/20);
    });
    assert.deepEqual(await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarSpectralEdges.getStats()),stats,'tilt performs no new pixel analyses');
    assert(await page.evaluate(()=>document.getElementById('nui').contentWindow.document.querySelector('.rarity-ghost-edges').classList.contains('active')),'conservative contour accent available');
    await page.evaluate(async()=>{
      const w=document.getElementById('nui').contentWindow;
      const native=w.HTMLCanvasElement.prototype.getContext;
      try{
        w.HTMLCanvasElement.prototype.getContext=()=>{throw new Error('simulated unreadable canvas');};
        const result=await w.BStarSpectralEdges.get('images/cards/ALPH1-EN002_MR_BSTAR.png',w.BSTAR_FOIL_SAMPLES.settings.artworkPolygon);
        if(result!==null)throw new Error('unreadable canvas should disable only the optional edge accent');
      }finally{w.HTMLCanvasElement.prototype.getContext=native;}
    });
    await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarFoil.configure({rarity:null}));
  }

  await set(sample,'DARK');assert.match((await state()).mask,/dark\.png/);
  await set(sample,'LIGHT');assert.match((await state()).mask,/light\.png/);
  // Experimental threshold preview controls belong to Work; tests use production masks.
  await set(sample);
  await page.evaluate(()=>{
    const w=document.getElementById('nui').contentWindow;
    w.BSTAR_FOIL_SAMPLES.cards['ALPH1-EN001_LAYLA_HART.png'].CUSTOM='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aT1sAAAAASUVORK5CYII=';
    w.BStarFoil.configure({mode:'CUSTOM'});
  });
  await page.waitForTimeout(100);assert((await state()).art,'CUSTOM alpha mask consumed');
  await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarFoil.configure({mode:'DARK',rarity:'GHOST'}));
  await page.evaluate(options=>window.rarityTest.set(options),{mode:'FULL',x:0,y:0});
  await page.waitForTimeout(500);const neutral=await state();
  await page.evaluate(options=>window.rarityTest.set(options),{x:-6,y:6});await page.waitForTimeout(500);const tilted=await state();
  assert(tilted.ghostOpacity>neutral.ghostOpacity+0.5,'Ghost transformation follows smoothed angle');
  await surface.screenshot({path:path.join(output,'ghost-on-colour-art.png')});
  await page.evaluate(options=>window.rarityTest.set(options),{x:0,y:0});
  await page.waitForTimeout(550);assert((await state()).ghostOpacity<0.15,'Ghost returns smoothly to neutral');
  await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarFoil.configure({rarity:null,mode:'FULL'}));
  const img=page.frameLocator('#nui').locator('#cardImage');
  await img.click();assert(await img.evaluate(el=>el.classList.contains('zoomed')),'zoom works');
  await page.evaluate(()=>document.getElementById('nui').contentWindow.document.getElementById('foilModeBtn').click());
  assert.equal((await state()).settings.mode,'DARK','viewer button cycles full to dark');
  await page.frameLocator('#nui').locator('#closeBtn').click();
  assert(await page.frameLocator('#nui').locator('#viewerWrap').evaluate(el=>el.classList.contains('hidden')),'Close works');
  await set(sample);await page.keyboard.press('Escape');
  assert(await page.frameLocator('#nui').locator('#viewerWrap').evaluate(el=>el.classList.contains('hidden')),'Escape works');
  await set(sample);await page.frameLocator('#nui').locator('#viewerWrap').click({position:{x:10,y:10}});
  assert(await page.frameLocator('#nui').locator('#viewerWrap').evaluate(el=>el.classList.contains('hidden')),'background click works');
  assert.deepEqual(errors,[],'no JS errors');
  fs.writeFileSync(path.join(output,'results.json'),JSON.stringify(reports,null,2));
  console.log('PASS six real rarities, pixel-identical Common, visible finishes, DARK/LIGHT/CUSTOM mask compatibility, Ghost angle/neutral, zoom/button/Close/ESC/background');
  console.log('Screenshots: '+output);
})().catch(error=>{console.error(error);process.exitCode=1}).finally(async()=>{if(browser)await browser.close();server.close();});
