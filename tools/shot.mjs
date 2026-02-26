import { spawn } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { chromium } from "playwright";

function parseArgs(argv) {
  const args = {
    host: "127.0.0.1",
    port: "4000",
    pagePath: "/",
    out: "",
    fullPage: true
  };

  for (let i = 2; i < argv.length; i++) {
    const value = argv[i];
    if (value === "--host") args.host = argv[++i] ?? args.host;
    else if (value === "--port") args.port = argv[++i] ?? args.port;
    else if (value === "--path") args.pagePath = argv[++i] ?? args.pagePath;
    else if (value === "--out") args.out = argv[++i] ?? args.out;
    else if (value === "--full-page") args.fullPage = true;
    else if (value === "--no-full-page") args.fullPage = false;
    else throw new Error(`Unknown arg: ${value}`);
  }

  if (!args.pagePath.startsWith("/")) args.pagePath = `/${args.pagePath}`;
  return args;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function terminateProcess(child) {
  if (!child || child.killed || child.exitCode !== null) return;

  const waitForExit = (timeoutMs) =>
    new Promise((resolve) => {
      const timeout = setTimeout(resolve, timeoutMs);
      child.once("exit", () => {
        clearTimeout(timeout);
        resolve();
      });
    });

  child.kill("SIGINT");
  await waitForExit(5_000);
  if (child.exitCode !== null) return;

  child.kill("SIGTERM");
  await waitForExit(5_000);
}

async function waitForOk(url, timeoutMs) {
  const start = Date.now();
  // eslint-disable-next-line no-constant-condition
  while (true) {
    try {
      const response = await fetch(url, { method: "GET" });
      if (response.ok) return;
    } catch {
      // ignore until ready
    }

    if (Date.now() - start > timeoutMs) {
      throw new Error(`Timed out waiting for ${url}`);
    }

    await sleep(250);
  }
}

function sanitizeForFilename(input) {
  return input
    .replaceAll("/", "_")
    .replaceAll("?", "_")
    .replaceAll("&", "_")
    .replaceAll("=", "_")
    .replaceAll(/[^a-zA-Z0-9._-]/g, "_")
    .replaceAll(/_+/g, "_")
    .replaceAll(/^_+|_+$/g, "");
}

async function ensureDir(dir) {
  await fs.mkdir(dir, { recursive: true });
}

async function main() {
  const args = parseArgs(process.argv);
  const baseUrl = `http://${args.host}:${args.port}`;
  const url = `${baseUrl}${args.pagePath}`;

  const now = new Date();
  const stamp = now.toISOString().replaceAll(":", "").replaceAll(".", "");
  const defaultOut = path.join(
    "tmp",
    "screenshots",
    `${stamp}_${sanitizeForFilename(args.pagePath || "/") || "root"}.png`
  );
  const outPath = args.out || defaultOut;
  await ensureDir(path.dirname(outPath));

  const jekyllArgs = [
    "exec",
    "jekyll",
    "serve",
    "--host",
    args.host,
    "--port",
    args.port
  ];

  const env = {
    ...process.env,
    BUNDLE_PATH: process.env.BUNDLE_PATH || "vendor/bundle"
  };

  const server = spawn("bundle", jekyllArgs, { env, stdio: "inherit" });

  const cleanup = async () => {
    await terminateProcess(server);
  };

  process.on("SIGINT", async () => {
    await cleanup();
    process.exit(130);
  });
  process.on("SIGTERM", async () => {
    await cleanup();
    process.exit(143);
  });

  try {
    await waitForOk(baseUrl, 60_000);

    const browser = await chromium.launch();
    const page = await browser.newPage();
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.goto(url, { waitUntil: "networkidle" });
    await page.screenshot({ path: outPath, fullPage: args.fullPage });
    await browser.close();

    console.log(`screenshot: ${outPath}`);
  } finally {
    await cleanup();
  }
}

await main();
