#!/usr/bin/env node
/**
 * Browser end-to-end smoke test for the Flutter Web build.
 *
 * Every tool that runs in the browser is exercised through the real UI:
 * pick a file -> press start -> wait for the task to finish -> download the
 * result -> verify the file signature AND that compression kept the input
 * format. This is the regression net for the class of bug that shipped twice
 * already (the file-picker TypeError, and PNG being silently re-encoded as
 * JPEG by the compression tool).
 *
 * The app is a single Flutter scroll view, so targets below the fold are wheeled
 * into view before they are clicked, and each case asserts that the workspace
 * actually switched to the tool under test (a missed tile click used to run the
 * whole case against the default tool).
 *
 * Usage:
 *   node tool/e2e/web_smoke.js [--dir build/web] [--out .work/e2e] [--headed]
 *
 * Requires `playwright-core` plus an installed Chromium/Edge. Set
 * `PLAYWRIGHT_CORE_PATH` to override module resolution, or run from a
 * directory that already has it in `node_modules`.
 */

'use strict';

const fs = require('fs');
const http = require('http');
const path = require('path');

function loadPlaywright() {
  const candidates = [
    process.env.PLAYWRIGHT_CORE_PATH,
    'playwright-core',
    'playwright',
  ].filter(Boolean);
  for (const candidate of candidates) {
    try {
      return require(candidate);
    } catch (error) {
      /* try the next candidate */
    }
  }
  throw new Error(
    'playwright-core is not resolvable. Set PLAYWRIGHT_CORE_PATH to its directory.',
  );
}

const { chromium } = loadPlaywright();

const args = process.argv.slice(2);
function flag(name, fallback) {
  const index = args.indexOf(`--${name}`);
  if (index === -1) return fallback;
  const value = args[index + 1];
  return value && !value.startsWith('--') ? value : true;
}

const buildDir = path.resolve(String(flag('dir', 'build/web')));
const outDir = path.resolve(String(flag('out', '.work/e2e')));
const headed = args.includes('--headed');
const baseHref = '/app/';

if (!fs.existsSync(path.join(buildDir, 'main.dart.js'))) {
  throw new Error(`no Flutter Web build at ${buildDir} (expected main.dart.js)`);
}
fs.mkdirSync(outDir, { recursive: true });

// ---------------------------------------------------------------------------
// Samples: generated in-process so the test owns its fixtures.
// ---------------------------------------------------------------------------

// Samples are generated in-process so the test owns its fixtures. Both were
// verified against package:image 4.5.4 and Node (identical decoded byte counts),
// because a subtly corrupt base64 is indistinguishable from a broken engine: the
// PNG below has a transparent quadrant so PNG -> JPEG must also flatten alpha.
//
// 8x8 RGBA PNG: rgb(220,40,60) with the top-right 4x4 quadrant at alpha 0.
const PNG_SAMPLE = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAJElEQVR42mO8o2HznwEJqNw4wojMZ2IgAChXwIjuBupbQVABACWfBk51skGuAAAAAElFTkSuQmCC',
  'base64',
);
// 8x8 baseline 4:4:4 JPEG, quality 90: blue field with a yellow 4x4 block.
const JPEG_SAMPLE = Buffer.from(
  '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAAIAAgDAREAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAAA//EACEQAAAFAgcAAAAAAAAAAAAAAAcREhMVAAIUFyUxRGFi/8QAFQEBAQAAAAAAAAAAAAAAAAAABgf/xAAmEQACAQEECwAAAAAAAAAAAAAREhMGAAEHYQIUFRchIyRBQkNi/9oADAMBAAIRAxEAPwBAfB/NeX1eLwDPGecWv3aRI73pjiZiZu61Po555PYionxpkvkB3PCTU7Tu3peaiL4kk53AC3//2Q==',
  'base64',
);

const samples = {
  png: path.join(outDir, 'sample.png'),
  jpg: path.join(outDir, 'sample.jpg'),
};
fs.writeFileSync(samples.png, PNG_SAMPLE);
fs.writeFileSync(samples.jpg, JPEG_SAMPLE);

// ---------------------------------------------------------------------------
// Static server that mounts the build at the same base href the site uses.
// ---------------------------------------------------------------------------

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.frag': 'application/octet-stream',
  '.symbols': 'application/octet-stream',
};

