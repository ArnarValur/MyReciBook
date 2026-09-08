// Generates the artboards for the MyReciBook tags rethink canvas.
import { writeFileSync } from 'node:fs';

// ── Tokens (light "Stitch Slate", lifted from app/lib/ui/theme.dart) ─────────
const C = {
  primary: '#24389C', onPrimary: '#FFFFFF', primaryContainer: '#3F51B5',
  secondaryContainer: '#ABB7FF', onSecondaryContainer: '#394687',
  tertiary: '#88003B', error: '#BA1A1A',
  scaffold: '#FAF8F0', white: '#FFFFFF', sc: '#EEEEF0', scHigh: '#E8E8EA',
  onSurface: '#1A1C1E', onSurfaceVariant: '#454652', outline: '#757684',
  outlineVariant: '#C5C5D4', hairline: 'rgba(197,197,212,0.5)', separator: 'rgba(197,197,212,0.35)',
  cardShadow: '0 4px 10px rgba(36,56,156,0.06)', modalShadow: '0 8px 20px rgba(36,56,156,0.12)',
  glassFill: 'rgba(255,255,255,0.55)', glassBorder: 'rgba(0,0,0,0.08)',
  scrim: 'rgba(11,13,22,0.45)',
};
const TINT = { primary: '#24389C', red: '#C62828', orange: '#E65100', amber: '#9A6600', green: '#2E7D32', teal: '#00695C', blue: '#1565C0', purple: '#6A1B9A' };
const GRAD = {
  indigo: 'linear-gradient(135deg,#3F51B5,#24389C)', slate: 'linear-gradient(135deg,#4A5A8C,#2C3557)',
  plum: 'linear-gradient(135deg,#8E3B62,#5B2340)', terracotta: 'linear-gradient(135deg,#B4643C,#7C3F24)',
  teal: 'linear-gradient(135deg,#2E6F6A,#1B4744)', olive: 'linear-gradient(135deg,#5E7346,#3B4A2B)',
};
const PJS = "'Plus Jakarta Sans', system-ui, -apple-system, 'Segoe UI', sans-serif";
const INTER = "'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif";

