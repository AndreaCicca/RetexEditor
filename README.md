# RetexEditor & Ratex

[![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue.svg)](https://apple.com/macos)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.9%2B-orange.svg)](https://developer.apple.com/xcode/swiftui/)
[![Rust](https://img.shields.io/badge/Rust-1.80%2B-lightgrey.svg)](https://www.rust-lang.org)
[![Core Engine](https://img.shields.io/badge/Engine-ratex%20v0.3.0-green.svg)](https://github.com/leoliu0/ratex)
[![License](https://img.shields.io/badge/license-MIT%2FApache--2.0-blue.svg)](LICENSE)

**RetexEditor** is a next-generation, high-performance LaTeX authoring environment and toolchain. It pairs an elegant, full-featured native macOS application (**RetexEditor**, built in SwiftUI, AppKit, and PDFKit) with an ultra-fast, self-contained, pure-Rust TeX engine (**ratex**).

By eliminating the traditional requirement to install 5–8 GB of TeX Live or MacTeX, RetexEditor compiles complex LaTeX documents entirely in memory in **0.8 to 50 milliseconds**, providing an instantaneous live preview experience without process delays, I/O lag, or screen flickering.

---

## 🧭 Project Architecture & Provenance

### The Core TeX Engine (ratex)
The underlying typesetting engine in this project is **`ratex`**, designed and created by **Leo Liu** ([github.com/leoliu0/ratex](https://github.com/leoliu0/ratex)).

Unlike common wrappers that invoke external `pdflatex` or `xelatex` binaries behind the scenes, `ratex` is a ground-up, 100% pure-Rust reimplementation of Donald Knuth's TeX engine:
- **Knuth's TeX82 Specification (`tex.web`)**: Implements the complete TeX finite-state machine (categories 0–15, macro expansion, math layout from Appendix G, paragraph line-breaking via the Knuth-Plass algorithm, and vertical page construction).
- **Zero Memory Compromises**: Written with strict Rust bounds checking, eliminating buffer overflows, segfaults, and memory corruption bugs common to legacy C TeX engines.
- **Embedded CTAN Distribution (`crates/tex-kpse`)**: Pre-packages the compiled LaTeX format, all standard fonts (AMS Math, Latin Modern, Computer Modern), and **over 24,000 CTAN packages** directly in memory.
- **Native BibTeX Engine (`crates/tex-bibtex`)**: Interprets `.bib` and `.bst` files directly in memory with automatic multi-pass convergence in single-digit milliseconds.

### Beyond a Fork — What RetexEditor Adds
This repository elevates the standalone Rust engine into a comprehensive, native publishing ecosystem for developers, researchers, and students:

1. **Native macOS Desktop IDE (`apps/RatexEditor`)**:
   - Built entirely in **SwiftUI** and **AppKit** utilizing native macOS components (`NavigationSplitView`).
   - Integrated file explorer with full CRUD (create, rename, delete) operations for complex project trees.
   - Master / Entry Point selector for multi-file projects (theses, books, multi-chapter publications) with real-time live buffer injection.
2. **Sub-50ms In-Memory C FFI Bridge (`crates/libtex` & `RatexEngine`)**:
   - Exposes a clean C ABI (`tex.h`) compiled as a universal static library (`libtex.a`).
   - Managed in Swift via an isolated concurrency actor (`RatexEngine.swift`), feeding in-memory file buffers and receiving serialized PDF bytes directly into RAM without temporary files or shell processes.
3. **Double-Buffered, Zero-Flicker Live PDF Preview (`SmoothPDFContainerView`)**:
   - Resolves the notorious "black screen flash" during active typing through an instant snapshot overlay and sub-frame cross-fade.
4. **Interactive Authoring & Typography**:
   - Dynamic editor font scaling via `⌘+`, `⌘-`, `⌘0` and a live subheader stepper.
   - Generous, book-like editor margins (32x22 pt) and proportional line spacing.
   - Graphical WYSIWYG formatting toolbar, Lorem Ipsum generators, and an interactive LaTeX math symbol palette.
5. **Unified Multi-Platform Distribution**:
   - A single cohesive repository supporting the macOS GUI app, standalone CLI binaries, embedded C API (`libtex`), and WebAssembly (`tex.wasm`).

---

## ⚡ Performance Highlights

Tested and verified against **3,000 real-world arXiv papers** across mathematics, physics, and computer science:

| Workload | RetexEditor / ratex | TeX Live (`pdflatex` / `latexmk`) | Advantage |
|---|---|---|---|
| **Incremental Rebuild (Warm)** | **0.8 – 8.2 ms** | 40 – 60 ms | **10× – 70× FASTER** ⚡ |
| **Short Papers (1–3 pages) Cold** | **11 – 13 ms** | 39 – 41 ms | **3.1× – 3.6× FASTER** ⚡ |
| **Full 3,000-Paper Corpus Throughput** | **89 papers / min** | 53 papers / min | **1.7× FASTER** ⚡ |
| **Clean Compiles Across arXiv** | **2,620 papers** | 2,613 papers | **More robust than TeX Live** |
| **Visual Document Parity** | **96.39% mean parity** | Baseline (100%) | **Publication-grade fidelity** |

---

## 🖥️ RetexEditor for macOS

For complete documentation on the macOS application, visual architecture diagrams, and keyboard shortcuts, please refer to the dedicated guide:

👉 **[RetexEditor macOS Documentation](apps/RatexEditor/README.md)**

```
apps/RatexEditor/
├── RatexEditor.xcodeproj/              # Native Xcode macOS project
├── Scripts/build_libtex.sh             # Compiles crates/libtex into libtex.a
└── RatexEditor/
    ├── App/RatexEditorApp.swift        # SwiftUI app lifecycle and native menu commands
    ├── Bridge/RatexEngine.swift        # Swift Actor managing in-memory Rust sessions
    ├── Views/MainSplitView.swift       # Responsive 3-pane split view (NavigationSplitView)
    ├── Views/SourceEditorView.swift    # Layer-backed NSTextView with padding and font scaling
    ├── Views/PDFKitRepresentable.swift # Smooth double-buffered PDF viewer
    └── Views/WYSIWYGToolbar.swift      # Formatting controls, math palette, entrypoint picker
```

---

## 🛠️ CLI & Toolchain Usage

In addition to the macOS application, the repository provides the standalone `ratex` CLI toolchain:

### Single-Command Multi-Pass Build
`ratex` automatically tracks dependencies, resolves CTAN packages in memory, runs embedded BibTeX passes, and converges cross-references in milliseconds:

```bash
# Compile document (automatically converges bibtex and cross-references)
ratex paper.tex

# Output PDF to a specific directory
ratex -output-directory=build paper.tex

# Clean auxiliary build artifacts and cache
ratex -c
```

### Visual Document Diffing (`latexdiff`)
```bash
# Compare two versions and generate marked-up difference file:
ratex latexdiff old.tex new.tex diff.tex

# Or compile the diff directly to PDF:
ratex diff.tex
```

### Integration with External Editors

#### VS Code (LaTeX Workshop)
Add this configuration to your VS Code `settings.json`:
```json
"latex-workshop.latex.tools": [
  {
    "name": "ratex",
    "command": "ratex",
    "args": ["-pdf", "-interaction=nonstopmode", "%DOC%"]
  }
],
"latex-workshop.latex.recipes": [
  { "name": "ratex", "tools": ["ratex"] }
]
```

#### TeXstudio
1. Open **Options** &rarr; **Configure TeXstudio** &rarr; **Build**.
2. Set **Default Compiler** to: `ratex -pdf -interaction=nonstopmode %.tex`
3. Press **F5** to compile.

---

## 🏗️ Building from Source

### Prerequisites
- **Rust**: 1.80 or newer (`cargo`) &mdash; [rustup.rs](https://rustup.rs)
- **Xcode**: 15.0+ or 16.0+ with Command Line Tools (`xcode-select --install`) for the macOS application
- **Python**: 3.11+ (optional, for WebAssembly bundling scripts)

### 1. Build the Rust CLI & Toolchain
```bash
git clone https://github.com/AndreaCicca/RetexEditor.git
cd RetexEditor

# Build all workspace crates in release mode
cargo build --release

# The compiled binary is located at target/release/ratex
```

### 2. Build and Run the macOS Application
```bash
# 1. Compile the C FFI static library (libtex.a)
./apps/RatexEditor/Scripts/build_libtex.sh

# 2. Build the macOS application using xcodebuild
xcodebuild -project apps/RatexEditor/RatexEditor.xcodeproj -scheme RatexEditor -configuration Debug build

# 3. Or open in Xcode directly
open apps/RatexEditor/RatexEditor.xcodeproj
```

---

## 📦 Workspace Structure

```
RetexEditor/
├── apps/
│   └── RatexEditor/         # Native macOS IDE (SwiftUI + AppKit + PDFKit)
├── crates/
│   ├── tex-core/            # Pure-Rust TeX state machine, math layout, line breaking, PDF generator
│   ├── tex-kpse/            # In-memory package resolver, font loader, and kpathsea emulator
│   ├── tex-bibtex/          # Native pure-Rust BibTeX interpreter
│   ├── tex-runtime/         # Multi-pass compilation orchestrator and session management
│   ├── tex-cli/             # Unified multi-pass CLI driver, command aliases, and artifact cache
│   ├── libtex/              # C FFI static and shared library (tex.h) for host application embedding
│   └── tex-wasm/            # In-memory WebAssembly module for browsers and Node.js
├── docs/
│   ├── libraries.md         # Documentation for C API (libtex) and WebAssembly (tex.wasm)
│   └── internals/           # Deep-dive engineering notes (Knuth-Plass, math layout, page builder)
├── packaging/               # Distribution installers for Linux, macOS, and Windows
└── scripts/                 # Corpus validation, parity testing, and benchmark suites
```

---

## 📚 Technical Documentation & Internals

- [Native C API (`libtex`) and WebAssembly Guide](docs/libraries.md)
- [RetexEditor macOS App Architecture](apps/RatexEditor/README.md)
- [TeX Engine Internals & Technical Notes](docs/internals/README.md):
  - [Math Formula Layout (TeX82 Appendix G)](docs/internals/math.md)
  - [Knuth-Plass Paragraph Line-Breaking](docs/internals/linebreak.md)
  - [Vertical Page Builder & Shipout](docs/internals/page-ship.md)
  - [Native BibTeX Interpreter](docs/internals/bibtex.md)
  - [Direct PDF Output & Font Subsetting](docs/internals/pdf-embed.md)
  - [Auxiliary State & Cryptographic Caching](docs/internals/artifacts.md)
  - [TeX Live Pixel Parity Reports](docs/internals/parity.md)

---

## 📜 License & Acknowledgements

This project is dual-licensed under:
- **MIT License** ([LICENSE-MIT](LICENSE-MIT))
- **Apache License, Version 2.0** ([LICENSE-APACHE](LICENSE-APACHE))

### Acknowledgements
- **Donald E. Knuth** for creating the foundational TeX82 typesetting system.
- **Leo Liu** ([leoliu0/ratex](https://github.com/leoliu0/ratex)) for the remarkable engineering of the pure-Rust `ratex` engine, in-memory package resolver, and typesetting pipeline.
