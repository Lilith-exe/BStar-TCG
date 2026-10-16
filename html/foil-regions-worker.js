// All image analysis and alpha composition stays off the NUI main thread.
self.window = self;
importScripts('foil-mask.js');
const atlases = new Map();
let bytes = 0, analyses = 0;
const budget = 40 * 1024 * 1024;
async function bitmap(url, integer = false) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Asset HTTP ${response.status}: ${url}`);
  const blob = await response.blob();
  return integer ? createImageBitmap(blob, { colorSpaceConversion: 'none' }) : createImageBitmap(blob);
}
async function atlas(entry, profile) {
  const map = entry.indexed[profile], key = map.url;
  if (atlases.has(key)) {
    const value = atlases.get(key); atlases.delete(key); atlases.set(key, value); return value;
  }
  const [width, height] = map.dimensions;
  const loaded = await Promise.allSettled([bitmap(map.url, true), bitmap(profile === 'thumb' ? entry.thumbnail : entry.image)]);
  const failure = loaded.find(item => item.status === 'rejected');
  if (failure) { loaded.forEach(item => { if (item.status === 'fulfilled') item.value.close(); }); throw failure.reason; }
  const encoded = loaded[0].value, image = loaded[1].value;
  try {
  const canvas = new OffscreenCanvas(...map.encodedDimensions);
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  try {
    if (encoded.width !== canvas.width || encoded.height !== canvas.height) throw new Error('Indexed dimensions mismatch');
    ctx.imageSmoothingEnabled = false; ctx.drawImage(encoded, 0, 0);
  } catch (error) { image.close(); throw error; } finally { encoded.close(); }
  const data = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
  const count = width * height, ids = new Uint8Array(count), edge = new Uint8Array(map.edgeBytes);
  for (let i = 0; i < count; i++) {
    ids[i] = data[i * 4];
    if (ids[i] > 10 || data[i * 4 + 1] !== ids[i] || data[i * 4 + 2] !== ids[i]) throw new Error('Invalid integer region ID');
  }
  for (let i = 0; i < edge.length; i++) edge[i] = data[(count + i) * 4];
  const header = new DataView(edge.buffer);
  if (header.getUint32(0, true) !== 0x324e4752 || header.getUint32(4, true) !== width ||
      header.getUint32(8, true) !== height || 24 + header.getUint32(12, true) * 5 + header.getUint32(16, true) * 7 + header.getUint32(20, true) * 14 !== edge.length) throw new Error('Invalid edge coverage payload');
  canvas.width = width; canvas.height = height;
  try {
    const expected = profile === 'thumb' ? [300, 405] : entry.dimensions;
    if (image.width !== expected[0] || image.height !== expected[1]) throw new Error('Artwork dimensions mismatch');
    ctx.imageSmoothingEnabled = true; ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(image, 0, 0, width, height);
  } finally { image.close(); }
  const pixels = ctx.getImageData(0, 0, width, height).data;
  canvas.width = canvas.height = 1;
  const value = { width, height, ids, edge, pixels, bytes: ids.byteLength + edge.byteLength + pixels.byteLength };
  atlases.set(key, value); bytes += value.bytes; analyses++;
  while (bytes > budget && atlases.size > 1) {
    const oldest = atlases.keys().next().value; bytes -= atlases.get(oldest).bytes; atlases.delete(oldest);
  }
  return value;
  } finally { encoded.close(); image.close(); }
}
async function compose(message) {
  const a = await atlas(message.entry, message.profile), selected = new Uint8Array(11);
  for (const id of message.regionIds) selected[id] = 1;
  const output = new Uint8ClampedArray(a.width * a.height * 4);
  output.fill(255);
  const artwork = (alpha, i) => {
    if (message.mode === 'FULL') return alpha;
    const j = i * 4, w = BStarArtworkMasks.weights(a.pixels[j], a.pixels[j + 1], a.pixels[j + 2], message.threshold, 'brightness', message.feather);
    const light = Math.round(w.light * alpha); return message.mode === 'LIGHT' ? light : alpha - light;
  };
  for (let i = 0; i < a.ids.length; i++) {
    const id = a.ids[i], j = i * 4;
    output[j + 3] = selected[id] ? (id === 1 ? artwork(a.pixels[j + 3], i) : a.pixels[j + 3]) : 0;
  }
  const view = new DataView(a.edge.buffer);
  const coverage = (id, value, i) => selected[id] ? (id === 1 ? artwork(value, i) : value) : 0;
  const apply = (i, alpha) => { if (i >= a.ids.length) throw new Error('Edge pixel outside region plane'); output[i * 4 + 3] = Math.min(a.pixels[i * 4 + 3], alpha); };
  let pos = 24;
  for (let n = 0; n < view.getUint32(12, true); n++, pos += 5) {
    const i = view.getUint32(pos, true); apply(i, coverage(a.ids[i], a.edge[pos + 4], i));
  }
  for (let n = 0; n < view.getUint32(16, true); n++, pos += 7) {
    const i = view.getUint32(pos, true), other = a.edge[pos + 5];
    if (other < 1 || other > 10) throw new Error('Invalid edge region ID');
    apply(i, coverage(a.ids[i], a.edge[pos + 4], i) + coverage(other, a.edge[pos + 6], i));
  }
  for (; pos < a.edge.length; pos += 14) {
    const i = view.getUint32(pos, true);
    if (i >= a.ids.length) throw new Error('Edge pixel outside region plane');
    let alpha = 0;
    for (let id = 1; id <= 10; id++) if (selected[id]) alpha += id === 1 ? artwork(a.edge[pos + 3 + id], i) : a.edge[pos + 3 + id];
    apply(i, alpha);
  }
  const canvas = new OffscreenCanvas(a.width, a.height);
  canvas.getContext('2d').putImageData(new ImageData(output, a.width, a.height), 0, 0);
  const blob = await canvas.convertToBlob({ type: 'image/png' }); canvas.width = canvas.height = 1;
  return { blob, width: a.width, height: a.height };
}
self.onmessage = async ({ data }) => {
  try {
    const result = data.kind === 'stats' ? { analyses, bytes, atlases: atlases.size } :
      data.kind === 'warm' ? true : data.kind === 'prepare' ? !!(await atlas(data.entry, data.profile)) : await compose(data);
    self.postMessage({ id: data.id, result });
  }
  catch (error) { self.postMessage({ id: data.id, error: error.message }); }
};
