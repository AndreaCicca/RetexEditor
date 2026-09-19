import SwiftUI

@main
struct RatexEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TeXDocument()) { file in
            DocumentWindow(document: file.$document)
        }
        .commands {
            CommandMenu("Typeset") {
                Button("Recompile Document") {
                    NotificationCenter.default.post(name: .recompileRequested, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])
                
                Divider()
                
                Button("Toggle Math Palette") {
                    NotificationCenter.default.post(name: .toggleMathPaletteRequested, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                
                Button("Toggle Diagnostics Drawer") {
                    NotificationCenter.default.post(name: .toggleDiagnosticsRequested, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            
            CommandMenu("Format (TeX)") {
                Button("Bold (\\textbf)") {
                    NotificationCenter.default.post(name: .formatBoldRequested, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command])
                
                Button("Italic (\\textit)") {
                    NotificationCenter.default.post(name: .formatItalicRequested, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command])
                
                Button("Underline (\\underline)") {
                    NotificationCenter.default.post(name: .formatUnderlineRequested, object: nil)
                }
                .keyboardShortcut("u", modifiers: [.command])
                
                Button("Monospace Code (\\texttt)") {
                    NotificationCenter.default.post(name: .formatCodeRequested, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])
                
                Divider()
                
                Button("Inline Math ($...$)") {
                    NotificationCenter.default.post(name: .formatInlineMathRequested, object: nil)
                }
                .keyboardShortcut("4", modifiers: [.command, .shift]) // Cmd+$
                
                Button("Display Equation (\\[...\\])") {
                    NotificationCenter.default.post(name: .formatDisplayMathRequested, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }
}

struct DocumentWindow: View {
    @Binding var document: TeXDocument
    @State private var state: EditorState
    
    init(document: Binding<TeXDocument>) {
        self._document = document
        self._state = State(initialValue: EditorState(source: document.wrappedValue.text))
    }
    
    var body: some View {
        MainSplitView(state: state, document: $document)
            .frame(minWidth: 800, minHeight: 600)
            .onReceive(NotificationCenter.default.publisher(for: .recompileRequested)) { _ in
                Task { @MainActor in
                    await state.compileImmediate()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleMathPaletteRequested)) { _ in
                state.isMathPaletteOpen.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleDiagnosticsRequested)) { _ in
                state.isDiagnosticsDrawerOpen.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .formatBoldRequested)) { _ in
                state.applyBold()
            }
            .onReceive(NotificationCenter.default.publisher(for: .formatItalicRequested)) { _ in
                state.applyItalic()
            }
            .onReceive(NotificationCenter.default.publisher(for: .formatUnderlineRequested)) { _ in
                state.applyUnderline()
            }
            .onReceive(NotificationCenter.default.publisher(for: .formatCodeRequested)) { _ in
                state.applyCode()
            }
            .onReceive(NotificationCenter.default.publisher(for: .formatInlineMathRequested)) { _ in
                state.insertInlineMath()
            }
            .onReceive(NotificationCenter.default.publisher(for: .formatDisplayMathRequested)) { _ in
                state.insertDisplayMath()
            }
    }
}

extension Notification.Name {
    static let recompileRequested = Notification.Name("ratex.recompileRequested")
    static let toggleMathPaletteRequested = Notification.Name("ratex.toggleMathPaletteRequested")
    static let toggleDiagnosticsRequested = Notification.Name("ratex.toggleDiagnosticsRequested")
    static let formatBoldRequested = Notification.Name("ratex.formatBoldRequested")
    static let formatItalicRequested = Notification.Name("ratex.formatItalicRequested")
    static let formatUnderlineRequested = Notification.Name("ratex.formatUnderlineRequested")
    static let formatCodeRequested = Notification.Name("ratex.formatCodeRequested")
    static let formatInlineMathRequested = Notification.Name("ratex.formatInlineMathRequested")
    static let formatDisplayMathRequested = Notification.Name("ratex.formatDisplayMathRequested")
}