const alpha = (hex, a) => {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a})`;
};

// ── Primitives ───────────────────────────────────────────────────────────────
const ms = (name, size, color, fill = false, extra = '') =>
  `<span class="ms${fill ? ' f' : ''}" style="font-size:${size}px;color:${color};width:${size}px;height:${size}px;${extra}">${name}</span>`;

let seq = 0;
const logo = (size, color, steam = true, extra = '') => {
  const id = `lm${++seq}`;
  const vb = steam ? '26 23 56 55' : '26 51 56 27';
  return `<svg width="${size}" height="${size}" viewBox="${vb}" preserveAspectRatio="xMidYMid meet" aria-hidden="true" style="display:block;flex:none;${extra}"><mask id="${id}"><rect x="0" y="0" width="108" height="108" fill="#fff"></rect><line x1="54" y1="62" x2="54" y2="76" stroke="#000" stroke-width="2.5" stroke-linecap="round"></line></mask><path d="M54 60 C47 53 36 51 26 53 L26 72 C36 70 47 72 54 78 C61 72 72 70 82 72 L82 53 C72 51 61 53 54 60 Z" fill="${color}" mask="url(#${id})"></path>${steam ? [45, 63].map((x) => `<path d="M${x} 26 C${x - 5} 33 ${x + 5} 35 ${x} 42" fill="none" stroke="${color}" stroke-width="6" stroke-linecap="round"></path>`).join('') : ''}</svg>`;
};

// A coverless recipe's drawn cover: 135° gradient + the mark at 22% white.
const cover = (grad, w, h, mark = 40, extra = '') =>
  `<div style="width:${w};height:${h};background:${GRAD[grad]};display:flex;align-items:center;justify-content:center;flex:none;${extra}">${logo(mark, 'rgba(255,255,255,0.22)', true)}</div>`;

const stripes = (w, h, extra = '') =>
  `<div style="width:${w};height:${h};flex:none;background:repeating-linear-gradient(45deg,#D6DAF6 0 8px,#E9EBFA 8px 16px);${extra}"></div>`;

// Tag record: {name, icon (symbol name) | emoji, color, showLabel}
const glyph = (t, size, color) =>
  t.emoji ? `<span style="font-size:${Math.round(size * 0.95)}px;line-height:1;display:inline-block">${t.emoji}</span>` : ms(t.icon, size, color, t.fill);

const tagBadge = (t, size = 20) => {
  const tint = t.tint;
  return `<div style="width:${size}px;height:${size}px;border-radius:999px;background:${alpha(tint, 0.16)};display:flex;align-items:center;justify-content:center;flex:none">${glyph(t, Math.round(size * 0.62), tint)}</div>`;
};

// TagChip as built: pill (icon+label) | circle (icon only) | label only.
const tagChip = (t, { selected = false, height = 36, close = false, plain = false } = {}) => {
  const tint = t.tint;
  const bg = selected ? alpha(tint, 0.16) : C.scHigh;
  const fg = selected ? tint : C.onSurface;
  const border = selected ? `border:1px solid ${alpha(tint, 0.55)};` : '';
  const circle = (t.icon || t.emoji) && t.showLabel === false;
  if (circle) {
    return `<div style="width:${height}px;height:${height}px;border-radius:999px;background:${bg};${border}display:flex;align-items:center;justify-content:center;flex:none">${glyph(t, Math.round(height * 0.5), tint)}</div>`;
  }
  const icon = (t.icon || t.emoji) && !plain ? `${glyph(t, 15, tint)}` : '';
  const x = close ? ms('close', 14, C.onSurfaceVariant) : '';
  return `<div style="height:${height}px;padding:0 14px;border-radius:999px;background:${bg};${border}display:flex;align-items:center;gap:5px;flex:none;box-sizing:border-box">${icon}<span style="font-family:${INTER};font-size:12.5px;font-weight:600;color:${fg};white-space:nowrap">${t.name}</span>${x}</div>`;
};

// MetaChip as built: surfaceContainerHigh pill, 13×7, 16px primary icon.
const metaChip = (icon, label) =>
  `<div style="padding:7px 13px;border-radius:999px;background:${C.scHigh};display:flex;align-items:center;gap:5px;flex:none">${icon ? ms(icon, 16, C.primary) : ''}<span style="font-family:${INTER};font-size:12.5px;font-weight:500;color:${C.onSurface};white-space:nowrap">${label}</span></div>`;

const eyebrow = (text, extra = '') =>
  `<span style="font-family:${INTER};font-size:11px;font-weight:600;letter-spacing:0.9px;text-transform:uppercase;color:${C.onSurfaceVariant};${extra}">${text}</span>`;

const circleBtn = (icon, size = 36, color = C.onSurfaceVariant, iconSize = 19, bg = C.scHigh) =>
  `<div style="width:${size}px;height:${size}px;border-radius:999px;background:${bg};display:flex;align-items:center;justify-content:center;flex:none">${ms(icon, iconSize, color)}</div>`;

// ── Screen furniture ─────────────────────────────────────────────────────────
const header = () =>
  `<div style="display:flex;align-items:center;gap:8px;padding:0 20px;height:32px">${logo(28, C.primary)}<span style="font-family:${PJS};font-size:23px;font-weight:800;letter-spacing:-0.46px;color:${C.primary};line-height:1">MyReciBook</span></div>`;

const searchBar = () =>
  `<div style="margin:12px 20px 0;height:48px;padding:0 16px;border-radius:999px;background:${C.sc};display:flex;align-items:center;gap:8px;box-sizing:border-box">${ms('search', 20, C.onSurfaceVariant)}<span style="font-family:${INTER};font-size:14px;color:${C.onSurfaceVariant}">Search your cookbook…</span></div>`;

const navBar = () => `
<div style="position:absolute;left:0;right:0;bottom:0;padding:0 20px 16px;height:64px;box-sizing:content-box">
  <div style="position:relative;height:64px">
    <div style="position:absolute;left:0;right:0;bottom:0;height:56px;border-radius:999px;background:${C.glassFill};border:1px solid ${C.glassBorder};backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);display:flex;align-items:center;box-sizing:border-box">
      <div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:2px">${logo(22, C.primary, false)}<span style="font-family:${INTER};font-size:10.5px;font-weight:600;letter-spacing:0.2px;color:${C.primary}">Cookbook</span></div>
      <div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:2px">${ms('checklist', 22, C.onSurfaceVariant)}<span style="font-family:${INTER};font-size:10.5px;font-weight:600;letter-spacing:0.2px;color:${C.onSurfaceVariant}">Grocery</span></div>
      <div style="width:60px;flex:none"></div>
      <div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:2px">${ms('restaurant', 22, C.onSurfaceVariant)}<span style="font-family:${INTER};font-size:10.5px;font-weight:600;letter-spacing:0.2px;color:${C.onSurfaceVariant}">Food</span></div>
      <div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:2px">${ms('settings', 22, C.onSurfaceVariant)}<span style="font-family:${INTER};font-size:10.5px;font-weight:600;letter-spacing:0.2px;color:${C.onSurfaceVariant}">Settings</span></div>
    </div>
    <div style="position:absolute;left:50%;top:0;margin-left:-26px;width:52px;height:52px;border-radius:999px;background:linear-gradient(135deg,${C.primaryContainer},${C.primary});box-shadow:0 8px 16px 2px rgba(63,81,181,0.45);display:flex;align-items:center;justify-content:center">${ms('add', 24, C.onPrimary)}</div>
  </div>
