const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');const {once}=require('node:events');const {chromium}=require('playwright');const {server,catalog}=require('./rarity-test-server.cjs');
const root=path.resolve(__dirname,'../.git/secret-ghost-next');const baseline=process.env.BSTAR_NEXT_BASELINE==='1';let browser;
(async()=>{if(!server.listening)await once(server,'listening');browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});const page=await browser.newPage({viewport:{width:1440,height:1000},reducedMotion:'reduce'});const errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto('http://127.0.0.1:'+server.address().port);await page.waitForFunction(()=>window.rarityTest.ready);
const show=async(rarity,x=0,y=0)=>{const c=catalog().find(c=>c.rarity===rarity);await page.evaluate(({c,x,y})=>{const w=document.getElementById('nui').contentWindow;w.BStarFoil.configure({mode:null,intensity:null,rarity:null,enabled:true});w.rarityFixture.show(c);w.rarityFixture.tilt(x,y);},{c,x,y});await page.waitForTimeout(600);};
const surface=page.frameLocator('#nui').locator('#cardSurface');
for(const r of ['COMMON','RARE','SUPER','ULTRA'])for(const [pose,x,y]of [['neutral',0,0],['tilted',-4,6]]){await show(r,x,y);const png=await surface.screenshot();const name=r.toLowerCase()+'-'+pose+'.png';if(baseline)fs.writeFileSync(path.join(root,name),png);else assert(png.equals(fs.readFileSync(path.join(root,name))),'approved appearance changed: '+name);}
if(baseline){console.log('Captured four approved rarities at default intensity/coverage, neutral and tilted.');return;}
const poses=[['neutral',0,0],['left',-4,-6],['right',4,6]];
let anchor,quiet;
for(const [pose,x,y]of poses){
 await show('SECRET',x,y);
 const state=await page.evaluate(()=>{const w=document.getElementById('nui').contentWindow,d=w.document,el=d.querySelector('.rarity-starlight'),bands=d.querySelector('.secret-facets');const a=w.getComputedStyle(el,'::before'),b=w.getComputedStyle(bands,'::before'),c=w.getComputedStyle(bands,'::after');return {geometry:[a,b,c].map(p=>[p.maskImage,p.maskPosition,p.maskSize,p.transform]),levels:[a,b,c].map(p=>Number(p.opacity)),mask:w.getComputedStyle(el).maskImage,full:w.getComputedStyle(d.querySelector('.rarity-full')).maskImage,settings:w.BStarFoil.getSettings()};});
 assert.equal(state.settings.mode,'DARK');assert.equal(state.settings.intensity,1);assert.equal(state.settings.threshold,.11);assert.equal(state.settings.feather,.33);assert.equal(state.mask,state.full);
 if(!anchor){anchor=state.geometry;quiet=Math.max(...state.levels);assert(quiet<.25,'most facets quiet at neutral');}else assert.deepEqual(state.geometry,anchor,'fixed facet geometry');
 if(pose==='left')assert(Math.max(...state.levels)>quiet*3,'angular facet catch is substantially brighter');
 await surface.screenshot({path:path.join(root,'secret-'+pose+'.png')});
 console.log('Secret',pose,'facet reflection levels',state.levels);
}
const colour=catalog().find(c=>c.inventoryImage==='ALPH1-EN001_LAYLA_HART.png');let ghostNeutral;
for(const [pose,x,y]of poses){
 await page.evaluate(({c,x,y})=>{const w=document.getElementById('nui').contentWindow;w.BStarFoil.configure({rarity:'GHOST',mode:'FULL',intensity:.55,ghost:{metallic:.9,diffraction:.7,visibility:.85}});w.rarityFixture.show(c);w.rarityFixture.tilt(x,y);},{c:colour,x,y});await page.waitForTimeout(650);
 const tone=await page.evaluate(()=>{const w=document.getElementById('nui').contentWindow,d=w.document;return {conceal:Number(d.getElementById('cardSurface').style.getPropertyValue('--ghost-conceal')),rainbow:Number(w.getComputedStyle(d.querySelector('.rarity-full')).opacity),image:Number(w.getComputedStyle(d.querySelector('.rarity-ghost-art')).opacity),metalMask:w.getComputedStyle(d.querySelector('.rarity-ghost-art')).maskImage,rainbowClip:w.getComputedStyle(d.querySelector('.rarity-full')).clipPath};});
 if(pose==='neutral')ghostNeutral=tone;else if(pose==='right'){assert(tone.conceal>ghostNeutral.conceal+.5);assert(tone.image>ghostNeutral.image+.15);assert(Math.abs(tone.rainbow-ghostNeutral.rainbow)>.1);}
 assert.match(tone.rainbowClip,/polygon/);await surface.screenshot({path:path.join(root,'ghost-colour-'+pose+'.png')});console.log('Ghost',pose,tone);
}
await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarFoil.configure({ghost:{metallic:0}}));
assert.equal(await page.evaluate(()=>Number(document.getElementById('nui').contentWindow.getComputedStyle(document.getElementById('nui').contentWindow.document.querySelector('.rarity-ghost-art')).opacity)),0);
await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarFoil.configure({ghost:{metallic:.9,diffraction:0}}));
assert.equal(await page.evaluate(()=>Number(document.getElementById('nui').contentWindow.getComputedStyle(document.getElementById('nui').contentWindow.document.querySelector('.rarity-full')).opacity)),0);
await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarFoil.configure({ghost:{diffraction:.7,visibility:0}}));
assert.equal(await page.evaluate(()=>Number(document.getElementById('nui').contentWindow.document.getElementById('cardSurface').style.getPropertyValue('--ghost-conceal'))),0);
await page.evaluate(()=>{const w=document.getElementById('nui').contentWindow,c=w.document.createElement('canvas');c.width=c.height=1;w.BSTAR_FOIL_SAMPLES.cards['ALPH1-EN001_LAYLA_HART.png'].CUSTOM=c.toDataURL();w.BStarFoil.configure({mode:'CUSTOM'});});await page.waitForTimeout(120);
assert(await page.evaluate(()=>{const w=document.getElementById('nui').contentWindow,d=w.document;return w.getComputedStyle(d.querySelector('.rarity-full')).maskImage===w.getComputedStyle(d.querySelector('.rarity-ghost-art')).maskImage;}),'Ghost diffraction shares selected custom mask');
await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarFoil.configure({mode:'FULL',ghost:{metallic:.9,diffraction:.7,visibility:.85}}));await page.waitForTimeout(120);
const stats=await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarSpectralEdges.getStats());
await page.evaluate(()=>{const w=document.getElementById('nui').contentWindow;for(let i=0;i<100;i++)w.BStarFoil.updateTilt(i/20,i/30);});
assert.deepEqual(await page.evaluate(()=>document.getElementById('nui').contentWindow.BStarSpectralEdges.getStats()),stats);
await page.frameLocator('#nui').locator('#cardImage').click();assert(await page.frameLocator('#nui').locator('#cardImage').evaluate(e=>e.classList.contains('zoomed')));
await page.frameLocator('#nui').locator('#closeBtn').click();assert(await page.frameLocator('#nui').locator('#viewerWrap').evaluate(e=>e.classList.contains('hidden')));
console.log('PASS fixed angular Secret facets, masked Ghost metal/diffraction/reveal controls, caching and zoom/close.');
assert.deepEqual(errors,[]);console.log('PASS four approved default appearances remain pixel-identical at both poses.');
})().catch(e=>{console.error(e);process.exitCode=1}).finally(async()=>{if(browser)await browser.close();server.close();});
