import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, realpathSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { chooseDevice, fileSelectionTemplate, findLauncher, findTarget, prepareLauncher, resolvePreviewFile } from './preview.mjs';

test('resolves shorthand and explicit paths, and lists ambiguous names', () => {
  const root = realpathSync(mkdtempSync(join(tmpdir(), 'quran-preview-names-')));
  try {
    for (const directory of ['UI', 'Other']) {
      mkdirSync(join(root, directory));
      writeFileSync(join(root, directory, 'Row.swift'), '#Preview {}');
    }
    writeFileSync(join(root, 'UI', 'Unique.swift'), '#Preview {}');
    const description = { targets: [
      { type: 'library', path: 'UI', sources: ['Row.swift', 'Unique.swift'] },
      { type: 'library', path: 'Other', sources: ['Row.swift'] },
    ] };
    for (const input of ['Unique', 'unique', 'UNIQUE.SWIFT', 'ui/unique.swift', join(root, 'UI/Unique.swift')]) {
      assert.equal(resolvePreviewFile(description, input, root), join(root, 'UI/Unique.swift'));
    }
    assert.throws(() => resolvePreviewFile(description, 'rOw', root), error =>
      error.message.includes('Multiple files') && error.message.includes('UI/Row.swift')
      && error.message.includes('Other/Row.swift'));
    assert.throws(() => resolvePreviewFile(description, 'Missing', root), /No Swift package source/);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('make passes f to the launcher, including paths with spaces', () => {
  const root = mkdtempSync(join(tmpdir(), 'quran-preview-make-'));
  try {
    writeFileSync(join(root, 'node'), '#!/bin/sh\nprintf "%s" "$PREVIEW_FILE"\n', { mode: 0o755 });
    const options = { encoding: 'utf8', env: { ...process.env, PATH: `${root}:${process.env.PATH}` } };
    assert.equal(execFileSync('make', ['--no-print-directory', 'preview', 'f=ayahnumberview'], options), 'ayahnumberview');
    assert.equal(execFileSync('make', ['--no-print-directory', 'preview', 'f=path with spaces/View.swift'], options),
      'path with spaces/View.swift');
    assert.throws(() => execFileSync('make', ['--no-print-directory', 'UnrecognizedPreviewGoal'],
      { ...options, stdio: 'pipe' }), /No rule to make target/);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('finds membership from SwiftPM sources, including custom paths and spaces', () => {
  const target = { name: 'UI', type: 'library', path: 'Custom UI', sources: ['Nested/View.swift'] };
  const description = { targets: [target, { name: 'Other', type: 'library', path: 'Other', sources: ['View.swift'] }] };
  assert.equal(findTarget(description, '/repo/Custom UI/Nested/View.swift', '/repo'), target);
  assert.throws(() => findTarget(description, '/repo/Other/Excluded.swift', '/repo'), /exactly one/);
});

const device = (name, udid, state = 'Shutdown') => ({ name, udid, state, isAvailable: true });
const devices = {
  'com.apple.CoreSimulator.SimRuntime.iOS-18-6': [device('iPhone 11', 'old', 'Booted')],
  'com.apple.CoreSimulator.SimRuntime.iOS-26-2': [device('iPhone 17', 'new')],
  'com.apple.CoreSimulator.SimRuntime.tvOS-26-2': [device('Apple TV', 'tv', 'Booted')],
};

test('reuses a compatible booted phone, otherwise selects the latest iOS', () => {
  assert.equal(chooseDevice(devices, '17.0').udid, 'old');
  assert.equal(chooseDevice(devices, '26.0').udid, 'new');
  assert.throws(() => chooseDevice(devices, '27.0'), /Install an iPhone/);
});

test('validates explicit device overrides against availability and deployment version', () => {
  assert.equal(chooseDevice(devices, '17.0', 'new').udid, 'new');
  assert.throws(() => chooseDevice(devices, '26.0', 'old'), /PREVIEW_DEVICE/);
  assert.throws(() => chooseDevice(devices, '17.0', 'tv'), /PREVIEW_DEVICE/);
});

test('filters using runtime file metadata, independently of preview labels', () => {
  const source = 'return retainedTypeNames.insert(previewType.typeName).inserted';
  const result = fileSelectionTemplate(source, 'NoorUI/NoteEditorView.swift');
  assert.equal(result, 'return previewType.fileID == "NoorUI/NoteEditorView.swift" && retainedTypeNames.insert(previewType.typeName).inserted');
  assert.throws(() => fileSelectionTemplate('incompatible template', 'UI/View.swift'), /template changed/);
});

test('discovers the newest installed launcher without a hardcoded plugin version', () => {
  const root = mkdtempSync(join(tmpdir(), 'quran-preview-test-'));
  try {
    for (const version of ['0.1.2', '0.1.10']) {
      const directory = join(root, 'plugins/cache/openai-curated-remote/build-ios-apps', version,
        'skills/ios-simulator-browser/scripts');
      mkdirSync(directory, { recursive: true });
      writeFileSync(join(directory, 'swiftui-preview-browser.mjs'), '');
    }
    assert.match(findLauncher({ CODEX_HOME: root }), /0\.1\.10/);
    assert.throws(() => findLauncher({ PREVIEW_LAUNCHER: join(root, 'missing') }), /does not exist/);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('copied launcher executes its entry point through macOS temporary-directory aliases', () => {
  const root = mkdtempSync(join(tmpdir(), 'quran-preview-entry-test-'));
  let scratch;
  try {
    mkdirSync(join(root, 'templates'));
    writeFileSync(join(root, 'templates/PreviewBrowserEntries.swift'),
      'retainedTypeNames.insert(previewType.typeName).inserted');
    const launcher = join(root, 'swiftui-preview-browser.mjs');
    writeFileSync(launcher, `import { pathToFileURL } from 'node:url';
      if (import.meta.url === pathToFileURL(process.argv[1]).href) console.log('launched');`);
    scratch = prepareLauncher(launcher, 'UI/View.swift');
    assert.equal(execFileSync(process.execPath, [join(scratch, 'swiftui-preview-browser.mjs')],
      { encoding: 'utf8' }).trim(), 'launched');
  } finally {
    if (scratch) rmSync(scratch, { recursive: true, force: true });
    rmSync(root, { recursive: true, force: true });
  }
});