</div>`;

// ── Data — the real library from the phone, gradient covers standing in ──────
const T = {
  fav:       { name: 'Favorites', icon: 'favorite', fill: true, tint: C.tertiary },
  weeknight: { name: 'Weeknight', icon: 'bolt', tint: TINT.amber },
  candy:     { name: 'Candy', emoji: '🍬', tint: TINT.red },
  pizza:     { name: 'Pizza', icon: 'local_pizza', tint: TINT.orange, showLabel: false },
  dessert:   { name: 'Dessert', icon: 'cake', tint: TINT.purple },
};
const R = [
  { t: 'Easy Sheet-Pan Apricot-Glazed Chicken', m: '50 min · 6', g: 'terracotta', tags: ['weeknight', 'fav'] },
  { t: 'Freezer Pancakes Are the Easiest Make-Ahead Breakfast', m: '4 hr 55 min · 6', g: 'olive', tags: ['weeknight'] },
  { t: 'Homemade Bounty Bars', m: '2 hr 15 min · 18', g: 'plum', tags: ['candy', 'dessert', 'fav'] },
  { t: 'White chocolate and rhubarb muffins', m: '22–25 minutes · 12 muffins', g: 'teal', tags: ['dessert'] },
  { t: 'Tomato and Cottage Cheese Sandwich', m: '5 min · 2', g: 'indigo', tags: ['weeknight'] },
  { t: 'Lemon-Blueberry Tiramisu', m: '8 hr 15 min · 12', g: 'slate', tags: ['dessert', 'fav'] },
  { t: 'Havregryn classic', m: '1 serving', g: 'olive', tags: ['weeknight'] },
  { t: 'These Bacon-Egg-Cheese-Potato Burritos Are the Best', m: '1 hr · 10', g: 'terracotta', tags: ['weeknight', 'fav'] },
  { t: 'Chicken, Corn & Black Bean Enchiladas Are Full of Fiber', m: '1 hr 15 min · 8', g: 'plum', tags: [] },
  { t: 'Creamed Spinach Chicken Breasts', m: '', g: 'indigo', tags: ['weeknight'] },
  { t: 'French Onion Mashed Potatoes', m: '1 hr 40 min · 6', g: 'teal', tags: [] },
  { t: 'Margherita from scratch', m: '1 hr 30 min · 2 pizzas', g: 'slate', tags: ['pizza'] },
];
const recipesOf = (key) => R.filter((r) => r.tags.includes(key));

// Recipe card as built: 154×172, cover 106, padding 11/9/11/11.
const recipeCard = (r) => `
<div style="width:154px;height:172px;border-radius:12px;background:${C.white};border:1px solid ${C.hairline};box-shadow:${C.cardShadow};overflow:hidden;box-sizing:border-box;display:flex;flex-direction:column">
  ${cover(r.g, '100%', '106px', 40)}
  <div style="padding:9px 11px 11px;display:flex;flex-direction:column;gap:3px">
    <span style="font-family:${INTER};font-size:13.5px;font-weight:600;line-height:1.3;color:${C.onSurface};display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden">${r.t}</span>
    ${r.m ? `<span style="font-family:${INTER};font-size:11.5px;color:${C.onSurfaceVariant};white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${r.m}</span>` : ''}
  </div>
</div>`;

const grid = (rs) =>
  `<div style="display:grid;grid-template-columns:repeat(2, minmax(0, 1fr));gap:12px;padding:0 20px">${rs.map(recipeCard).join('')}</div>`;

// The collage on a tag tile: the covers of its recipes, 2×2 at most.
const collage = (rs, w, h) => {
  const n = Math.min(rs.length, 4);
  const cell = (r, cw, ch) => cover(r.g, cw, ch, 16);
  if (n >= 4) return `<div style="width:${w}px;height:${h}px;display:grid;grid-template-columns:repeat(2, minmax(0, 1fr));grid-template-rows:repeat(2, minmax(0, 1fr));gap:1px;background:${C.white}">${rs.slice(0, 4).map((r) => cell(r, '100%', '100%')).join('')}</div>`;
  if (n === 3) return `<div style="width:${w}px;height:${h}px;display:grid;grid-template-columns:repeat(2, minmax(0, 1fr));gap:1px;background:${C.white}">${cell(rs[0], '100%', '100%')}<div style="display:grid;grid-template-rows:repeat(2, minmax(0, 1fr));gap:1px">${cell(rs[1], '100%', '100%')}${cell(rs[2], '100%', '100%')}</div></div>`;
  if (n === 2) return `<div style="width:${w}px;height:${h}px;display:grid;grid-template-columns:repeat(2, minmax(0, 1fr));gap:1px;background:${C.white}">${cell(rs[0], '100%', '100%')}${cell(rs[1], '100%', '100%')}</div>`;
  return `<div style="width:${w}px;height:${h}px">${cell(rs[0], '100%', '100%')}</div>`;
};

// A tag tile: collage + badge + name + count. Selected = 1.5px tint + glow.
const tile = (key, selected = false) => {
  const t = T[key];
  const rs = recipesOf(key);
  const n = rs.length;
  const border = selected ? `border:1.5px solid ${t.tint};box-shadow:0 0 12px 2px ${alpha(t.tint, 0.18)};` : `border:1px solid ${C.hairline};box-shadow:${C.cardShadow};`;
  return `
