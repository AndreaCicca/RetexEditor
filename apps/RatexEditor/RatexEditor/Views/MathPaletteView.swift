import SwiftUI

public struct MathSymbol: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let latex: String
    private let rawDescription: String
    
    public var description: String {
        rawDescription.isEmpty ? latex : String(localized: String.LocalizationValue(rawDescription))
    }
    
    public init(_ label: String, _ latex: String, _ desc: String = "") {
        self.id = latex
        self.label = label
        self.latex = latex
        self.rawDescription = desc
    }
}

public struct MathPaletteView: View {
    @Bindable var state: EditorState
    @State private var selectedTab = 0
    
    private let greekLower: [MathSymbol] = [
        .init("α", "\\alpha ", "alpha"), .init("β", "\\beta ", "beta"), .init("γ", "\\gamma ", "gamma"),
        .init("δ", "\\delta ", "delta"), .init("ε", "\\varepsilon ", "epsilon"), .init("ζ", "\\zeta ", "zeta"),
        .init("η", "\\eta ", "eta"), .init("θ", "\\theta ", "theta"), .init("ι", "\\iota ", "iota"),
        .init("κ", "\\kappa ", "kappa"), .init("λ", "\\lambda ", "lambda"), .init("μ", "\\mu ", "mu"),
        .init("ν", "\\nu ", "nu"), .init("ξ", "\\xi ", "xi"), .init("π", "\\pi ", "pi"),
        .init("ρ", "\\rho ", "rho"), .init("σ", "\\sigma ", "sigma"), .init("τ", "\\tau ", "tau"),
        .init("υ", "\\upsilon ", "upsilon"), .init("φ", "\\phi ", "phi"), .init("χ", "\\chi ", "chi"),
        .init("ψ", "\\psi ", "psi"), .init("ω", "\\omega ", "omega")
    ]
    
    private let greekUpper: [MathSymbol] = [
        .init("Γ", "\\Gamma ", "Gamma"), .init("Δ", "\\Delta ", "Delta"), .init("Θ", "\\Theta ", "Theta"),
        .init("Λ", "\\Lambda ", "Lambda"), .init("Ξ", "\\Xi ", "Xi"), .init("Π", "\\Pi ", "Pi"),
        .init("Σ", "\\Sigma ", "Sigma"), .init("Υ", "\\Upsilon ", "Upsilon"), .init("Φ", "\\Phi ", "Phi"),
        .init("Ψ", "\\Psi ", "Psi"), .init("Ω", "\\Omega ", "Omega")
    ]
    
    private let operators: [MathSymbol] = [
        .init("±", "\\pm ", "plus-minus"), .init("×", "\\times ", "times"), .init("÷", "\\div ", "divide"),
        .init("·", "\\cdot ", "centered dot"), .init("≤", "\\le ", "less or equal"), .init("≥", "\\ge ", "greater or equal"),
        .init("≠", "\\ne ", "not equal"), .init("≈", "\\approx ", "approximately"), .init("≡", "\\equiv ", "equivalent"),
        .init("∈", "\\in ", "element of"), .init("∉", "\\notin ", "not element of"), .init("⊂", "\\subset ", "subset"),
        .init("⊆", "\\subseteq ", "subset or equal"), .init("∪", "\\cup ", "union"), .init("∩", "\\cap ", "intersection"),
        .init("∀", "\\forall ", "for all"), .init("∃", "\\exists ", "exists"), .init("¬", "\\neg ", "negation"),
        .init("∝", "\\propto ", "proportional"), .init("⊥", "\\perp ", "perpendicular"), .init("∥", "\\parallel ", "parallel"),
        .init("→", "\\to ", "right arrow"), .init("⇒", "\\Rightarrow ", "implies"), .init("⇔", "\\iff ", "if and only if")
    ]
    
    private let calculus: [MathSymbol] = [
        .init("∫", "\\int ", "integral"), .init("∫_a^b", "\\int_{a}^{b} ", "definite integral"),
        .init("∬", "\\iint ", "double integral"), .init("∮", "\\oint ", "contour integral"),
        .init("∑", "\\sum ", "summation"), .init("∑_i^n", "\\sum_{i=1}^{n} ", "indexed sum"),
        .init("∏", "\\prod ", "product"), .init("∏_i^n", "\\prod_{i=1}^{n} ", "indexed product"),
        .init("lim", "\\lim_{x \\to \\infty} ", "limit"), .init("∂", "\\partial ", "partial derivative"),
        .init("∇", "\\nabla ", "nabla / gradient"), .init("∞", "\\infty ", "infinity"),
        .init("dx", "\\, dx", "differential dx"), .init("dt", "\\, dt", "differential dt"),
        .init("prime", "^{\\prime}", "prime notation")
    ]
    
