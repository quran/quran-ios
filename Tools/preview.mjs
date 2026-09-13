#!/usr/bin/env node

import { execFileSync, spawn } from 'node:child_process';
import { cpSync, existsSync, mkdtempSync, readFileSync, readdirSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { homedir, tmpdir } from 'node:os';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const launcherName = 'swiftui-preview-browser.mjs';

export function resolvePreviewFile(description, input, root) {
  const filename = input.toLowerCase().endsWith('.swift') ? input : `${input}.swift`;
  const files = description.targets.filter(target => target.type === 'library').flatMap(target =>
    (target.sources ?? []).map(source => resolve(root, target.path, source)));
  const matches = [...new Set(files.filter(file => input.includes('/')
    ? file.toLowerCase() === resolve(root, input).toLowerCase()
    : basename(file).toLowerCase() === filename.toLowerCase()))].sort();
  if (!matches.length) throw new Error(`No Swift package source matches "${input}".`);
  if (matches.length > 1) {
    throw new Error(`Multiple files match "${input}". Use make preview f=<path>:\n${matches.join('\n')}`);
  }
  return realpathSync(matches[0]);
}

export function findTarget(description, file, root) {
  const matches = description.targets.filter(target =>
    target.type === 'library' && (target.sources ?? []).some(source =>
      resolve(root, target.path, source) === file));
  if (matches.length !== 1) {
    throw new Error('The file must belong to exactly one Swift package library target.');
  }
  return matches[0];
}

export function chooseDevice(devices, minimumVersion, requested) {
  const candidates = Object.entries(devices).flatMap(([runtime, entries]) => {
    const version = runtime.match(/\.iOS-(\d+(?:-\d+)*)$/)?.[1]?.replaceAll('-', '.');
    if (!version || version.localeCompare(minimumVersion, undefined, { numeric: true }) < 0) return [];
    return entries.filter(device => device.isAvailable).map(device => ({ ...device, version }));
  });
  if (requested) {
    const device = candidates.find(device => device.udid === requested);
    if (!device) throw new Error(`PREVIEW_DEVICE must be an available iOS ${minimumVersion}+ simulator UDID.`);
    return device;
  }
  const phones = candidates.filter(device => device.name.startsWith('iPhone'));
  phones.sort((a, b) => Number(b.state === 'Booted') - Number(a.state === 'Booted')
    || b.version.localeCompare(a.version, undefined, { numeric: true })
    || a.name.localeCompare(b.name));
  if (!phones.length) throw new Error(`Install an iPhone simulator with iOS ${minimumVersion}+ in Xcode first.`);
  return phones[0];
}

export function findLauncher(env = process.env) {
  if (env.PREVIEW_LAUNCHER) {
    const path = resolve(env.PREVIEW_LAUNCHER);
    if (!existsSync(path)) throw new Error(`PREVIEW_LAUNCHER does not exist: ${path}`);
    return path;
  }
  const cache = join(env.CODEX_HOME || join(homedir(), '.codex'),
    'plugins/cache/openai-curated-remote/build-ios-apps');
  const versions = existsSync(cache) ? readdirSync(cache).sort((a, b) =>
    b.localeCompare(a, undefined, { numeric: true })) : [];
  for (const version of versions) {
    const path = join(cache, version, 'skills/ios-simulator-browser/scripts', launcherName);
    if (existsSync(path)) return path;
  }
  throw new Error('Install the build-ios-apps Codex plugin, or set PREVIEW_LAUNCHER to its swiftui-preview-browser.mjs.');
}

// The upstream launcher filters names only. Adapt a disposable copy to match
// #Preview's runtime fileID, preserving every named and unnamed variant in a file.
export function fileSelectionTemplate(template, fileID) {
  const anchor = 'retainedTypeNames.insert(previewType.typeName).inserted';
  if (template.split(anchor).length !== 2) {
    throw new Error('The installed preview launcher template changed; update Tools/preview.mjs before using it.');
  }
  const swiftString = JSON.stringify(fileID).replace(/\\u([0-9a-f]{4})/gi, '\\u{$1}');
  return template.replace(anchor, `previewType.fileID == ${swiftString} && ${anchor}`);
}

function runJSON(command, args) {
  return JSON.parse(execFileSync(command, args, {
    encoding: 'utf8', maxBuffer: 20 * 1024 * 1024, env: { ...process.env, QURAN_SYNC: '' },
  }));
}

export function prepareLauncher(launcher, fileID) {
  // Node resolves module URLs through symlinks. Canonicalize macOS /var here so
  // the upstream import.meta.url entry-point check agrees with process.argv[1].
  const scratch = realpathSync(mkdtempSync(join(tmpdir(), 'quran-preview-launcher-')));
  try {
    cpSync(dirname(launcher), scratch, { recursive: true });
    const template = join(scratch, 'templates/PreviewBrowserEntries.swift');
    writeFileSync(template, fileSelectionTemplate(readFileSync(template, 'utf8'), fileID));
    return scratch;
  } catch (error) {
    rmSync(scratch, { recursive: true, force: true });
    throw error;
  }
}

export async function main() {
  const input = process.env.PREVIEW_FILE;
  if (!input) throw new Error('Usage: make preview f=ViewName or make preview f=path/to/View.swift');
  const launcher = findLauncher();
  console.log('Resolving the Swift package target…');
  const description = runJSON('swift', ['package', '--package-path', packageRoot, 'describe', '--type', 'json']);
  const file = resolvePreviewFile(description, input, realpathSync(packageRoot));
  if (!file.endsWith('.swift')) throw new Error('f must be a Swift source file.');
  if (!/#Preview\b/.test(readFileSync(file, 'utf8'))) {
    throw new Error('The file must contain #Preview declarations. Legacy PreviewProvider file selection is unsupported.');
  }
  const target = findTarget(description, file, realpathSync(packageRoot));
  const iosVersion = description.platforms.find(platform => platform.name === 'ios')?.version ?? '17.0';
  const minimumVersion = Number.parseFloat(iosVersion) < 17 ? '17.0' : iosVersion;
  const device = chooseDevice(runJSON('xcrun', ['simctl', 'list', 'devices', 'available', '-j']).devices,
    minimumVersion, process.env.PREVIEW_DEVICE);
  const fileID = `${target.c99name}/${basename(file)}`;
  const scratch = prepareLauncher(launcher, fileID);
  try {
    console.log(`Previewing ${fileID} on ${device.name} (iOS ${device.version}).`);
    console.log('All #Preview variants in this file are included. Keep this terminal open; Ctrl-C stops watching.');
    execFileSync('open', ['-a', 'Simulator', '--args', '-CurrentDeviceUDID', device.udid]);
    // The filter also gives each file its own upstream build cache. File selection
    // happens above; this match-all suffix lets every variant through name filtering.
    const child = spawn(process.execPath, [join(scratch, launcherName), join(packageRoot, 'Package.swift'),
      '--package-target', target.name, '--device', device.udid,
      '--preview-filter', `(?:${Buffer.from(fileID).toString('hex')})|.*`], {
      stdio: 'inherit', env: { ...process.env, QURAN_SYNC: '' },
    });
    const interrupt = () => child.kill('SIGINT');
    const terminate = () => child.kill('SIGTERM');
    process.on('SIGINT', interrupt);
    process.on('SIGTERM', terminate);
    try {
      await new Promise((resolveRun, reject) => {
        child.once('error', reject);
        child.once('exit', (code, signal) => {
          if (code === 0 || signal === 'SIGINT' || signal === 'SIGTERM') resolveRun();
          else reject(new Error(`Preview launcher exited with ${signal || code}.`));
        });
      });
    } finally {
      process.off('SIGINT', interrupt);
      process.off('SIGTERM', terminate);
    }
  } finally {
    rmSync(scratch, { recursive: true, force: true });
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(error => {
    console.error(`Preview error: ${error.message}`);
    process.exitCode = 1;
  });
}