<div style="width:120px;flex:none;border-radius:12px;background:${C.white};${border}overflow:hidden;box-sizing:border-box;display:flex;flex-direction:column">
  ${collage(rs, 118, 72)}
  <div style="padding:8px 10px 10px;display:flex;flex-direction:column;gap:3px">
    <div style="display:flex;align-items:center;gap:6px">${tagBadge(t, 20)}<span style="font-family:${INTER};font-size:12.5px;font-weight:600;color:${selected ? t.tint : C.onSurface};white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${t.name}</span></div>
    <span style="font-family:${INTER};font-size:11px;color:${C.onSurfaceVariant};padding-left:26px">${n} recipe${n === 1 ? '' : 's'}</span>
  </div>
</div>`;
};

const newTile = () => `
<div style="width:120px;height:130px;flex:none;border-radius:12px;border:1px dashed ${alpha(C.outline, 0.6)};box-sizing:border-box;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:6px">
  ${ms('add', 22, C.primary)}<span style="font-family:${INTER};font-size:12.5px;font-weight:600;color:${C.primary}">New tag</span>
</div>`;

const tagStrip = (selectedKey = null) => `
<div style="margin-top:14px;padding:0 20px;display:flex;align-items:center;justify-content:space-between;height:16px">${eyebrow('Your tags · 4')}</div>
<div style="margin-top:6px;padding:4px 0 6px 20px;overflow:hidden">
  <div style="display:flex;gap:10px;align-items:stretch;padding-right:20px;${selectedKey === 'dessert' ? 'margin-left:-390px;' : ''}">
    ${['fav', 'weeknight', 'candy', 'pizza', 'dessert'].map((k) => tile(k, k === selectedKey)).join('')}${newTile()}
  </div>
</div>`;

// ── Shared shell for a .dc.html artboard ─────────────────────────────────────
const helmet = () => `
<helmet>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&amp;family=Inter:wght@400;500;600;700&amp;family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&amp;display=block">
  <style>
    body { margin: 0; background: ${C.scaffold}; font-family: ${INTER}; color: ${C.onSurface}; }
    a { color: ${C.primary}; } a:hover { color: ${C.primaryContainer}; }
    .ms { font-family: 'Material Symbols Rounded'; font-weight: normal; font-style: normal; line-height: 1; letter-spacing: normal; text-transform: none; display: inline-block; white-space: nowrap; word-wrap: normal; direction: ltr; -webkit-font-smoothing: antialiased; font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24; flex: none; text-align: center; }
    .ms.f { font-variation-settings: 'FILL' 1, 'wght' 400, 'GRAD' 0, 'opsz' 24; }
  </style>
</helmet>`;

const page = (body) => `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>${helmet()}
${body}
</x-dc>
</body>
</html>
`;

const phone = (inner, bg = C.scaffold) =>
  `<div style="width:360px;height:800px;background:${bg};position:relative;overflow:hidden;box-sizing:border-box">${inner}</div>`;

// ── A1 · Cookbook ────────────────────────────────────────────────────────────
const cookbook = (selectedKey = null) => {
  const rs = selectedKey ? recipesOf(selectedKey) : R;
  const t = selectedKey ? T[selectedKey] : null;
  const gridHead = selectedKey
    ? `<div style="margin-top:14px;padding:0 20px;display:flex;align-items:center;gap:10px;height:36px">
         ${tagChip(t, { selected: true, close: true })}
         <span style="font-family:${INTER};font-size:12px;color:${C.onSurfaceVariant}">${rs.length} recipes</span>
         <span style="font-family:${INTER};font-size:13px;font-weight:600;color:${C.primary};margin-left:2px">Edit tag</span>
         <div style="flex:1"></div>
         ${circleBtn('view_list', 36)}
       </div>`
    : `<div style="margin-top:14px;padding:0 20px;display:flex;align-items:center;justify-content:space-between;height:36px">
         ${eyebrow('All recipes · 12')}
         ${circleBtn('view_list', 36)}
       </div>`;
  return phone(`
<div style="padding-top:36px;display:flex;flex-direction:column">
  ${header()}
  ${searchBar()}
  ${tagStrip(selectedKey)}
  ${gridHead}
  <div style="margin-top:10px">${grid(rs)}</div>
