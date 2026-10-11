// Production counterpart of the Lab split-blend calculation; no analysis during tilt.
(() => {
  function weights(r, g, b, threshold, metric = 'brightness', softness = 0.3) {
    const value = metric === 'brightness' ? (0.2126*r+0.7152*g+0.0722*b)/255 : (Math.max(r,g,b)+Math.min(r,g,b))/510;
    const t=softness>0 ? Math.max(0,Math.min(1,(value-(threshold-softness/2))/softness)) : value>=threshold ? 1:0;
    const light=t*t*(3-2*t);
    return {dark:1-light,light};
  }
  const cache = new Map();
  let analyses = 0;
  async function build(source, points, threshold = 0.11, softness = 0.33, mode = 'DARK', cachedPath = null) {
    const key = JSON.stringify([source,points,threshold,softness,mode,cachedPath]);
    if (cache.has(key)) return cache.get(key);
    const job = (async () => {
      const image = new Image(); image.src = source; await image.decode();
      const canvas = document.createElement('canvas'); canvas.width = 384;
      canvas.height = Math.round(canvas.width*image.naturalHeight/image.naturalWidth);
      const ctx = canvas.getContext('2d',{willReadFrequently:true});
      ctx.drawImage(image,0,0,canvas.width,canvas.height);
      const pixels = ctx.getImageData(0,0,canvas.width,canvas.height);
      const region = document.createElement('canvas'); region.width=canvas.width; region.height=canvas.height;
      const rc = region.getContext('2d',{willReadFrequently:true}); rc.beginPath();
      points.forEach(([x,y],i) => rc[i ? 'lineTo':'moveTo'](x*canvas.width,y*canvas.height));
      rc.closePath(); rc.fillStyle='white'; rc.fill();
      const coverage = rc.getImageData(0,0,canvas.width,canvas.height);
      let cached;
      if (cachedPath) {
        const mask = new Image(); mask.src=cachedPath; await mask.decode();
        rc.clearRect(0,0,canvas.width,canvas.height); rc.drawImage(mask,0,0,canvas.width,canvas.height);
        cached=rc.getImageData(0,0,canvas.width,canvas.height);
      }
      const art=ctx.createImageData(canvas.width,canvas.height), combined=ctx.createImageData(canvas.width,canvas.height);
      for (let i=0;i<pixels.data.length;i+=4) {
        const c=coverage.data[i+3];
        let selectedAlpha=0;
        if (c) {
          if (cached) selectedAlpha=Math.min(c,cached.data[i+3]);
          else {
            const selected=weights(pixels.data[i],pixels.data[i+1],pixels.data[i+2],threshold,'brightness',softness);
            const alpha=Math.round(c*pixels.data[i+3]/255);
            const light=Math.round(selected.light*alpha);
            selectedAlpha=mode==='FULL' ? alpha : mode==='LIGHT' ? light : alpha-light;
          }
        }
        for (const output of [art,combined]) {output.data[i]=255;output.data[i+1]=255;output.data[i+2]=255;}
        art.data[i+3]=selectedAlpha;
        combined.data[i+3]=255-c+selectedAlpha;
      }
      analyses++;
      ctx.putImageData(art,0,0); const artwork=canvas.toDataURL('image/png');
      ctx.putImageData(combined,0,0); const regional=canvas.toDataURL('image/png');
      return {artwork,regional,width:canvas.width,height:canvas.height};
    })();
    cache.set(key,job);
    while(cache.size>12)cache.delete(cache.keys().next().value);
    try {return await job;} catch(error){cache.delete(key);throw error;}
  }
  window.BStarArtworkMasks={weights,build,getStats:()=>({analyses,cached:cache.size})};
})();
