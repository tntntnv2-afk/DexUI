const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const NAMES = ["sprout","sword","swords","crosshair","map-pin","layout-grid","settings","star","search","x","minus","chevron-down","chevron-right","chevron-up","chevron-left","check","eye","eye-off","user","users","zap","shield","target","flame","skull","coins","clock","trophy","package","gem","heart","bell","info","triangle-alert","lock","lock-open","refresh-cw","play","pause","square","plus","copy","trash-2","folder","save","download","upload","palette","monitor","keyboard","mouse-pointer-2","wand-sparkles","bot","ghost","footprints","wind","axe","hammer","compass","globe","server","wifi","activity","chart-column","list","sliders-horizontal","toggle-right","sparkles","moon","sun","droplet","fish","tree-pine","mountain","cloud","store","shopping-cart","gift","crown","medal","book-open","scroll-text","message-square","link","external-link","log-out","power","rotate-ccw","maximize-2","minimize-2","grip-vertical","menu","filter","house","circle-help","circle-check","circle-x","flag","bomb","rocket","pickaxe","backpack","dices","sparkle","shirt","car","plane","anchor","bug","code","terminal","command","fingerprint","radar","scan","locate","navigation","route","timer","hourglass","calendar","award","badge-check","box","boxes","shuffle","repeat","infinity","skip-forward","fast-forward","mic","volume-2","volume-x","image","camera","video","music","gamepad-2","joystick"];
const SIZE = 64, COLS = 16;
(async () => {
  const dir = path.join(process.cwd(), 'node_modules/lucide-static/icons');
  const out = process.argv[2] || 'icons.png';
  const found = NAMES.filter(n => fs.existsSync(path.join(dir, n + '.svg')));
  const missing = NAMES.filter(n => !found.includes(n));
  if (missing.length) console.error('missing', missing.join(','));
  const rows = Math.ceil(found.length / COLS);
  let cells = '';
  found.forEach((n, i) => {
    let svg = fs.readFileSync(path.join(dir, n + '.svg'), 'utf8');
    svg = svg.replace(/<!--[\s\S]*?-->/g, '').replace(/width="24"/, `width="${SIZE - 8}"`).replace(/height="24"/, `height="${SIZE - 8}"`).replace(/stroke="currentColor"/, 'stroke="#ffffff"').replace(/stroke-width="2"/, 'stroke-width="2"');
    cells += `<div style="position:absolute;left:${(i % COLS) * SIZE + 4}px;top:${Math.floor(i / COLS) * SIZE + 4}px;width:${SIZE - 8}px;height:${SIZE - 8}px">${svg}</div>`;
  });
  const html = `<html><body style="margin:0;background:transparent"><div id="a" style="position:relative;width:${COLS * SIZE}px;height:${rows * SIZE}px">${cells}</div></body></html>`;
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: COLS * SIZE, height: rows * SIZE }, deviceScaleFactor: 1 });
  await page.setContent(html);
  await page.locator('#a').screenshot({ path: out, omitBackground: true });
  await browser.close();
  console.log('local ICON_NAMES = { ' + found.map(n => JSON.stringify(n)).join(', ') + ' }');
  console.log(found.length, 'icons', COLS * SIZE + 'x' + rows * SIZE);
})();