</div>
${navBar()}`);
};

// ── A3 · Tag sheet over the filtered cookbook ────────────────────────────────
const colorDots = (chosen) => Object.entries(TINT).map(([k, v]) =>
  `<div style="width:32px;height:32px;border-radius:999px;background:${v};flex:none;display:flex;align-items:center;justify-content:center;${k === chosen ? `outline:2.5px solid ${C.onSurface};outline-offset:-2.5px` : ''}">${k === chosen ? ms('check', 18, '#FFFFFF') : ''}</div>`).join('');

const iconTile = (name, tint, selected = false) =>
  `<div style="width:44px;height:44px;border-radius:12px;background:${selected ? C.secondaryContainer : C.scHigh};${selected ? `border:1.5px solid ${C.primary};` : ''}box-sizing:border-box;display:flex;align-items:center;justify-content:center">${ms(name, 21, tint)}</div>`;

const iconGrid = (names, tint, selectedName) =>
  `<div style="display:grid;grid-template-columns:repeat(6, minmax(0, 1fr));gap:8px">${names.map((n) => iconTile(n, tint, n === selectedName)).join('')}</div>`;

const DISHES = ['local_pizza', 'dinner_dining', 'ramen_dining', 'rice_bowl', 'soup_kitchen', 'lunch_dining', 'restaurant', 'breakfast_dining', 'brunch_dining', 'kebab_dining', 'tapas', 'set_meal', 'bakery_dining', 'fastfood', 'takeout_dining', 'cake', 'cookie', 'icecream'];
const INGREDIENTS = ['egg', 'egg_alt', 'grain', 'grass', 'local_florist', 'eco'];

const tagSheet = () => {
  const t = T.dessert;
  const tint = t.tint;
  const label = (txt) => `<span style="font-family:${INTER};font-size:11px;font-weight:600;letter-spacing:0.9px;text-transform:uppercase;color:${C.onSurfaceVariant}">${txt}</span>`;
  const sheet = `
<div style="position:absolute;left:0;right:0;top:118px;bottom:0;background:${C.white};border-radius:24px 24px 0 0;box-shadow:${C.modalShadow};overflow:hidden;display:flex;flex-direction:column">
  <div style="height:24px;display:flex;align-items:center;justify-content:center;flex:none"><div style="width:32px;height:4px;border-radius:999px;background:${C.outlineVariant}"></div></div>
  <div style="flex:1;overflow:hidden;padding:4px 20px 0;display:flex;flex-direction:column;gap:14px">
    <div style="display:flex;align-items:center;justify-content:space-between;height:36px">
      ${tagChip(t, { selected: true })}
      <span style="font-family:${INTER};font-size:12px;color:${C.onSurfaceVariant}">on 3 recipes</span>
    </div>
    <div style="position:relative;height:52px;border:1px solid ${C.outline};border-radius:8px;box-sizing:border-box;display:flex;align-items:center;padding:0 14px">
      <span style="position:absolute;left:10px;top:-7px;padding:0 4px;background:${C.white};font-family:${INTER};font-size:11px;color:${C.onSurfaceVariant}">Name</span>
      <span style="font-family:${INTER};font-size:14px;color:${C.onSurface}">Dessert</span>
    </div>
    <div style="display:flex;align-items:center;justify-content:space-between;gap:12px">
      <div style="display:flex;flex-direction:column;gap:2px">
        <span style="font-family:${INTER};font-size:14px;color:${C.onSurface}">Show the name</span>
        <span style="font-family:${INTER};font-size:12px;color:${C.onSurfaceVariant}">A pill with the icon and the name</span>
      </div>
      <div style="width:52px;height:32px;border-radius:999px;background:${C.primary};position:relative;flex:none"><div style="position:absolute;right:4px;top:4px;width:24px;height:24px;border-radius:999px;background:${C.white};display:flex;align-items:center;justify-content:center">${ms('check', 16, C.primary)}</div></div>
    </div>
    <div style="display:flex;flex-direction:column;gap:10px">
      ${label('Colour')}
      <div style="display:flex;gap:9px">${colorDots('purple')}</div>
    </div>
    <div style="display:flex;flex-direction:column;gap:12px">
      ${label('Icon')}
      <div style="display:flex;align-items:center;justify-content:space-between">
        <div style="display:flex;height:40px;border:1px solid ${C.outline};border-radius:999px;overflow:hidden;box-sizing:border-box">
          <div style="padding:0 18px;display:flex;align-items:center;background:${C.secondaryContainer}"><span style="font-family:${INTER};font-size:14px;font-weight:600;color:${C.onSecondaryContainer}">Icons</span></div>
          <div style="padding:0 18px;display:flex;align-items:center;border-left:1px solid ${C.outline}"><span style="font-family:${INTER};font-size:14px;font-weight:600;color:${C.onSurface}">Emoji</span></div>
        </div>
        <div style="display:flex;align-items:center;gap:6px">${ms('backspace', 18, C.primary)}<span style="font-family:${INTER};font-size:13px;font-weight:600;color:${C.primary}">No icon</span></div>
      </div>
      ${label('Dishes')}
      ${iconGrid(DISHES, tint, 'cake')}
      ${label('Ingredients')}
      ${iconGrid(INGREDIENTS, tint, '')}
    </div>
  </div>
  <div style="flex:none;padding:12px 20px 16px;background:linear-gradient(180deg, rgba(255,255,255,0) 0%, ${C.white} 30%);display:flex;align-items:center;justify-content:space-between">
    <span style="font-family:${INTER};font-size:13px;font-weight:600;color:${C.error}">Delete tag</span>
    <div style="height:48px;padding:0 32px;border-radius:999px;background:${C.primary};display:flex;align-items:center;justify-content:center"><span style="font-family:${INTER};font-size:14px;font-weight:600;color:${C.onPrimary}">Save</span></div>
  </div>
