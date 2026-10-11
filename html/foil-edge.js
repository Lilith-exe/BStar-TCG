// Optional cached Ghost contour accent. Never part of DARK/LIGHT threshold generation.
(() => {
  const cache = new Map();
  let analyses = 0;
  const load = source => new Promise(resolve => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = () => resolve(null);
    image.src = source;
  });

  async function build(source, polygon, subject) {
    try {
      const image = await load(subject || source);
      if (!image || !polygon?.length) return null;
      const width = 256, height = Math.round(width * image.height / image.width);
      const canvas = document.createElement('canvas');
      canvas.width = width; canvas.height = height;
      const ctx = canvas.getContext('2d', { willReadFrequently: true });
      ctx.drawImage(image, 0, 0, width, height);
      const data = ctx.getImageData(0, 0, width, height).data;
      const field = new Float32Array(width * height);
      for (let i = 0; i < field.length; i++) field[i] = subject ? data[i * 4 + 3] : (data[i * 4] * 0.2126 + data[i * 4 + 1] * 0.7152 + data[i * 4 + 2] * 0.0722);
      const horizontal = new Float32Array(field.length), blurred = new Float32Array(field.length);
      for (let y = 2; y < height - 2; y++) for (let x = 2; x < width - 2; x++) {
        const i = y * width + x;
        horizontal[i] = (field[i - 2] + field[i - 1] + field[i] + field[i + 1] + field[i + 2]) / 5;
      }
      for (let y = 4; y < height - 4; y++) for (let x = 4; x < width - 4; x++) {
        const i = y * width + x;
        blurred[i] = (horizontal[i - 2 * width] + horizontal[i - width] + horizontal[i] + horizontal[i + width] + horizontal[i + 2 * width]) / 5;
      }
      ctx.clearRect(0, 0, width, height);
      ctx.beginPath(); polygon.forEach(([x, y], i) => ctx[i ? 'lineTo' : 'moveTo'](x * width, y * height));
      ctx.closePath(); ctx.fillStyle = 'white'; ctx.fill();
      const region = ctx.getImageData(0, 0, width, height).data;
      const magnitudes = new Float32Array(field.length), samples = [];
      for (let y = 5; y < height - 5; y++) for (let x = 5; x < width - 5; x++) {
        const i = y * width + x;
        if (!region[i * 4 + 3]) continue;
        const distance = ((x / width - 0.54) / 0.29) ** 2 + ((y / height - 0.39) / 0.26) ** 2;
        if (!subject && distance >= 1) continue;
        const magnitude = Math.hypot(blurred[i + 2] - blurred[i - 2], blurred[i + 2 * width] - blurred[i - 2 * width]);
        magnitudes[i] = magnitude;
        if (magnitude > 8) samples.push(magnitude);
      }
      if (!samples.length) return null;
      samples.sort((a, b) => a - b);
      const threshold = subject ? 10 : Math.max(14, samples[Math.floor(samples.length * 0.78)]);
      const output = ctx.createImageData(width, height);
      let edgePixels = 0;
      for (let y = 5; y < height - 5; y++) for (let x = 5; x < width - 5; x++) {
        const i = y * width + x;
        if (magnitudes[i] <= threshold) continue;
        const distance = ((x / width - 0.54) / 0.29) ** 2 + ((y / height - 0.39) / 0.26) ** 2;
        const focus = subject ? 1 : Math.max(0, 1 - distance);
        const alpha = Math.round(150 * Math.min(1, (magnitudes[i] - threshold) / Math.max(20, threshold)) * focus * region[i * 4 + 3] / 255);
        output.data.set([255, 255, 255, alpha], i * 4);
        if (alpha > 8) edgePixels++;
      }
      if (edgePixels < 12) return null;
      ctx.putImageData(output, 0, 0);
      analyses++;
      return canvas.toDataURL('image/png');
    } catch {
      return null;
    }
  }

  window.BStarSpectralEdges = {
    get(source, polygon, subject = null) {
      const key = `${source}|${subject || ''}|${JSON.stringify(polygon)}`;
      if (!cache.has(key)) {
        if (cache.size >= 6) cache.delete(cache.keys().next().value);
        cache.set(key, build(source, polygon, subject));
      }
      return cache.get(key);
    },
    getStats: () => ({ analyses, cached: cache.size })
  };
})();