function startServer() {
  const server = http.createServer((request, response) => {
    const url = new URL(request.url, 'http://127.0.0.1');
    let pathname = decodeURIComponent(url.pathname);
    if (pathname === '/') pathname = baseHref;
    if (!pathname.startsWith(baseHref)) {
      response.writeHead(404).end('not found');
      return;
    }
    let relative = pathname.slice(baseHref.length);
    if (relative === '' || relative.endsWith('/')) relative += 'index.html';
    const target = path.join(buildDir, relative);
    if (!target.startsWith(buildDir) || !fs.existsSync(target) || fs.statSync(target).isDirectory()) {
      response.writeHead(404).end('not found');
      return;
    }
    response.writeHead(200, {
      'content-type': MIME[path.extname(target).toLowerCase()] || 'application/octet-stream',
      'cache-control': 'no-store',
    });
    fs.createReadStream(target).pipe(response);
  });
  return new Promise((resolve) => {
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

// ---------------------------------------------------------------------------
// Flutter semantics driving helpers
// ---------------------------------------------------------------------------

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function enableSemantics(page) {
  await page.waitForFunction(
    () =>
      !!document.querySelector('flt-semantics-placeholder') ||
      document.querySelectorAll('flt-semantics').length > 3,
    null,
    { timeout: 90_000 },
  );
  if ((await page.evaluate(() => document.querySelectorAll('flt-semantics').length)) > 3) return;
  for (let attempt = 0; attempt < 8; attempt += 1) {
    await page.evaluate(() => {
      const placeholder = document.querySelector('flt-semantics-placeholder');
      if (!placeholder) return;
      Object.assign(placeholder.style, {
        left: '80px',
        top: '80px',
        width: '160px',
        height: '80px',
        zIndex: '99999',
        opacity: '0.01',
      });
    });
    await page.mouse.click(120, 110);
    await page.waitForTimeout(1200);
    if ((await page.evaluate(() => document.querySelectorAll('flt-semantics').length)) > 3) return;
  }
  throw new Error('could not enable the Flutter semantics tree');
}

async function snapshot(page) {
  return page.evaluate(() =>
    [...document.querySelectorAll('flt-semantics')].map((node) => {
      const rect = node.getBoundingClientRect();
      return {
        role: node.getAttribute('role') || '',
        label: node.getAttribute('aria-label') || '',
        text: (node.textContent || '').trim(),
        x: rect.x,
        y: rect.y,
        w: rect.width,
        h: rect.height,
      };
    }),
  );
}

async function pageText(page) {
  return (await snapshot(page))
    .map((node) => `${node.label} ${node.text}`)
    .join('\n');
}

// The app is one Flutter scroll view painted into a canvas, so the DOM cannot
// scroll a widget into view and a click at coordinates outside the viewport is
// silently dropped. That is exactly how the compression cases used to fail: the
// tool tile sits below the fold, the click did nothing, and the case then ran
// against the default tool while only reporting a wrong output. `clickText`
// therefore wheels the Flutter scroll view until the target is on screen.
function centreOf(node) {
  return { x: node.x + node.w / 2, y: node.y + node.h / 2 };
}

function isClickable(node, viewport, requireFull) {
  if (node.w <= 2 || node.h <= 2) return false;
  const centre = centreOf(node);
  const centreInside =
    centre.x > 1 &&
    centre.y > 1 &&
    centre.x < viewport.width - 1 &&
    centre.y < viewport.height - 1;
  if (!centreInside) return false;
  if (!requireFull) return true;
  // Flutter clips the reported rect of content scrolled out of view, so a rect
  // that merely touches the bottom edge may still be an off-screen widget:
  // demand the whole node before trusting the click.
  return (
    node.x >= 0 &&
    node.y >= 2 &&
    node.x + node.w <= viewport.width &&
    node.y + node.h <= viewport.height - 2
  );
}

async function wheelToward(page, node, viewport) {
  const centre = centreOf(node);
  const distance = centre.y - viewport.height / 2;
  const step = Math.sign(distance) * Math.min(Math.abs(distance), 600);
  await page.mouse.move(viewport.width / 2, viewport.height / 2);
  await page.mouse.wheel(0, step);
  await page.waitForTimeout(700);
}

async function clickText(page, needle, { optional = false, waitAfter = 1200, requireFull = false } = {}) {
  const viewport = page.viewportSize();
  for (let attempt = 0; attempt < 14; attempt += 1) {
    const nodes = await snapshot(page);
    // Smallest match = the leaf widget. Ancestor/container nodes inherit their
    // children's textContent, so a big container also "contains" the needle and
    // clicking its centre lands on whatever happens to be in the middle of the
    // page: never fall back to a larger node.
    const matches = nodes
      .filter((node) => `${node.label} ${node.text}`.includes(needle) && node.w > 2 && node.h > 2)
      .sort((left, right) => left.w * left.h - right.w * right.h);
    if (matches.length === 0) {
      await page.waitForTimeout(600);
      continue;
    }
    const target = matches[0];
    if (isClickable(target, viewport, requireFull)) {
      const centre = centreOf(target);
      await page.mouse.click(centre.x, centre.y);
      await page.waitForTimeout(waitAfter);
      return true;
    }
    await wheelToward(page, target, viewport);
  }
  if (optional) return false;
  throw new Error(`no clickable semantics node matching ${JSON.stringify(needle)}`);
}

async function gotoRoute(page, route) {
  await page.goto(`${page.__base}#${route}`, { waitUntil: 'load', timeout: 90_000 });
  await enableSemantics(page);
  await page.waitForTimeout(1200);
}

// ---------------------------------------------------------------------------
// Cases
// ---------------------------------------------------------------------------

const CASES = [
  {
    id: 'png_to_jpeg',
    toolLabel: 'PNG → JPEG',
    sample: 'png',
    extension: '.jpg',
    expect: { signature: '\xff\xd8\xff', note: 'JPEG' },
  },
  {
    id: 'jpg_to_png',
    // Must match tool/registry.json -> name.zh exactly, or the click silently
    // depends on a fallback that hides a renamed tile.
    toolLabel: 'JPEG → PNG',
    sample: 'jpg',
    extension: '.png',
    expect: { signature: '\x89PNG', note: 'PNG' },
  },
  {
    id: 'compress_png',
    toolLabel: '图片压缩',
    sample: 'png',
    extension: '.png',
    // Without this the case can silently run against the default tool when the
    // tile click misses, and only report a confusing output mismatch.
    workspaceMarker: '压缩档位',
    // The regression that matters: a PNG input must stay a PNG.
    expect: { signature: '\x89PNG', note: 'PNG (format preserved)' },
  },
  {
    id: 'compress_jpg',
    toolLabel: '图片压缩',
    sample: 'jpg',
    extension: '.jpg',
    workspaceMarker: '压缩档位',
    expect: { signature: '\xff\xd8\xff', note: 'JPEG (format preserved)' },
  },
  {
    id: 'image_to_pdf',
    toolLabel: '图片 → PDF',
    sample: 'png',
    extension: '.pdf',
    expect: { signature: '%PDF-', note: 'PDF' },
  },
];

async function runCase(page, testCase, results, logs) {
  const entry = { case: testCase.id, tool: testCase.toolLabel, ok: false, notes: [] };
  try {
    await gotoRoute(page, '/tools');
    const selected =
      (await clickText(page, testCase.toolLabel, { optional: true, requireFull: true })) ||
      (testCase.fallbackLabel
        ? await clickText(page, testCase.fallbackLabel, { optional: true, requireFull: true })
        : false);
    if (!selected) throw new Error(`tool tile ${testCase.toolLabel} is not reachable`);

    // A tile click that misses keeps the previously selected tool, so assert the
    // workspace really switched to the tool under test before uploading a file.
    if (testCase.workspaceMarker) {
      const selectedText = await pageText(page);
      if (!selectedText.includes(testCase.workspaceMarker)) {
        throw new Error(
          `tool ${testCase.toolLabel} does not look selected: no ` +
            `${JSON.stringify(testCase.workspaceMarker)} control on screen`,
        );
      }
    }

    const chooserPromise = page.waitForEvent('filechooser', { timeout: 20_000 });
    await clickText(page, '选择文件');
    const chooser = await chooserPromise;
    await chooser.setFiles(samples[testCase.sample]);
    await page.waitForTimeout(1500);

    await clickText(page, '开始处理');

    await page
      .waitForFunction(
        () =>
          /任务已完成|任务失败|已取消|处理失败/.test(
            [...document.querySelectorAll('flt-semantics')]
              .map((node) => `${node.getAttribute('aria-label') || ''} ${node.textContent || ''}`)
              .join(' '),
          ),
        null,
        { timeout: 120_000 },
      )
      .catch(() => {});

    const text = await pageText(page);
    // Deliberately narrow: a bare /已完成/ also matches the task-history rows on
    // other pages and would hide a run that never finished.
    if (!/任务已完成|处理完成/.test(text)) {
      entry.notes.push(`run did not report success: ${text.slice(0, 400)}`);
      await page.screenshot({ path: path.join(outDir, `${testCase.id}-failed.png`) });
      results.push(entry);
      return entry;
    }

    const downloadPromise = page.waitForEvent('download', { timeout: 30_000 }).catch(() => null);
    await clickText(page, '下载结果');
    const download = await downloadPromise;
    if (!download) {
      entry.notes.push('no download event fired');
      results.push(entry);
      return entry;
    }
    const target = path.join(outDir, `${testCase.id}${testCase.extension}`);
    await download.saveAs(target);
    const bytes = fs.readFileSync(target);
    entry.bytes = bytes.length;
    entry.savedName = download.suggestedFilename();
    entry.signature = bytes.subarray(0, 8).toString('latin1');
    const signatureOk = entry.signature.startsWith(testCase.expect.signature);
    const extensionOk = entry.savedName
      ? entry.savedName.toLowerCase().endsWith(testCase.extension)
      : true;
    entry.ok = signatureOk && entry.bytes > 0 && extensionOk;
    if (!signatureOk) {
      entry.notes.push(`expected ${testCase.expect.note} (${JSON.stringify(testCase.expect.signature)})`);
    }
    if (!extensionOk) {
      entry.notes.push(`downloaded file is named ${entry.savedName}, expected ${testCase.extension}`);
    }
    await page.screenshot({ path: path.join(outDir, `${testCase.id}.png`) });
  } catch (error) {
    entry.notes.push(`exception: ${error.message}`);
    await page.screenshot({ path: path.join(outDir, `${testCase.id}-error.png`) }).catch(() => {});
    await pageText(page)
      .then((text) => fs.writeFileSync(path.join(outDir, `${testCase.id}-error.txt`), text))
      .catch(() => {});
    // Node rects make a "the click went nowhere" failure diagnosable from the
    // uploaded artifact alone.
    await snapshot(page)
      .then((nodes) =>
        fs.writeFileSync(
          path.join(outDir, `${testCase.id}-semantics.json`),
          JSON.stringify(nodes, null, 2),
        ),
      )
      .catch(() => {});
  }
  results.push(entry);
  return entry;
}

(async () => {
  const server = await startServer();
  const { port } = server.address();
  const base = `http://127.0.0.1:${port}${baseHref}`;

  const results = [];
  const logs = [];
  const browser = await chromium.launch({ channel: 'msedge', headless: !headed }).catch(() =>
    chromium.launch({ headless: !headed }),
  );
  const context = await browser.newContext({
    viewport: { width: 1440, height: 1000 },
    acceptDownloads: true,
  });
  const page = await context.newPage();
  page.__base = base;
  page.on('console', (message) => {
    if (message.type() === 'error') logs.push(`[console.error] ${message.text()}`);
  });
  page.on('pageerror', (error) => logs.push(`[pageerror] ${error.message}`));

  for (const testCase of CASES) {
    const entry = await runCase(page, testCase, results, logs);
    console.log(`${entry.ok ? 'PASS' : 'FAIL'}  ${entry.case}  ${entry.notes.join('; ')}`);
  }

  fs.writeFileSync(path.join(outDir, 'results.json'), JSON.stringify(results, null, 2));
  fs.writeFileSync(path.join(outDir, 'console.log'), logs.join('\n'));

  await browser.close();
  server.close();

  const failed = results.filter((entry) => !entry.ok);
  if (failed.length > 0) {
    console.error(`\n${failed.length}/${results.length} browser tool cases failed`);
    process.exitCode = 1;
  } else {
    console.log(`\nall ${results.length} browser tool cases passed`);
  }
})().catch((error) => {
  console.error(error);
  fs.writeFileSync(path.join(outDir, 'fatal.txt'), String(error.stack || error));
  process.exit(1);
});