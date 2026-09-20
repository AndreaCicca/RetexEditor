# RetexEditor (macOS)

[![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue.svg)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B%20%2F%20SwiftUI-orange.svg)](https://swift.org)
[![Rust Engine](https://img.shields.io/badge/Rust%20Engine-ratex%20v0.3.0-green.svg)](https://github.com/leoliu0/ratex)
[![Repository](https://img.shields.io/badge/GitHub-AndreaCicca%2FRetexEditor-blue.svg)](https://github.com/AndreaCicca/RetexEditor)
[![License](https://img.shields.io/badge/license-MIT%2FApache--2.0-blue.svg)](../../LICENSE)

**RetexEditor** (sviluppato come target Xcode `RatexEditor`) è un ambiente di sviluppo integrato (IDE) e editor LaTeX completo, moderno e nativo per macOS, sviluppato in **SwiftUI**, **AppKit** e **PDFKit**, alimentato direttamente in memoria dal motore TeX puro in Rust **`ratex`**.

A differenza degli editor LaTeX tradizionali (come TeXShop, TeXstudio o VS Code con LaTeX Workshop) che si limitano a invocare script di shell e processi esterni lenti (`pdflatex`, `latexmk`), **RatexEditor incorpora il motore TeX direttamente nel proprio processo**. La compilazione avviene interamente nella RAM in **meno di 10–50 millisecondi**, consentendo una vera esperienza di **Live Preview in tempo reale** senza latenza, senza flickering e senza alcuna necessità di installare TeX Live o MacTeX.

---

## 📖 Cos'è questo Progetto

RatexEditor nasce per superare le limitazioni storiche dell'ecosistema TeX su macOS:
1. **Zero Dipendenze Esterne**: Non richiede l'installazione di suite pesanti come TeX Live o MacTeX (che occupano tipicamente tra i 5 e gli 8 GB di spazio su disco). L'applicazione è 100% autonoma.
2. **Reattività Istantanea**: La compilazione continua del documento non blocca l'interfaccia né fa lampeggiare a nero l'anteprima: il visualizzatore PDF a doppio buffer garantisce una transizione fluida e continua durante la digitazione.
3. **Editor TeX Completo e Strutturato**: Pensato per progetti accademici e professionali di qualsiasi scala (dall'articolo scientifico breve alla tesi di laurea o libro multi-capitolo), supporta la navigazione dell'albero di progetto, la selezione del file master di compilazione (*Entry Point*), classi `.cls`, stili `.sty`, bibliografie `.bib` e immagini vettoriali.
4. **Esperienza Nativa macOS**: Rispetta fedelmente le Human Interface Guidelines di Apple: sidebar a scomparsa con scivolamento nativo (`NavigationSplitView`), menu di sistema completi con scorciatoie da tastiera standard, supporto Dark/Light mode automatico e tipografia scalabile.

---

## 🦀 Da dove viene preso l'Engine in Rust?

Il cuore computazionale di questo progetto è **`ratex`**, un motore TeX e una toolchain di composizione tipografica scritti da zero in **Rust puro (100% memory-safe)**, creato e manutenuto da **Leo Liu** ([github.com/leoliu0/ratex](https://github.com/leoliu0/ratex)).

### Perché un Engine in Rust?
Il codice originale di TeX scritto da Donald Knuth nel 1982 (`tex.web`, poi convertito in C tramite `web2c`) è alla base della maggior parte delle distribuzioni odierne. Tuttavia, il codice C storico presenta limiti intrinseci: gestione complessa della memoria con rischio di buffer overflow o segfault, I/O sincrono su disco per ogni singolo file di font/macro, e forte rigidità nell'essere incorporato come libreria in-memory in app moderne.

`ratex` risolve radicalmente questi problemi:
- **Riscrittura Fedele e Sicura**: Riscrive l'intera macchina a stati di Knuth (tokenizzazione a categorie 0–15, espansione macro, e-TeX primitives, impaginazione, box/glue e l'algoritmo di Knuth-Plass per l'interruzione di riga) garantendo totale memoria sicura (zero memory corruption).
- **Bundle Virtuale In-Memory (`crates/tex-kpse`)**: Incorpora direttamente nel binario il formato LaTeX precompilato, tutti i font standard (AMS Math, Latin Modern, Computer Modern) e **oltre 24.000 pacchetti CTAN**. Nessun accesso alla rete o al file system è necessario per risolvere i pacchetti standard.
- **Interprete BibTeX Nativo (`crates/tex-bibtex`)**: Gestione automatica della bibliografia ed elaborazione delle citazioni e dei riferimenti incrociati (`.aux`) in-memory, con convergenza multi-passaggio in pochi millisecondi.
- **Validazione Crittografica delle Dipendenze**: Monitora le dipendenze e ricalcola solo le frazioni modificate del documento, riducendo i tempi di compilazione a 0.8–8 ms per edit incrementali.

### Come viene integrato in RatexEditor (macOS)
L'integrazione tra il codice Rust e l'interfaccia grafica Swift avviene attraverso una pipeline ad alte prestazioni:

```
┌─────────────────────────────────────────────────────────────┐
│                 RatexEditor (SwiftUI / AppKit)              │
│  - MainSplitView (Sidebar + Editor + Live PDFKit)           │
│  - SourceEditorView (NSTextView con formattazione e zoom)   │
│  - EditorState (@Observable, debouncer Task 350ms)          │
└──────────────────────────────┬──────────────────────────────┘
                               │ Swift Concurrency / Actor
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     RatexEngine.swift                       │
│  Actor Swift per la gestione thread-safe delle sessioni     │
└──────────────────────────────┬──────────────────────────────┘
                               │ C Bridging Header (RatexBridge.h)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 crates/libtex (C FFI ABI)                   │
│  Libreria statica C-compatible: target/ffi-release/libtex.a │
│  Header C: tex.h (tex_session_*, tex_compile, tex_result_*) │
└──────────────────────────────┬──────────────────────────────┘
                               │ Rust FFI
                               ▼
┌─────────────────────────────────────────────────────────────┐
│               ratex Engine Workspace (Rust)                 │
│  ├── tex-core     (TeX state machine, math layout, PDF gen) │
│  ├── tex-kpse     (In-memory package resolver & fonts)      │
│  ├── tex-bibtex   (Interprete BibTeX integrato)             │
│  └── tex-runtime  (Gestione sessioni e convergenza pass)    │
└─────────────────────────────────────────────────────────────┘
```

1. **Compilazione Rust FFI (`libtex.a`)**: Il crate `crates/libtex` esporta simboli C puri (`extern "C"`) con panic unwinding controllato (`ffi-release`). Lo script `build_libtex.sh` compila la libreria statica universale `libtex.a`.
2. **Bridging Header (`RatexBridge.h`)**: Espone le firme C di `tex.h` direttamente al compilatore Swift/Clang di Xcode.
3. **Actor Swift (`RatexEngine.swift`)**: Gestisce un'istanza thread-safe della sessione:
   - Carica il testo del documento master e di tutti i file secondari (`\include`, `\input`, `.cls`, `.sty`, `.bib`) direttamente come buffer di byte nella sessione in-memory (`tex_session_add_file`).
   - Invoca `tex_compile` con il nome dell'entry point.
   - Estrae il PDF risultante come `Data` nativo (`tex_result_pdf`), la diagnostica formattata (`tex_result_diagnostics`) e il log completo (`tex_result_log`).
   - Libera le strutture Rust in modo deterministico (`tex_result_free`, `tex_session_free`).
4. **Nessun File Temporaneo**: Nessun file ausiliario (`.aux`, `.log`, `.toc`) viene scritto sul disco fisico dell'utente, prevenendo l'accumulo di file spazzatura e azzerando i colli di bottiglia di I/O.

---

## ✨ Funzionalità dell'Editor

### 1. Esplora Risorse Nativo & Gestione Progetto
- **Albero File e Cartelle**: Visualizzazione gerarchica completa della directory di progetto con icone contestuali per file `.tex`, `.bib`, `.cls`, `.sty` e immagini.
- **Operazioni CRUD Complete**: Creazione di nuovi documenti o cartelle, rinomina contestuale ed eliminazione con conferma nativa.
- **Selettore Entry Point (Master TeX File)**: Menu a tendina che permette di impostare quale file è il documento principale (ad es. `Tesi.tex`). Quando si modifica un capitolo secondario (ad es. `Capitoli/Introduzione.tex`), l'editor inietta istantaneamente le modifiche correnti e ricompila il master, mostrando l'anteprima coerente dell'intera opera.

### 2. Editor del Codice Sorgente Avanzato
- **Padding Generoso & Tipografia Curata**: Area di testo isolata con un margine interno di 32pt orizzontali e 22pt verticali e interlinea proporzionale per una lettura confortevole.
- **Ridimensionamento Dinamico del Testo (`⌘+`, `⌘-`, `⌘0`)**:
  - Premi `⌘+` (o `⌘=`) per aumentare la dimensione del font monospaziato.
  - Premi `⌘-` per diminuire la dimensione del font.
  - Premi `⌘0` per ripristinare la dimensione predefinita (13.5 pt).
  - Indicatore live dei punti (`pt`) e pulsanti stepper integrati direttamente nella barra dell'editor.
- **Zero Flickering al Resize**: Utilizzo di viste layer-backed (`layerContentsRedrawPolicy = .onSetNeedsDisplay`) e sincronizzazione differenziale in memoria: ridimensionare le finestre o lo split avviene a 120 FPS senza scatti né ricalcoli pesanti del layout di testo.

### 3. Visualizzatore Live PDF a Doppio Buffer
- **Eliminazione del Flash a Nero**: Durante la ricompilazione continua, un contenitore specializzato (`SmoothPDFContainerView`) mantiene uno snapshot istantaneo della pagina precedente in overlay e dissolve il nuovo documento solo quando è pronto (0.06s cross-fade). L'anteprima PDF rimane sempre solida, bianca e stabile.
- **Controlli di Zoom e Adattamento**: Zoom In, Zoom Out, Reset al 100% e pulsante *"Fit to Width"* (`arrow.left.and.right`) per adattare le pagine alla larghezza della colonna.
- **Esportazione Diretta**: Pulsante *"Export…"* per salvare il PDF master compilato ovunque sul Mac.

### 4. Strumenti di Formattazione Rapida, Formule & Template
- **Toolbar di Formattazione Rapida**: Grassetto (`\textbf`), corsivo (`\textit`), sottolineato (`\underline`), codice monospazio (`\texttt`).
- **Struttura Documento**: Inserimento con un click di sezioni (`\section`), sottosezioni, liste puntate/numerate, tabelle e figure con didascalia.
- **Menu "Lorem Ipsum"**: Raccolta di template completi pronti all'uso (Articolo Accademico, Formulario Scientifico, Presentazione Beamer, Documento Minimale) e inserimento rapido di paragrafi di testo fittizio per testare l'impaginazione.
- **Palette Matematica Visuale**: Griglia interattiva con lettere greche, simboli relazionali, operatori, frazioni, radici, sommatorie, integrali e matrici.
- **Console Diagnostica e Log TeX**: Drawer inferiore a scomparsa con errori formattati con righe di contesto e registro completo di TeX.

---

## ⌨️ Scorciatoie da Tastiera Principali

| Azione | Scorciatoia | Descrizione |
|---|---|---|
| **Apri Cartella Progetto** | `⌘O` | Apre una directory contenente capitoli e risorse |
| **Apri Singolo File TeX** | `⇧⌘O` | Apre un documento `.tex` individuale |
| **Nuovo Progetto** | `⌘N` | Apre la schermata guidata per un nuovo progetto |
| **Mostra/Nascondi Barra Laterale** | `⌃⌘S` | Toggle animato della sidebar nativa |
| **Ricompila Documento** | `⌘R` | Forza la ricompilazione immediata |
| **Ingrandisci Testo Editor** | `⌘+` (o `⌘=`) | Aumenta la dimensione del font (+1.5 pt) |
| **Rimpicciolisci Testo Editor** | `⌘-` | Diminuisce la dimensione del font (-1.5 pt) |
| **Dimensione Normale Testo** | `⌘0` | Ripristina font a 13.5 pt |
| **Grassetto** | `⌘B` | Applica o inserisce `\textbf{...}` |
| **Corsivo** | `⌘I` | Applica o inserisce `\textit{...}` |
| **Sottolineato** | `⌘U` | Applica o inserisce `\underline{...}` |
| **Codice Monospazio** | `⌘K` | Applica o inserisce `\texttt{...}` |
| **Matematica Inline** | `⇧⌘4` (`⌘$`) | Inserisce `$ ... $` |
| **Equazione in Display** | `⇧⌘E` | Inserisce `\[ ... \]` |
| **Palette Matematica** | `⇧⌘M` | Apre/chiude la palette dei simboli matematici |
| **Console Diagnostica / Log** | `⇧⌘D` | Apre/chiude il pannello degli errori e del log TeX |

---

## 🛠️ Guida alla Compilazione da Sorgenti

### Prerequisiti
- **macOS**: 14.0 (Sonoma) o versione successiva
- **Xcode**: 15.0+ o 16.0+ (con i Command Line Tools installati: `xcode-select --install`)
- **Rust & Cargo**: versione 1.80 o successiva ([rustup.rs](https://rustup.rs))

### 1. Clona il Repository
```bash
git clone https://github.com/leoliu0/ratex.git
cd ratex
```

### 2. Compila la Libreria Rust FFI (`libtex.a`)
Dalla radice del progetto, esegui lo script di compilazione FFI:
```bash
./apps/RatexEditor/Scripts/build_libtex.sh
```
Questo comando compila il crate `crates/libtex` con il profilo `ffi-release` e genera la libreria statica in `target/ffi-release/libtex.a` e il relativo header C `crates/libtex/include/tex.h`.

### 3. Compila ed Esegui l'Applicazione macOS
Puoi aprire il progetto in Xcode:
```bash
open apps/RatexEditor/RatexEditor.xcodeproj
```
Premi **⌘R** per compilare e avviare l'applicazione in modalità Debug.

In alternativa, puoi compilare direttamente da terminale tramite `xcodebuild`:
```bash
xcodebuild -project apps/RatexEditor/RatexEditor.xcodeproj -scheme RatexEditor -configuration Debug build
```

Il binario dell'applicazione compilata sarà disponibile in:
`~/Library/Developer/Xcode/DerivedData/RatexEditor-*/Build/Products/Debug/RatexEditor.app`

---

## 🏛️ Struttura della Cartella `RatexEditor`

```
apps/RatexEditor/
├── RatexEditor.xcodeproj/              # Progetto Xcode nativo per macOS
├── Scripts/
│   └── build_libtex.sh                # Script Bash per compilare il core Rust in libtex.a
└── RatexEditor/
    ├── App/
    │   └── RatexEditorApp.swift        # Entry point dell'app SwiftUI e comandi della barra dei menu
    ├── Bridge/
    │   ├── RatexBridge.h               # Header di bridging Objective-C / C per collegare libtex.a
    │   └── RatexEngine.swift           # Actor Swift per compilazione e gestione sessioni in RAM
    ├── Models/
    │   ├── TeXDocument.swift           # Gestione documenti singoli FileDocument
    │   ├── WorkspaceModel.swift        # Model del workspace: albero file, entry point, watcher
    │   ├── EditorState.swift           # Stato osservabile (@Observable): sorgente, PDF, font size, debouncer
    │   └── Templates.swift             # Template predefiniti e generatori di testo Lorem Ipsum
    ├── Views/
    │   ├── WelcomeView.swift           # Schermata iniziale: progetti recenti, apertura cartelle/file, drag & drop
    │   ├── ProjectSidebarView.swift    # Barra laterale ad albero con operazioni CRUD (nuovo file, rinomina, elimina)
    │   ├── MainSplitView.swift         # Layout split view nativo macOS (NavigationSplitView + HSplitView)
    │   ├── SourceEditorView.swift      # Editor di testo nativo (LaTeXNSTextView) con interlinea, padding e zoom
    │   ├── PDFKitRepresentable.swift   # Visualizzatore PDF nativo a doppio buffer anti-flicker e anti-black flash
    │   ├── EditorToolbar.swift         # Toolbar grafica di formattazione, inserimento, template e selettore master
    │   ├── MathPaletteView.swift       # Palette visiva completa per simboli matematici e formule LaTeX
    │   └── DiagnosticsView.swift       # Drawer inferiore per visualizzare errori di sintassi e log del motore
    └── Resources/
        ├── Info.plist                  # Configurazione bundle, associazioni file .tex e permessi
        └── RatexEditor.entitlements    # Configurazione sandbox e sicurezza macOS
```

---

## 📜 Licenza

Dual-licensed under:
- **MIT License** ([LICENSE-MIT](../../LICENSE-MIT))
- **Apache License, Version 2.0** ([LICENSE-APACHE](../../LICENSE-APACHE))
