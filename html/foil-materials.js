// Exact definitions and GLSL from tools/nui-lab/playground.js; shared production context.
(() => {
  const common=['density','scale','sharpness','saturation'];
  const definitions={
    'pg-shards':{name:'Starlight Shards',mode:0,controls:common,defaults:{density:.85,sharpness:.8}},
    'pg-etching':{name:'Prismatic Etching',mode:1,controls:common,defaults:{density:.7,sharpness:.65}},
    'pg-crystal':{name:'Crystal Fracture',mode:2,controls:common,defaults:{density:.55,sharpness:.7}},
    'pg-flake':{name:'Metallic Flake',mode:3,controls:[...common,'metal','tint'],defaults:{density:.8,sharpness:.8,metal:'silver',tint:'#80cfff'}},
    'pg-damascus':{name:'Rainbow Damascus',mode:4,controls:common,defaults:{density:.6,sharpness:.55}},
    'pg-mercury':{name:'Liquid Mercury',mode:5,controls:common,defaults:{density:.35,sharpness:.5,saturation:.25,blend:'normal'}},
    'pg-aurora':{name:'Aurora Foil',mode:6,controls:common,defaults:{density:.35,sharpness:.25}},
    'pg-diamond':{name:'Diamond Dust',mode:7,controls:common,defaults:{density:.95,sharpness:.9}},
    'pg-oil':{name:'Oil-Slick Interference',mode:8,controls:common,defaults:{density:.45,sharpness:.55,blend:'normal'}},
    'pg-circuit':{name:'Holographic Circuit',mode:9,controls:common,defaults:{density:.5,sharpness:.7}}
  };
  for(const def of Object.values(definitions)){
    def.family='playground';def.defaults={intensity:1,scale:1,saturation:1,sensitivity:1,blend:'screen',...def.defaults};
  }
  // Baseline IDs and their optical defaults are retained. Refinements are opt-in.
  for(const def of Object.values(definitions)){
    def.baseline=true;def.defaults={brightness:1,particleSize:1,variant:0,...def.defaults};
    def.controls=[...def.controls,'brightness',...([0,3,7].includes(def.mode)?['particleSize']:[])];
  }
  const variations={
    'pg-shards-bright':['pg-shards','Starlight Shards · Bright', {density:.95,sharpness:.85,brightness:2.6,particleSize:1.7,variant:1}],
    'pg-etching-bright':['pg-etching','Prismatic Etching · Strong diffraction',{brightness:2.2,saturation:1.35,sharpness:.8,variant:1}],
    'pg-flake-dense':['pg-flake','Metallic Flake · Dense reflective',{density:1,brightness:2.3,particleSize:1.45,variant:1}],
    'pg-mercury-subtle':['pg-mercury','Liquid Mercury · Subtle pearl',{density:.15,brightness:.65,sharpness:.35,variant:1}],
    'pg-diamond-bright':['pg-diamond','Diamond Dust · Dense spectral',{density:1,brightness:3,particleSize:1.15,sharpness:.9,variant:1}],
    'pg-circuit-starlight':['pg-circuit','Holographic Circuit · Starlight etching',{density:.85,brightness:2.4,sharpness:.88,mode:10,variant:1}]
  };
  for(const [id,[original,name,overrides]]of Object.entries(variations)){
    const parent=definitions[original];const {mode=parent.mode,...params}=overrides;
    definitions[id]={...parent,name,mode,baseline:false,original,controls:[...parent.controls],defaults:{...parent.defaults,...params}};
  }
  const vertex=`attribute vec2 pos; varying vec2 uv; void main(){uv=pos*.5+.5;gl_Position=vec4(pos,0.,1.);}`;
  const fragment=`precision highp float;
  varying vec2 uv; uniform int u_mode; uniform vec2 u_tilt;
  uniform float u_density,u_scale,u_sharp,u_saturation,u_intensity;
  uniform vec3 u_metal; uniform float u_gain,u_size,u_variant;
  vec2 hash(vec2 p){return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);}
  vec3 rainbow(float t){return .55+.45*cos(6.283185*(vec3(0.,.33,.67)+t));}
  float field(vec2 p){return sin(p.x*1.7+sin(p.y*2.3))*.5+cos(p.y*1.3+sin(p.x*2.1))*.5;}
  float catchLight(float normal){return pow(max(0.,cos(normal+u_tilt.x*1.6-u_tilt.y*.8)),mix(6.,96.,u_sharp));}
  // Fixed irregular Voronoi facets: distance, seed and distance to neighboring face.
  vec4 facet(vec2 p){vec2 cell=floor(p),f=fract(p);float a=10.,b=10.;vec2 seed=vec2(0.);
    for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
      vec2 offset=vec2(float(x),float(y)),r=hash(cell+offset),v=offset+.12+r*.76-f;
      float d=dot(v,v);if(d<a){b=a;a=d;seed=r;}else b=min(b,d);
    }return vec4(sqrt(a),seed,b-a);
  }
  void main(){
    vec2 p=vec2(uv.x,(1.-uv.y)*1.35),q=p/max(.4,u_scale);
    float angle=u_tilt.x*1.1-u_tilt.y*.7, freq=mix(60.,190.,u_density);
    float spot=exp(-length(p-(vec2(.5,.66)+u_tilt*vec2(.22,-.18)))*1.8);
    float energy=0.,silver=0.,hue=0.;vec3 col=vec3(1.);
    if(u_mode==0 || u_mode==3 || u_mode==7){
      vec2 grid=q*freq*(u_variant>.5?(u_mode==7?1.9:1.45):1.),cell=floor(grid),r=hash(cell),d=fract(grid)-(.15+.7*r);
      float rotation=r.x*6.28;d=mat2(cos(rotation),-sin(rotation),sin(rotation),cos(rotation))*d;
      d/=u_size;
      float shape=1.-smoothstep(.14,.25,abs(d.x)*1.2+abs(d.y)*(u_mode==7?2.5:4.));
      float spec=catchLight((r.y-.5)*5.8);float sparkle=shape*spec*(.3+.7*spot);
      if(u_mode==0){energy=sparkle;col=mix(rainbow(r.x*.8+angle*.22+q.y*.3),vec3(1.),spec*.4);}
      else if(u_mode==3){energy=shape*(.025+spec*.95);col=mix(u_metal*.28,u_metal+vec3(.25),spec);}
      else{energy=shape*pow(spec,1.4);col=mix(vec3(1.),rainbow(r.x+angle*.45),step(.87,r.x)*.85);}
    }else if(u_mode==1){
      float etched=abs(fract((q.x+q.y*.72)*mix(130.,340.,u_density))-.5);
      float groove=1.-smoothstep(.04,.16,etched);
      float sweep=pow(.5+.5*cos((q.x-q.y)*7.+angle*4.),mix(2.,14.,u_sharp));
      energy=groove*(.025+.95*sweep)*spot;col=rainbow(q.x*.7+q.y*.45+angle*.65);
    }else if(u_mode==2){
      vec4 f=facet(q*mix(24.,85.,u_density));float spec=catchLight((f.y+f.z-1.)*4.8);
      float rim=1.-smoothstep(.005,.025,f.w);
      energy=(spec*(.5+.5*spot)+rim*.07);col=mix(rainbow(f.y+angle*.3),vec3(1.),spec*.5);
    }else if(u_mode==4){
      float warp=field(q*5.);float layers=q.y*mix(25.,80.,u_density)+warp*3.5;
      float ridges=pow(.5+.5*sin(layers*6.28),mix(2.,12.,u_sharp));
      float reflection=pow(.5+.5*cos(warp*3.+q.x*2.+angle*3.),4.);
      energy=ridges*(.045+.8*reflection);col=rainbow(warp*.18+layers*.04+angle*.45);
    }else if(u_mode==5){
      float ripple=field(q*mix(2.,8.,u_density));
      float reflected=sin(q.x*5.+ripple*(u_variant>.5?.55:2.)+angle*4.);
      float band=pow(max(0.,reflected),mix(2.,18.,u_sharp));
      energy=(u_variant>.5?.04:.12)+band*.8;silver=.06+band*.94;col=vec3(silver*.92,silver*.97,silver);
      col+=rainbow(ripple*.2+angle*.1)*band*.12;
    }else if(u_mode==6){
      float ribbons=sin(q.x*mix(5.,15.,u_density)+field(q*2.)*2.);
      float ribbon=pow(.5+.5*cos(q.y*5.+ribbons*2.),mix(1.,5.,u_sharp));
      float sweep=.15+.85*pow(.5+.5*sin(q.x*2.+angle*2.5),2.);
      energy=ribbon*sweep*.8;col=rainbow(ribbons*.22+q.y*.18+angle*.25);
    }else if(u_mode==8){
      float organic=field(q*mix(3.,9.,u_density));float film=organic*2.+field(q*3.7)*.7;
      float band=.5+.5*cos(film*7.+angle*5.);
      energy=.08+pow(band,mix(1.,6.,u_sharp))*.68;
      col=rainbow(film*.7+angle*.8)*(.25+.75*band);
    }else if(u_mode==10){
      float warp=field(q*4.)*.14;
      float etched=abs(fract((q.x+q.y*.68)*mix(120.,330.,u_density)+warp)-.5);
      float groove=1.-smoothstep(.035,.13,etched);
      vec2 normal=hash(floor(q*mix(75.,170.,u_density)));
      float spec=catchLight((normal.y-.5)*4.8);
      float sweep=pow(.5+.5*cos(dot(q,vec2(6.,-4.))+angle*3.),mix(3.,32.,u_sharp));
      energy=groove*(.01+.8*sweep+.4*spec)*spot;
      col=mix(rainbow(q.x*.5+q.y*.25+angle*.5),vec3(1.),spec*.55);
    }else{
      vec2 grid=q*mix(12.,42.,u_density),cell=floor(grid),f=fract(grid),r=hash(cell);
      float trace=1.-smoothstep(.016,.04,min(abs(f.x-(r.x>.5?.25:.75)),abs(f.y-.5)));
      float fine=1.-smoothstep(.008,.025,abs(f.y-.78));
      float node=1.-smoothstep(.04,.075,length(f-vec2(r.x>.5?.25:.75,.5)));
      float sweep=pow(.5+.5*cos(dot(q,vec2(4.,-3.))+angle*4.),mix(3.,18.,u_sharp));
      energy=(trace*.85+fine*.2+node)*(.025+.95*sweep);
      col=mix(rainbow(q.x*.25+angle*.4),vec3(.7,.95,1.),node*.6);
    }
    col=mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,u_saturation);
    float alpha=min(.88,energy*u_intensity*u_gain);
    gl_FragColor=vec4(clamp(col,0.,1.),alpha);
  }`;
// Shared renderer appended to the byte-exact Test Lab material definitions/GLSL.
// No clock/frame loop; the existing pointer/tilt path requests draws.
  let canvas, gl, program, uniforms, last = '', draws = 0, compilations = 0;
  const listeners = new Set();
  function init() {
    if (gl) return;
    canvas = document.createElement('canvas'); canvas.width = 640; canvas.height = 864;
    gl = canvas.getContext('webgl', {alpha:true,antialias:false,depth:false,stencil:false,premultipliedAlpha:false,preserveDrawingBuffer:true});
    if (!gl) throw new Error('Exact Lab materials require WebGL');
    const compile = (type, source) => {
      const shader = gl.createShader(type); gl.shaderSource(shader, source); gl.compileShader(shader);
      if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(shader));
      return shader;
    };
    program = gl.createProgram();
    const vs = compile(gl.VERTEX_SHADER, vertex), fs = compile(gl.FRAGMENT_SHADER, fragment);
    gl.attachShader(program, vs); gl.attachShader(program, fs); gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(program));
    gl.deleteShader(vs); gl.deleteShader(fs); gl.useProgram(program);
    const buffer = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1,1,-1,-1,1,-1,1,1,-1,1,1]), gl.STATIC_DRAW);
    const pos = gl.getAttribLocation(program, 'pos'); gl.enableVertexAttribArray(pos); gl.vertexAttribPointer(pos,2,gl.FLOAT,false,0,0);
    uniforms = Object.fromEntries(['mode','tilt','density','scale','sharp','saturation','intensity','metal','gain','size','variant'].map(k => [k, gl.getUniformLocation(program,'u_'+k)]));
    compilations++; last = '';
    canvas.addEventListener('webglcontextlost', event => { event.preventDefault(); last = ''; listeners.forEach(fn => fn(false)); });
    canvas.addEventListener('webglcontextrestored', () => { gl = null; init(); listeners.forEach(fn => fn(true)); });
  }
  function draw(target, settings, tilt) {
    init();
    if (gl.isContextLost()) throw new Error('Material GPU context lost');
    const angles = tilt.map(x => Math.round(x * 100) / 100);
    const signature = JSON.stringify([settings, angles]);
    if (signature !== last) {
      gl.useProgram(program); gl.viewport(0,0,640,864);
      gl.uniform1i(uniforms.mode, definitions[settings.preset].mode);
      gl.uniform2f(uniforms.tilt, angles[1]/8*settings.sensitivity, angles[0]/8*settings.sensitivity);
      for (const [key,value] of Object.entries({density:settings.density,scale:settings.scale,sharp:settings.sharpness,saturation:settings.saturation,intensity:settings.intensity,gain:settings.brightness,size:settings.particleSize,variant:settings.variant})) gl.uniform1f(uniforms[key],value);
      const hex = settings.metal==='gold' ? '#ffd47a' : settings.metal==='custom' ? settings.tint||'#80cfff' : '#dce8ff';
      gl.uniform3f(uniforms.metal, ...[1,3,5].map(i => parseInt(hex.slice(i,i+2),16)/255));
      gl.drawArrays(gl.TRIANGLES,0,6); last = signature; draws++;
    }
    const ctx = target.getContext('2d'); ctx.clearRect(0,0,640,864); ctx.drawImage(canvas,0,0);
  }
  let preparing;
  function prepare() {
    if (!preparing) preparing = new Promise(resolve => setTimeout(resolve, 0)).then(init).catch(error => { preparing = null; console.warn('[BStar foil] GPU preparation deferred:', error.message); });
    return preparing;
  }
  window.BStarFoilMaterials = { definitions, draw, prepare, subscribe(fn) { listeners.add(fn); return () => listeners.delete(fn); },
    getStats: () => ({ contexts: gl ? 1 : 0, compilations, draws }),
    // Exposed for focused comparison against the actual Lab, without changing shaders.
    source: { vertex, fragment }, getCanvas: () => canvas };

})();