    private let structures: [(title: String, latex: String, preview: String)] = [
        ("Fraction", "\\frac{a}{b}", "a/b"),
        ("Square Root", "\\sqrt{x}", "√x"),
        ("N-th Root", "\\sqrt[n]{x}", "ⁿ√x"),
        ("Subscript", "x_{i}", "xᵢ"),
        ("Superscript", "x^{2}", "x²"),
        ("Vector Arrow", "\\vec{v}", "v⃗"),
        ("Matrix 2x2", "\\begin{pmatrix}\n  a & b \\\\\n  c & d\n\\end{pmatrix}", "[ ]"),
        ("Determinant 2x2", "\\begin{vmatrix}\n  a & b \\\\\n  c & d\n\\end{vmatrix}", "| |"),
        ("Piecewise Cases", "\\begin{cases}\n  x & \\text{if } x \\ge 0 \\\\\n  -x & \\text{otherwise}\n\\end{cases}", "{"),
        ("Scaled Parentheses", "\\left( \\frac{a}{b} \\right)", "( )"),
        ("Scaled Brackets", "\\left[ \\frac{a}{b} \\right]", "[ ]"),
        ("Text inside Math", "\\text{word}", "abc")
    ]

    private let gridColumns = [GridItem(.adaptive(minimum: 40, maximum: 44), spacing: 8)]

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("LaTeX Math Symbols", systemImage: "function")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: { state.isMathPaletteOpen = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.glass)
                .controlSize(.mini)
            }
            
            // Category Tabs (Liquid Glass Sliding Selector)
            GlassCategorySelector(selectedTab: $selectedTab)
            
            // Scrollable Symbols & Structures
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 14) {
                    switch selectedTab {
                    case 0:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Lowercase")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: gridColumns, spacing: 8) {
                                ForEach(greekLower) { sym in
                                    SymbolButton(symbol: sym) {
                                        state.insertText(sym.latex)
                                    }
                                }
                            }
                            
                            Divider().padding(.vertical, 4)
                            
                            Text("Uppercase")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: gridColumns, spacing: 8) {
                                ForEach(greekUpper) { sym in
                                    SymbolButton(symbol: sym) {
                                        state.insertText(sym.latex)
                                    }
                                }
                            }
                        }
                    case 1:
                        LazyVGrid(columns: gridColumns, spacing: 8) {
                            ForEach(operators) { sym in
                                SymbolButton(symbol: sym) {
                                    state.insertText(sym.latex)
                                }
                            }
                        }
                    case 2:
                        LazyVGrid(columns: gridColumns, spacing: 8) {
                            ForEach(calculus) { sym in
                                SymbolButton(symbol: sym) {
                                    state.insertText(sym.latex)
                                }
                            }
                        }
                    case 3:
                        VStack(spacing: 8) {
                            ForEach(structures, id: \.title) { item in
                                StructureButton(
                                    title: item.title,
                                    latex: item.latex,
                                    preview: item.preview
                                ) {
                                    state.insertText(item.latex)
                                }
                            }
                        }
                    default:
                        EmptyView()
                    }
                }
                .padding(.leading, 2)
                .padding(.trailing, 16)
                .padding(.vertical, 4)
            }
            .frame(height: 310)
        }
        .padding(14)
        .frame(width: 420, height: 400)
    }
}

// MARK: - Liquid Glass Sliding Tab Selector

struct GlassCategorySelector: View {
    @Binding var selectedTab: Int
    @Namespace private var tabNamespace
    
    private let tabs: [(id: Int, title: String, icon: String)] = [
        (0, "Greek", "character.textbox"),
        (1, "Operators", "plusminus"),
        (2, "Calculus", "function"),
        (3, "Structures", "square.stack.3d.up")
    ]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.id) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        selectedTab = tab.id
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(LocalizedStringKey(tab.title))
                            .font(.system(size: 11, weight: selectedTab == tab.id ? .semibold : .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .background {
                    if selectedTab == tab.id {
                        Capsule()
                            .fill(Color.accentColor.opacity(0.16))
                            .glassEffect(.regular, in: .capsule)
                            .matchedGeometryEffect(id: "activeTabGlassPill", in: tabNamespace)
                    }
                }
                .foregroundStyle(selectedTab == tab.id ? Color.primary : Color.secondary)
            }
        }
        .padding(3)
        .glassEffect(.regular, in: .capsule)
    }
}

// MARK: - Reusable Symbol & Structure Buttons

struct SymbolButton: View {
    let symbol: MathSymbol
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            Text(symbol.label)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .frame(width: 40, height: 38)
        }
        .buttonStyle(.glass)
        .help(symbol.description)
    }
}

struct StructureButton: View {
    let title: String
    let latex: String
    let preview: String
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(preview)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .frame(width: 36, height: 28)
                    .glassEffect(.regular, in: .rect(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(.system(size: 12, weight: .semibold))
                    Text(latex)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .buttonStyle(.glass)
    }
}
