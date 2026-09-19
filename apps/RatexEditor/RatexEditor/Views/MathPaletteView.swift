import SwiftUI

public struct MathSymbol: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let latex: String
    public let description: String
    
    public init(_ label: String, _ latex: String, _ desc: String = "") {
        self.id = latex
        self.label = label
        self.latex = latex
        self.description = desc.isEmpty ? latex : desc
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

    private let gridColumns = [GridItem(.adaptive(minimum: 38, maximum: 44), spacing: 6)]

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Label("LaTeX Math Symbols", systemImage: "function")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: { state.isMathPaletteOpen = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 2)
            
            // Category Tabs
            Picker("Category", selection: $selectedTab) {
                Text("Greek").tag(0)
                Text("Operators").tag(1)
                Text("Calculus").tag(2)
                Text("Structures").tag(3)
            }
            .pickerStyle(.segmented)
            
            // Content Container
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 12) {
                    switch selectedTab {
                    case 0:
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Lowercase")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: gridColumns, spacing: 6) {
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
                            LazyVGrid(columns: gridColumns, spacing: 6) {
                                ForEach(greekUpper) { sym in
                                    SymbolButton(symbol: sym) {
                                        state.insertText(sym.latex)
                                    }
                                }
                            }
                        }
                    case 1:
                        LazyVGrid(columns: gridColumns, spacing: 6) {
                            ForEach(operators) { sym in
                                SymbolButton(symbol: sym) {
                                    state.insertText(sym.latex)
                                }
                            }
                        }
                    case 2:
                        LazyVGrid(columns: gridColumns, spacing: 6) {
                            ForEach(calculus) { sym in
                                SymbolButton(symbol: sym) {
                                    state.insertText(sym.latex)
                                }
                            }
                        }
                    case 3:
                        VStack(spacing: 6) {
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
                .padding(.trailing, 4)
            }
            .frame(height: 290)
        }
        .padding(14)
        .frame(width: 410, height: 370)
    }
}

// Reusable symbol button with hover effect
struct SymbolButton: View {
    let symbol: MathSymbol
    let onSelect: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            Text(symbol.label)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isHovered ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(symbol.description)
    }
}

// Reusable structure/template button with hover effect
struct StructureButton: View {
    let title: String
    let latex: String
    let preview: String
    let onSelect: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(preview)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .frame(width: 36, height: 28)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(4)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                    Text(latex)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(isHovered ? Color.accentColor : Color.secondary.opacity(0.6))
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isHovered ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
