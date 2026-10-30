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

async function clickText(page, needle, { optional = false, waitAfter = 1200 } = {}) {
  for (let attempt = 0; attempt < 6; attempt += 1) {
    const nodes = await snapshot(page);
    const matches = nodes
      .filter((node) => `${node.label} ${node.text}`.includes(needle) && node.w > 2 && node.h > 2)
      .sort((left, right) => left.w * left.h - right.w * right.h);
    if (matches.length > 0) {
      await page.mouse.click(matches[0].x + matches[0].w / 2, matches[0].y + matches[0].h / 2);
      await page.waitForTimeout(waitAfter);
      return true;
    }
    await page.waitForTimeout(600);
  }
  if (optional) return false;
  throw new Error(`no semantics node matching ${JSON.stringify(needle)}`);
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
    // The regression that matters: a PNG input must stay a PNG.
    expect: { signature: '\x89PNG', note: 'PNG (format preserved)' },
  },
  {
    id: 'compress_jpg',
    toolLabel: '图片压缩',
    sample: 'jpg',
    extension: '.jpg',
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
      (await clickText(page, testCase.toolLabel, { optional: true })) ||
      (testCase.fallbackLabel
        ? await clickText(page, testCase.fallbackLabel, { optional: true })
        : false);
    if (!selected) throw new Error(`tool tile ${testCase.toolLabel} is not reachable`);

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