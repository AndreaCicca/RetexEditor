# RatexEditor (macOS)

**RatexEditor** è un editor LaTeX nativo per macOS in **SwiftUI** e **PDFKit**, basato sul motore TeX ad altissime prestazioni **ratex** (scritto interamente in Rust).

Grazie alla capacità di `ratex` di compilare documenti LaTeX direttamente in memoria senza invocare sottoprocessi o toccare il disco, RatexEditor offre un'esperienza di **editing WYSIWYG / Live Preview in tempo reale** (< 10-50 ms per ricompilazione).

---

## Caratteristiche Principali

- ⚡ **Compilazione In-Memory Sub-Second**: Anteprima PDF reattiva a ogni battitura o formattazione, mantenendo la posizione di scroll e lo zoom.
- 📦 **100% Autonomo (Zero Dipendenze)**: Include il motore TeX, il formato LaTeX, oltre 24.000 pacchetti e i font matematici standard direttamente nel binario `.app`. Nessuna necessità di installare TeX Live, MacTeX o Rust per usare l'app.
- 🎨 **Toolbar WYSIWYG**: Inserimento istantaneo di formattazione testo (grassetto, corsivo, codice, sottolineato), titoli di sezione (`\section`), elenchi e tabelle con selezione del cursore.
- 📐 **Palette Matematica Visuale**: Griglia interattiva con lettere greche minuscole/maiuscole, operatori, sommatorie, integrali, radici, frazioni e matrici.
- 📄 **Supporto Document-Based macOS**: Gestione nativa dei file `.tex` con apertura, salvataggio, autosave, versioning e finestre multiple.
- 📑 **Template Pronti all'Uso**: Articolo accademico, foglio formule di matematica e fisica, presentazione Beamer e scheletro minimale.
- 🔍 **Pannello Diagnostica & Log TeX**: Drawer a scomparsa con errori di compilazione formattati e log dettagliato.
- 📤 **Esportazione PDF**: Salvataggio diretto del file PDF compilato in qualsiasi cartella del Mac.

---

## Come Aprire ed Eseguire il Progetto

### Prerequisiti
- macOS 14.0 (Sonoma) o successivo
- Xcode 16.0 o successivo (installato con Command Line Tools)
- Rust & Cargo (necessari solo per ricompilare il core Rust `libtex.a`)

### 1. Compilare la Libreria Rust (`libtex.a`)
Dalla cartella principale del repository o tramite lo script dedicato:
```bash
./apps/RatexEditor/Scripts/build_libtex.sh
```
Questo genererà `target/ffi-release/libtex.a` contenente l'API C di ratex.

### 2. Aprire in Xcode
Fai doppio click su `RatexEditor.xcodeproj` oppure esegui da terminale:
```bash
open apps/RatexEditor/RatexEditor.xcodeproj
```

### 3. Eseguire l'Applicazione
- In Xcode, premi **⌘R** (Cmd + R) per avviare l'applicazione.
- In alternativa, compila da linea di comando con:
  ```bash
  xcodebuild -project apps/RatexEditor/RatexEditor.xcodeproj -scheme RatexEditor -configuration Release build
  ```

---

## Scorciatoie da Tastiera

| Azione | Scorciatoia | Descrizione |
|---|---|---|
| **Ricompila Documento** | `⌘R` | Forza la ricompilazione immediata |
| **Grassetto** | `⌘B` | `\textbf{...}` |
| **Corsivo** | `⌘I` | `\textit{...}` |
| **Sottolineato** | `⌘U` | `\underline{...}` |
| **Codice Monospazio** | `⌘K` | `\texttt{...}` |
| **Matematica Inline** | `⇧⌘4` (`⌘$`) | `$ ... $` |
| **Equazione Display** | `⇧⌘E` | `\[ ... \]` |
| **Palette Matematica** | `⇧⌘M` | Mostra/Nasconde la palette simboli |
| **Pannello Diagnostica** | `⇧⌘D` | Mostra/Nasconde console log ed errori |

---

## Architettura del Codice

```
apps/RatexEditor/
├── RatexEditor.xcodeproj/         # Progetto Xcode configurato per macOS
├── Scripts/
│   └── build_libtex.sh           # Script di build per generare libtex.a
└── RatexEditor/
    ├── App/
    │   └── RatexEditorApp.swift   # Entry point DocumentGroup e menu bar
    ├── Bridge/
    │   ├── RatexBridge.h          # Bridging header C ABI
    │   └── RatexEngine.swift      # Swift Actor per la compilazione in memoria
    ├── Models/
    │   ├── TeXDocument.swift      # Conformance a FileDocument per file .tex
    │   ├── EditorState.swift      # Stato osservabile (@Observable) e debouncer
    │   └── Templates.swift        # Modelli predefiniti di documenti LaTeX
    ├── Views/
    │   ├── MainSplitView.swift    # Layout principale split-view
    │   ├── SourceEditorView.swift # NSTextView integrata con selezione e formattazione
    │   ├── PDFKitRepresentable.swift # Viewer PDF nativo con mantenimento scroll
    │   ├── WYSIWYGToolbar.swift   # Barra dei comandi e formattazione
    │   ├── MathPaletteView.swift  # Palette visuale per simboli e formule matematiche
    │   └── DiagnosticsView.swift  # Console diagnostica e log TeX
    └── Resources/
        ├── Info.plist             # Registrazione tipi documento .tex / org.tug.tex
        └── RatexEditor.entitlements # Permessi sandbox macOS
```