</div>`;
  return phone(`
<div style="padding-top:36px;display:flex;flex-direction:column">
  ${header()}
  ${searchBar()}
  ${tagStrip('dessert')}
</div>
${navBar()}
<div style="position:absolute;inset:0;background:${C.scrim}"></div>
${sheet}`);
};

// ── A4 · Rescue review with suggested tags ───────────────────────────────────
const review = () => {
  const suggestion = (name) =>
    `<div style="height:32px;padding:0 12px 0 10px;border-radius:999px;background:${alpha(C.secondaryContainer, 0.3)};display:flex;align-items:center;gap:4px;flex:none">${ms('add', 15, C.onSecondaryContainer)}<span style="font-family:${INTER};font-size:12.5px;font-weight:500;color:${C.onSecondaryContainer};white-space:nowrap">${name}</span></div>`;
  const ingredient = (qty, rest, last = false) =>
    `<div style="height:44px;display:flex;align-items:center;${last ? '' : `border-bottom:1px solid ${C.separator};`}"><span style="font-family:${INTER};font-size:14px;color:${C.onSurface}"><b style="font-weight:600">${qty}</b> ${rest}</span></div>`;
  const card = (inner, pad = '12px') => `<div style="background:${C.white};border:1px solid ${C.hairline};border-radius:12px;box-shadow:${C.cardShadow};padding:${pad};box-sizing:border-box">${inner}</div>`;
  return phone(`
<div style="padding-top:36px;display:flex;flex-direction:column">
  <div style="display:flex;align-items:center;gap:14px;padding:0 14px;height:48px">${ms('arrow_back', 22, C.onSurface)}<span style="font-family:${PJS};font-size:18px;font-weight:700;color:${C.onSurface}">Recipe rescued</span>${ms('check', 18, '#22C55E')}</div>
  <div style="padding:4px 20px 0;display:flex;flex-direction:column;gap:12px">
    <div style="display:flex;align-items:center;gap:12px">
      ${stripes('52px', '76px', 'border-radius:8px')}
      <div style="flex:1;display:flex;flex-direction:column;gap:2px">
        <span style="font-family:${INTER};font-size:14px;font-weight:600;color:${C.onSurface}">Original screenshot</span>
        <span style="font-family:${INTER};font-size:12px;color:${C.onSurfaceVariant}">tap to see what we read</span>
      </div>
      ${circleBtn('swap_horiz', 40, C.onSurfaceVariant, 20)}
    </div>
    ${card(`<div style="display:flex;align-items:center;gap:12px">${circleBtn('add_a_photo', 40, C.primary, 20, C.scHigh)}<div style="display:flex;flex-direction:column;gap:2px"><span style="font-family:${INTER};font-size:14px;font-weight:600;color:${C.onSurface}">Add a cover</span><span style="font-family:${INTER};font-size:12px;color:${C.onSurfaceVariant}">Optional — a photo you pick</span></div></div>`, '10px 12px')}
    ${card(`<div style="display:flex;align-items:center;gap:8px"><span style="flex:1;font-family:${PJS};font-size:18px;font-weight:700;color:${C.onSurface}">Lemon-Blueberry Tiramisu</span>${ms('edit', 19, C.onSurfaceVariant)}</div>`, '12px 14px')}
    <div style="display:flex;gap:8px;flex-wrap:wrap">${metaChip('restaurant', 'Serves 12')}${metaChip('schedule', 'Total 8 hr 15 min')}</div>
  </div>
  <div style="padding:14px 20px 0;display:flex;flex-direction:column;gap:8px">
    ${eyebrow('Tags · 1')}
    <div style="display:flex;gap:8px;flex-wrap:wrap;align-items:center">
      ${tagChip(T.dessert, { height: 32, close: true })}
      <div style="height:32px;padding:0 12px;border-radius:999px;border:1px solid ${alpha(C.outline, 0.6)};box-sizing:border-box;display:flex;align-items:center;gap:4px">${ms('add', 15, C.primary)}<span style="font-family:${INTER};font-size:12.5px;font-weight:600;color:${C.primary}">Tag</span></div>
    </div>
    <span style="margin-top:4px;font-family:${INTER};font-size:12px;color:${C.onSurfaceVariant}">From the site — tap one to keep it</span>
    <div style="display:flex;gap:8px;flex-wrap:wrap">${['American', 'Side Dish', 'Holiday', 'Make-ahead', 'Summer'].map(suggestion).join('')}</div>
  </div>
  <div style="padding:14px 20px 0;display:flex;flex-direction:column;gap:8px">
    ${eyebrow('Ingredients · 8')}
    ${card(`${ingredient('500 g', 'mascarpone')}${ingredient('300 ml', 'double cream')}${ingredient('200 g', 'blueberries')}${ingredient('2', 'lemons, zest and juice', true)}`, '2px 14px')}
  </div>
