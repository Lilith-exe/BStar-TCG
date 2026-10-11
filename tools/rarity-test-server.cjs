const http=require('node:http');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const html=path.join(root,'html');
function catalog(){
  const lua=fs.readFileSync(path.join(root,'shared/cards.lua'),'utf8');
  const starts=[...lua.matchAll(/^    \['([^']+)'\] = \{/gm)];
  return starts.map((m,i)=>{
    const block=lua.slice(m.index,starts[i+1]?.index||lua.length);
    const field=k=>block.match(new RegExp('^        '+k+" = '([^']*)'",'m'))?.[1]||'';
    return {id:m[1],name:field('name'),rarity:field('rarity'),inventoryImage:field('inventoryImage')};
  }).filter(c=>c.inventoryImage&&path.basename(c.inventoryImage)===c.inventoryImage&&fs.existsSync(path.join(html,'images/cards',c.inventoryImage)));
}
const bridge=`window.GetParentResourceName=()=> 'bstar_cards';
window.fetch=async()=>new Response(JSON.stringify({ok:true,mocked:true}),{headers:{'Content-Type':'application/json'}});
window.rarityFixture={show(card){window.dispatchEvent(new MessageEvent('message',{data:{action:'showCard',card:{...card,image:'images/cards/'+card.inventoryImage}}}));},tilt(x,y){targetRotateX=x;targetRotateY=y;currentRotateX=x;currentRotateY=y;ensureAnimationLoop();}};`;
const host=`<!doctype html><meta charset="utf-8"><style>body{margin:0;background:#17121c}iframe{display:block;border:0;width:100vw;height:100vh}</style><iframe id="nui" src="/nui/index.html"></iframe><script src="/test/host.js"></script>`;
const hostJS=`window.rarityTest={ready:false};let cards,state={mode:'FULL',intensity:.55,x:0,y:0};
document.getElementById('nui').addEventListener('load',async()=>{cards=await(await fetch('/catalog.json')).json();window.rarityTest.ready=true;});
window.rarityTest.set=async options=>{state={...state,...options};const w=document.getElementById('nui').contentWindow;
if(options.card)w.rarityFixture.show(cards.find(c=>c.id===options.card));
w.BStarFoil.configure({mode:state.mode==='OFF'?'FULL':state.mode,enabled:state.mode!=='OFF',intensity:state.intensity});w.rarityFixture.tilt(state.x,state.y);
await new Promise(r=>setTimeout(r,100));};`;
const mime={'.html':'text/html','.js':'text/javascript','.css':'text/css','.png':'image/png'};
const server=http.createServer((req,res)=>{
  if(req.method!=='GET'||req.headers.host!=='127.0.0.1:'+server.address().port){res.writeHead(403).end();return;}
  res.setHeader('Cache-Control','no-store');
  try{
    const url=new URL(req.url,'http://127.0.0.1');
    if(url.pathname==='/'){res.setHeader('Content-Type','text/html');res.end(host);return;}
    if(url.pathname==='/catalog.json'){res.setHeader('Content-Type','application/json');res.end(JSON.stringify(catalog()));return;}
    if(url.pathname==='/test/bridge.js'||url.pathname==='/test/host.js'){res.setHeader('Content-Type','text/javascript');res.end(url.pathname.endsWith('bridge.js')?bridge:hostJS);return;}
    if(!url.pathname.startsWith('/nui/')){res.writeHead(404).end();return;}
    const file=path.resolve(html,decodeURIComponent(url.pathname.slice(5)));
    const relative=path.relative(html,file);
    if(relative.startsWith('..')||path.isAbsolute(relative)||!mime[path.extname(file)]){res.writeHead(404).end();return;}
    const real=path.relative(fs.realpathSync(html),fs.realpathSync(file));
    if(real.startsWith('..')||path.isAbsolute(real)){res.writeHead(404).end();return;}
    let content=fs.readFileSync(file);
    if(file===path.join(html,'index.html'))content=content.toString().replace('<head>','<head><script src="/test/bridge.js"></script>');
    if(path.extname(file)==='.js')content=content.toString().replaceAll('nui://bstar_cards/html/','/nui/');
    res.setHeader('Content-Type',mime[path.extname(file)]);res.end(content);
  }catch{res.writeHead(404).end();}
});
server.listen(0,'127.0.0.1');
module.exports={server,catalog};
