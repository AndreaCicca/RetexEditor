import Foundation

public struct TeXTemplate: Identifiable, Sendable, Hashable {
    public let id: String
    public var name: String {
        switch id {
        case "article": return String(localized: "Academic Article")
        case "math": return String(localized: "Mathematics & Physics")
        case "blank": return String(localized: "Minimal Document")
        default: return id
        }
    }
    public let icon: String
    public var description: String {
        switch id {
        case "article": return String(localized: "Standard LaTeX article with title, abstract, math equations, and tables.")
        case "math": return String(localized: "Template rich in calculus, linear algebra, and physics formulas.")
        case "blank": return String(localized: "A clean, minimal LaTeX starter.")
        default: return ""
        }
    }
    public let source: String
    
    public init(id: String, icon: String, source: String) {
        self.id = id
        self.icon = icon
        self.source = source
    }
    
    public static var article: TeXTemplate { defaultArticle }
    
    public static let defaultArticle = TeXTemplate(
        id: "article",
        icon: "doc.richtext",
        source: """
\\documentclass[11pt]{article}
\\usepackage{amsmath}
\\usepackage{amssymb}
\\usepackage{booktabs}

\\title{\\textbf{High-Performance Typesetting with Ratex}}
\\author{Ratex Team}
\\date{\\today}

\\begin{document}

\\maketitle

\\begin{abstract}
Ratex is an ultra-fast, self-contained pure-Rust TeX typesetting engine. This document demonstrates real-time live preview editing directly within macOS SwiftUI with sub-10ms compilation speeds.
\\end{abstract}

\\section{Introduction}
Traditional TeX compilation requires external toolchains and multi-second build cycles. By leveraging an embedded Rust engine directly via C FFI, this editor compiles documents instantly in memory.

\\section{Mathematical Formulations}
Ratex natively supports complex AMS math syntax:

\\begin{equation}
\\int_{-\\infty}^{\\infty} e^{-x^2} \\, dx = \\sqrt{\\pi}
\\end{equation}

Here is a system of equations with a matrix:
\\begin{equation}
\\begin{pmatrix}
\\cos\\theta & -\\sin\\theta \\\\
\\sin\\theta & \\cos\\theta
\\end{pmatrix}
\\begin{pmatrix}
x \\\\
y
\\end{pmatrix}
=
\\begin{pmatrix}
x' \\\\
y'
\\end{pmatrix}
\\end{equation}

\\section{Results \\& Tables}
Below is an example of a benchmark table:

\\begin{center}
\\begin{tabular}{lrr}
\\toprule
\\textbf{Engine} & \\textbf{Passes} & \\textbf{Compile Time} \\\\
\\midrule
Legacy pdfTeX & 2 & 1420 ms \\\\
Ratex Native  & 2 & 12 ms \\\\
\\bottomrule
\\end{tabular}
\\end{center}

\\section{Conclusion}
Real-time feedback loops enable instant preview productivity while retaining the typesetting perfection of LaTeX.

\\end{document}
"""
    )
    
    public static let mathCheatSheet = TeXTemplate(
        id: "math",
        icon: "function",
        source: """
\\documentclass[12pt]{article}
\\usepackage{amsmath}
\\usepackage{amssymb}

\\title{\\textbf{Mathematics \\& Physics Formula Sheet}}
\\author{Quick Reference}
\\date{\\today}

\\begin{document}
\\maketitle

\\section{Calculus \\& Analysis}
\\subsection{Taylor Series}
The Taylor series expansion of a smooth function $f(x)$ around $a$:
\\[
f(x) = \\sum_{n=0}^{\\infty} \\frac{f^{(n)}(a)}{n!} (x - a)^n
\\]

\\subsection{Fourier Transform}
\\[
\\hat{f}(\\xi) = \\int_{-\\infty}^{\\infty} f(x) e^{-2\\pi i x \\xi} \\, dx
\\]

\\section{Electromagnetism (Maxwell's Equations)}
\\begin{align}
\\nabla \\cdot \\mathbf{E} &= \\frac{\\rho}{\\varepsilon_0} \\\\
\\nabla \\cdot \\mathbf{B} &= 0 \\\\
\\nabla \\times \\mathbf{E} &= -\\frac{\\partial \\mathbf{B}}{\\partial t} \\\\
\\nabla \\times \\mathbf{B} &= \\mu_0 \\mathbf{J} + \\mu_0 \\varepsilon_0 \\frac{\\partial \\mathbf{E}}{\\partial t}
\\end{align}

\\section{Quantum Mechanics}
The time-dependent Schr\\"odinger equation:
\\[
i\\hbar \\frac{\\partial}{\\partial t} \\Psi(\\mathbf{r}, t) = \\left( -\\frac{\\hbar^2}{2m} \\nabla^2 + V(\\mathbf{r}, t) \\right) \\Psi(\\mathbf{r}, t)
\\]

\\end{document}
"""
    )
    
    public static let blank = TeXTemplate(
        id: "blank",
        icon: "doc.text",
        source: """
\\documentclass{article}

\\begin{document}
\\section{Hello World}
Welcome to your new document! Start writing here.
\\end{document}
"""
    )
    
    public static let all: [TeXTemplate] = [defaultArticle, mathCheatSheet, blank]
}