</div>`);
};

// ── Low-fi alternates ────────────────────────────────────────────────────────
const W = { line: '#C5C5D4', box: '#E8E8EA', ink: '#1A1C1E', dim: '#757684' };
const wf = (inner) => phone(`<div style="padding:36px 20px 0;display:flex;flex-direction:column;gap:12px;font-family:${INTER};color:${W.ink}">${inner}</div>`, '#FFFFFF');
const wbox = (h, txt = '', extra = '') => `<div style="height:${h}px;border:1px solid ${W.line};border-radius:12px;background:${W.box};display:flex;align-items:center;justify-content:center;font-size:12px;color:${W.dim};box-sizing:border-box;${extra}">${txt}</div>`;
const wchip = (txt, on = false) => `<div style="height:36px;padding:0 14px;border-radius:999px;border:1px solid ${on ? W.ink : W.line};background:${on ? W.ink : '#FFFFFF'};color:${on ? '#FFFFFF' : W.ink};display:flex;align-items:center;font-size:12.5px;font-weight:600;flex:none;box-sizing:border-box;white-space:nowrap">${txt}</div>`;
const wcard = () => `<div style="height:150px;border:1px solid ${W.line};border-radius:12px;overflow:hidden;box-sizing:border-box;display:flex;flex-direction:column"><div style="height:92px;background:${W.box}"></div><div style="padding:8px 10px;display:flex;flex-direction:column;gap:6px"><div style="height:10px;width:80%;background:${W.line};border-radius:4px"></div><div style="height:8px;width:45%;background:${W.box};border-radius:4px"></div></div></div>`;
const wgrid = (n) => `<div style="display:grid;grid-template-columns:repeat(2, minmax(0, 1fr));gap:12px">${Array.from({ length: n }, wcard).join('')}</div>`;
const wtitle = (txt) => `<div style="font-family:${PJS};font-size:23px;font-weight:800;color:${W.ink}">${txt}</div>`;

const optionB = () => wf(`
${wtitle('MyReciBook')}
${wbox(48, 'Search your cookbook…', 'border-radius:999px;justify-content:flex-start;padding-left:16px')}
<div style="display:flex;gap:8px;overflow:hidden;align-items:center">${wchip('All', true)}${wchip('♥ Favorites')}${wchip('⚡ Weeknight')}${wchip('Candy')}${wchip('Pizza')}${wchip('Dessert')}${wchip('⋯')}</div>
<div style="font-size:11px;font-weight:600;letter-spacing:0.9px;color:${W.dim}">ALL RECIPES · 12</div>
${wgrid(6)}
<div style="position:absolute;left:20px;right:20px;bottom:16px;height:56px;border:1px solid ${W.line};border-radius:999px;background:#FFFFFF;display:flex;align-items:center;justify-content:space-around;font-size:10.5px;color:${W.dim}"><span>Cookbook</span><span>Grocery</span><span style="width:52px;height:52px;border-radius:999px;background:${W.ink};color:#fff;display:flex;align-items:center;justify-content:center;font-size:22px">+</span><span>Food</span><span>Settings</span></div>
`);

const wrow = (name, n) => `<div style="height:64px;display:flex;align-items:center;gap:12px;border-bottom:1px solid ${W.line}"><div style="width:36px;height:36px;border-radius:999px;background:${W.box};flex:none"></div><div style="flex:1;display:flex;flex-direction:column;gap:3px"><span style="font-size:15px;font-weight:600">${name}</span><span style="font-size:12px;color:${W.dim}">${n} recipes</span></div><div style="display:flex;gap:-6px">${[0, 1, 2].map((i) => `<div style="width:30px;height:30px;border-radius:8px;background:${W.box};border:1px solid #fff;margin-left:${i ? '-8px' : '0'}"></div>`).join('')}</div><span style="color:${W.dim};font-size:18px">›</span></div>`;

const optionC = () => wf(`
${wtitle('MyReciBook')}
${wbox(48, 'Search your cookbook…', 'border-radius:999px;justify-content:flex-start;padding-left:16px')}
<div style="border:1px solid ${W.line};border-radius:12px;padding:0 12px;background:#FFFFFF">
  ${wrow('Everything', 12)}${wrow('Favorites', 4)}${wrow('Weeknight', 6)}${wrow('Dessert', 3)}${wrow('Candy', 1)}${wrow('Pizza', 1)}
  <div style="height:56px;display:flex;align-items:center;gap:12px"><div style="width:36px;height:36px;border-radius:999px;border:1px dashed ${W.dim};flex:none;display:flex;align-items:center;justify-content:center;font-size:20px;color:${W.dim}">+</div><span style="font-size:14px;font-weight:600">New tag</span></div>
