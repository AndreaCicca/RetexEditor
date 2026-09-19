import SwiftUI

public struct MathSymbol: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let latex: String
    
    public init(_ label: String, _ latex: String) {
        self.id = latex
        self.label = label
        self.latex = latex
    }
}

public struct MathPaletteView: View {
    @Bindable var state: EditorState
    @State private var selectedTab = 0
    
    private let greekLower: [MathSymbol] = [
        .init("α", "\\alpha "), .init("β", "\\beta "), .init("γ", "\\gamma "),
        .init("δ", "\\delta "), .init("ε", "\\varepsilon "), .init("ζ", "\\zeta "),
        .init("η", "\\eta "), .init("θ", "\\theta "), .init("ι", "\\iota "),
        .init("κ", "\\kappa "), .init("λ", "\\lambda "), .init("μ", "\\mu "),
        .init("ν", "\\nu "), .init("ξ", "\\xi "), .init("π", "\\pi "),
        .init("ρ", "\\rho "), .init("σ", "\\sigma "), .init("τ", "\\tau "),
        .init("υ", "\\upsilon "), .init("φ", "\\phi "), .init("χ", "\\chi "),
        .init("ψ", "\\psi "), .init("ω", "\\omega ")
    ]
    
    private let greekUpper: [MathSymbol] = [
        .init("Γ", "\\Gamma "), .init("Δ", "\\Delta "), .init("Θ", "\\Theta "),
        .init("Λ", "\\Lambda "), .init("Ξ", "\\Xi "), .init("Π", "\\Pi "),
        .init("Σ", "\\Sigma "), .init("Υ", "\\Upsilon "), .init("Φ", "\\Phi "),
        .init("Ψ", "\\Psi "), .init("Ω", "\\Omega ")
    ]
    
    private let operators: [MathSymbol] = [
        .init("±", "\\pm "), .init("×", "\\times "), .init("÷", "\\div "),
        .init("·", "\\cdot "), .init("≤", "\\le "), .init("≥", "\\ge "),
        .init("≠", "\\ne "), .init("≈", "\\approx "), .init("≡", "\\equiv "),
        .init("∈", "\\in "), .init("∉", "\\notin "), .init("⊂", "\\subset "),
        .init("⊆", "\\subseteq "), .init("∪", "\\cup "), .init("∩", "\\cap "),
        .init("∀", "\\forall "), .init("∃", "\\exists "), .init("¬", "\\neg ")
    ]
    
    private let calculus: [MathSymbol] = [
        .init("∫", "\\int_{a}^{b} "), .init("∬", "\\iint "), .init("∮", "\\oint "),
        .init("∑", "\\sum_{i=1}^{n} "), .init("∏", "\\prod_{i=1}^{n} "),
        .init("lim", "\\lim_{x \\to \\infty} "), .init("∂", "\\partial "),
        .init("∇", "\\nabla "), .init("∞", "\\infty "), .init("→", "\\to ")
    ]
    
    private let structures: [(label: String, latex: String)] = [
        ("Fraction \\frac{a}{b}", "\\frac{a}{b}"),
        ("Square Root \\sqrt{x}", "\\sqrt{x}"),
        ("N-th Root \\sqrt[n]{x}", "\\sqrt[n]{x}"),
        ("Subscript x_i", "x_{i}"),
        ("Superscript x^2", "x^{2}"),
        ("Vector \\vec{v}", "\\vec{v}"),
        ("Hat \\hat{x}", "\\hat{x}"),
        ("Bar \\bar{x}", "\\bar{x}"),
        ("Paren \\left( \\dots \\right)", "\\left( \\dots \\right)"),
        ("Bracket \\left[ \\dots \\right]", "\\left[ \\dots \\right]")
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("LaTeX Math Palette", systemImage: "function")
                    .font(.headline)
                Spacer()
                Button(action: { state.isMathPaletteOpen = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)
            
            Picker("Category", selection: $selectedTab) {
                Text("Greek").tag(0)
                Text("Operators").tag(1)
                Text("Calculus").tag(2)
                Text("Structures").tag(3)
            }
            .pickerStyle(.segmented)
            
            ScrollView(.vertical, showsIndicators: true) {
                switch selectedTab {
                case 0:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lowercase").font(.caption).foregroundStyle(.secondary)
                        symbolGrid(greekLower)
                        Divider().padding(.vertical, 4)
                        Text("Uppercase").font(.caption).foregroundStyle(.secondary)
                        symbolGrid(greekUpper)
                    }
                case 1:
                    symbolGrid(operators)
                case 2:
                    symbolGrid(calculus)
                case 3:
                    VStack(spacing: 6) {
                        ForEach(structures, id: \.label) { item in
                            Button(action: {
                                state.insertText(item.latex)
                            }) {
                                HStack {
                                    Text(item.label)
                                        .font(.system(.body, design: .monospaced))
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.tint)
                                }
                                .padding(6)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                default:
                    EmptyView()
                }
            }
            .frame(maxHeight: 280)
        }
        .padding(12)
        .frame(width: 320)
    }
    
    private func symbolGrid(_ symbols: [MathSymbol]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 36, maximum: 44))], spacing: 6) {
            ForEach(symbols) { sym in
                Button(action: {
                    state.insertText(sym.latex)
                }) {
                    Text(sym.label)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 36, height: 36)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .help(sym.latex)
            }
        }
    }
}

