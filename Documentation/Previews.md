# SwiftUI Previews from the Terminal

```sh
make preview f=AyahNumberView
# Or supply a filename/path explicitly:
make preview f=UI/NoorUI/Sources/Features/Note/NoteEditorView.swift
```

The command searches the package's source files for `AyahNumberView.swift`; you don't need to supply `.swift` or the full path. Matching is case-insensitive, so `f=ayahnumberview` also works. You can optionally supply the extension or a path. If multiple files match, it lists their paths so you can select one with `f=`.

It then discovers the file's Swift package target, selects and boots a compatible iPhone simulator, opens Simulator, and runs every `#Preview` in that file with page controls and hot reload. Keep the terminal open; Ctrl-C stops watching. Previews run with sync disabled, independently of the ambient `QURAN_SYNC` setting.

## Requirements

Requires Xcode with an installed iOS simulator, Node.js, and the `build-ios-apps` Codex plugin. The script discovers the installed plugin version automatically. To use another installation, set `PREVIEW_LAUNCHER` to its `swiftui-preview-browser.mjs`; to select a particular simulator, set `PREVIEW_DEVICE` to its UDID.

## How it works

The launcher creates a temporary host outside the repository and downloads its preview dependencies on the first build. Only Swift package library sources with `#Preview` are supported; legacy `PreviewProvider` declarations cannot be selected by file. The helper adapts a temporary copy of the plugin's template to match runtime source-file metadata, leaving the installed plugin and package unchanged. Run helper tests with `make test-preview-tools`.
