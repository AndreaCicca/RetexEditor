<p align="center">
  <img src="apps/RatexEditor/RatexEditor/Resources/AppIcon.png" width="128" height="128" alt="RetexEditor Icon" />
</p>

# RetexEditor & Ratex

[![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue.svg)](https://apple.com/macos)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.9%2B-orange.svg)](https://developer.apple.com/xcode/swiftui/)
[![Rust](https://img.shields.io/badge/Rust-1.80%2B-lightgrey.svg)](https://www.rust-lang.org)
[![Core Engine](https://img.shields.io/badge/Engine-ratex%20v0.3.0-green.svg)](https://github.com/leoliu0/ratex)
[![License](https://img.shields.io/badge/license-MIT%2FApache--2.0-blue.svg)](LICENSE)

**RetexEditor** is a high-performance, native LaTeX authoring environment and toolchain for macOS. It pairs an elegant, full-featured desktop IDE (**RetexEditor**, built in SwiftUI, AppKit, and PDFKit) with an ultra-fast, self-contained, pure-Rust TeX engine (**ratex**).

---

## 🎯 Overview: The Editor vs. The Engine

To understand the project architecture, it is helpful to distinguish between its two foundational components:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        RetexEditor (macOS App)                          │
│   Native SwiftUI / AppKit desktop IDE for writing and previewing LaTeX  │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ In-Memory C FFI (`crates/libtex`)
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          ratex (Rust Engine)                            │
│   Pure-Rust TeX compiler, in-memory CTAN package resolver & BibTeX      │
└─────────────────────────────────────────────────────────────────────────┘
```

### 🖥️ What is RetexEditor (The Editor)?

**RetexEditor** (located in `apps/RatexEditor`) is a modern, native macOS integrated development environment (IDE) built specifically for LaTeX authoring. Designed with **SwiftUI**, **AppKit**, and **PDFKit**, it replaces the slow, cumbersome workflows of legacy LaTeX editors:

- **Zero External Dependencies**: Completely self-contained. You do **not** need to install MacTeX or TeX Live (saving 5–8 GB of disk space), nor Perl or external shell scripts.
- **Instant Live Preview**: Documents compile in-memory in under 50 milliseconds. Thanks to a double-buffered PDF view (`SmoothPDFContainerView`), preview updates are instantaneous and smooth—no black-screen flashing, no blank frames.
- **Academic Multi-File Project Workflow**:
  - Full file tree navigator with CRUD operations (create, rename, delete files and folders).
  - **Master / Entry Point Selector**: Set a primary root document (e.g. `main.tex` or `Thesis.tex`). When editing individual chapters or sub-files (e.g. `chapters/intro.tex`), changes are live-injected into the master compilation automatically.
- **Refined macOS Typography & UX**:
  - Distraction-free, book-style editor padding (32pt horizontal, 22pt vertical) and proportional line spacing.
  - Interactive font scaling via keyboard shortcuts (`⌘+`, `⌘-`, `⌘0`) and live point stepper.
  - Layer-backed text view (`NSTextView`) with zero resizing flicker.
  - Smooth native collapsible sidebar via `NavigationSplitView`.
  - Comprehensive macOS menu bar integration, document templates ("Lorem Ipsum" menu), interactive LaTeX math symbol palette, and compiler diagnostics.
- **Native macOS Design**: Features an authentic macOS squircle app icon with a ruby-red "R" emblem and dark slate finish.

👉 For detailed architecture diagrams, shortcuts, and documentation of the macOS app, see [RetexEditor macOS Documentation](apps/RatexEditor/README.md).

---

### 🦀 What is ratex (The TeX Engine)?

**`ratex`** is the underlying computational typesetting engine of this project. It is a high-speed, modern TeX engine and compiler written from scratch in **pure Rust (100% memory-safe)** by **Leo Liu** ([github.com/leoliu0/ratex](https://github.com/leoliu0/ratex)):

- **Knuth's TeX82 Reimagined**: Implements Donald Knuth's complete TeX specification (`tex.web`), including categories 0–15, macro expansion, mathematical formula layout (Appendix G), and the Knuth-Plass optimal paragraph line-breaking algorithm.
- **Memory Safety & Modern Architecture**: Legacy TeX engines (`web2c`, `pdflatex`, `xelatex`) rely on 40-year-old C code vulnerable to buffer overflows, segfaults, and memory corruption. `ratex` enforces Rust's strict ownership and bounds-checking model, providing stability and thread-safe execution.
- **Embedded CTAN Distribution (`crates/tex-kpse`)**: Pre-compiles and embeds the LaTeX format, standard fonts (Computer Modern, Latin Modern, AMS Math), and **over 24,000 CTAN packages** directly in memory. No network requests or file system lookups are needed to resolve standard macros.
- **Native In-Memory BibTeX (`crates/tex-bibtex`)**: Parses `.bib` and `.bst` files in memory with automatic multi-pass convergence in single-digit milliseconds.
- **Zero Temporary Disk Pollution**: Operates entirely in RAM without producing auxiliary clutter files (`.aux`, `.log`, `.toc`, `.fls`) on your physical drive.

---

### ⚡ How They Work Together: The In-Memory Pipeline

Traditional LaTeX editors invoke external shell processes (`pdflatex document.tex`) that write auxiliary files to disk, read them back, and trigger PDF refreshes with noticeable lag and flicker.

In **RetexEditor**, the entire workflow is bound in-memory:

1. **Swift Concurrency Actor (`RatexEngine.swift`)**: When the user edits text, a debounced actor task captures the active document buffer and any project assets.
2. **C FFI Static Library (`crates/libtex` / `libtex.a`)**: Swift passes in-memory byte buffers directly across a clean C ABI (`tex.h`) to the Rust engine.
3. **Pure-Rust Compilation**: `ratex` parses, typesets, and renders the PDF directly into a raw byte vector in **0.8 to 50 milliseconds**.
4. **Zero-Flicker Snapshot Presentation**: The resulting PDF data is deserialized directly into Apple's `PDFDocument` (PDFKit) and presented smoothly with cross-fading.

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

## 🛠️ Standalone CLI Toolchain

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
