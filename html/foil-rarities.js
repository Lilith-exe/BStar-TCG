// Optical settings remain in the exact exports. Requested region policy is separate.
(() => {
  const presets = window.BSTAR_TEN_MASKS.presets;
  const foundation = ['artwork', 'type_jewel'];
  const secret = ['artwork', 'inner', 'stats', 'rarity_jewel', 'type_jewel', 'other'];
  const border = { kind: 'silver', regions: ['outer'], intensity: .55, blend: 'hard-light' };
  const superFoil = { kind: 'super', regions: foundation, intensity: 1, blend: 'screen', sensitivity: 1 };
  const configurations = {
    COMMON: { layers: [] },
    RARE: { layers: [superFoil, border] },
    SUPER: { inherits: 'RARE' },
    ULTRA: { inherits: 'RARE', preset: 'ultra-damascus-maybe', layers: [
      { kind: 'material', regions: foundation, options: presets['ultra-damascus-maybe'].settings.shader },
      // The saved secondary IS the inherited Super foundation: retain its position
      // above Damascus and avoid applying a second duplicate native Super layer.
      { kind: 'super', regions: foundation, options: presets['ultra-damascus-maybe'].settings.phase2.secondary }, border
    ] },
    SECRET: { preset: 'starlight-extreme', layers: [
      { kind: 'material', regions: secret, options: presets['starlight-extreme'].settings.shader },
      { kind: 'material', regions: secret, options: presets['starlight-extreme'].settings.phase2.secondary }, border
    ] },
    GHOST: { legacy: true }
  };
  function resolve(rarity) {
    const definition = configurations[rarity] || configurations.COMMON;
    return definition.inherits ? { ...resolve(definition.inherits), ...definition } : definition;
  }
  window.BStarRarityConfig = { configurations, resolve, defaults: { mode: 'DARK', threshold: .11, feather: .33, intensity: 1 } };
})();