</div>
<div style="font-size:11px;font-weight:600;letter-spacing:0.9px;color:${W.dim}">RECENTLY RESCUED</div>
<div style="display:flex;gap:12px;overflow:hidden">${Array.from({ length: 3 }, () => `<div style="width:154px;flex:none">${wcard()}</div>`).join('')}</div>
<div style="position:absolute;left:20px;right:20px;bottom:16px;height:56px;border:1px solid ${W.line};border-radius:999px;background:#FFFFFF;display:flex;align-items:center;justify-content:space-around;font-size:10.5px;color:${W.dim}"><span>Cookbook</span><span>Grocery</span><span style="width:52px;height:52px;border-radius:999px;background:${W.ink};color:#fff;display:flex;align-items:center;justify-content:center;font-size:22px">+</span><span>Food</span><span>Settings</span></div>
`);

// ── Emit ─────────────────────────────────────────────────────────────────────
writeFileSync('Main.dc.html', page(cookbook()));
writeFileSync('Filtered.dc.html', page(cookbook('dessert')));
writeFileSync('TagSheet.dc.html', page(tagSheet()));
writeFileSync('Review.dc.html', page(review()));
writeFileSync('RailOption.dc.html', page(optionB()));
writeFileSync('ContentsOption.dc.html', page(optionC()));

const canvas = {
  artboards: [
    { file: 'Main.dc.html', title: 'A · Cookbook', x: 0, y: 0, w: 360, h: 800 },
    { file: 'Filtered.dc.html', title: 'A · Dessert selected', x: 440, y: 0, w: 360, h: 800 },
    { file: 'TagSheet.dc.html', title: 'A · Tag sheet', x: 880, y: 0, w: 360, h: 800 },
    { file: 'Review.dc.html', title: 'A · Rescue review', x: 1320, y: 0, w: 360, h: 800 },
    { file: 'RailOption.dc.html', title: 'B · Rail (low-fi)', x: 0, y: 1080, w: 360, h: 800 },
    { file: 'ContentsOption.dc.html', title: 'C · Contents (low-fi)', x: 440, y: 1080, w: 360, h: 800 },
  ],
  annotations: [
    { id: 'note-a', x: 0, y: -200, w: 800, text: 'Direction A — built out.\nOne grid, always. Untagged recipes never sit on top of tagged ones.\nYour tags are tiles above the grid: your icon, your colour, the covers of the recipes inside.\nTap a tile to filter in place. Tap the × to clear.\nManage a tag where you see it: "Edit tag" on the filtered header, or the + tile. Settings → Tags goes away.' },
    { id: 'note-sheet', x: 880, y: -140, w: 360, text: 'One sheet replaces the list page and the editor page.\nSame icons, colours and name toggle you liked — one tap closer.' },
    { id: 'note-review', x: 1320, y: -170, w: 360, text: 'Import: nothing lands untapped.\nThe site\'s categories come in as suggestions under the tags row.\nTap one to keep it. Leave it and it is never saved.\nA suggestion that matches one of your tags wears that tag\'s colour and icon, so it never becomes a duplicate.' },
    { id: 'note-b', x: 0, y: 940, w: 360, text: 'Direction B — the rail.\nCheapest: today\'s chips, one grid, filter in place. Manage from the ⋯ at the end of the rail.\nTrade-off: a long rail hides tags off-screen, and tags stay small.' },
    { id: 'note-c', x: 440, y: 940, w: 360, text: 'Direction C — a table of contents.\nThe cookbook opens as a list of your tags with counts. Tap one for its grid.\nMost book-like. Trade-off: one more tap to every recipe.' },
  ],
  launch: { view: 'canvas' },
};
writeFileSync('canvas.json', JSON.stringify(canvas, null, 2));
console.log('ok');
