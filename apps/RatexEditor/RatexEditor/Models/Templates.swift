import Foundation

public struct TeXTemplate: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let icon: String
    public let description: String
    public let source: String
    
    public static let defaultArticle = TeXTemplate(
        id: "article",
        name: "Academic Article",
        icon: "doc.richtext",
        description: "Standard LaTeX article with title, abstract, math equations, and tables.",
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
Ratex is an ultra-fast, self-contained pure-Rust TeX typesetting engine. This document demonstrates real-time WYSIWYG editing directly within macOS SwiftUI with sub-10ms compilation speeds.
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
Real-time feedback loops enable true WYSIWYG productivity while retaining the typesetting perfection of LaTeX.

\\end{document}
"""
    )
    
    public static let mathCheatSheet = TeXTemplate(
        id: "math",
        name: "Mathematics & Physics",
        icon: "function",
        description: "Template rich in calculus, linear algebra, and physics formulas.",
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
        name: "Minimal Document",
        icon: "doc.text",
        description: "A clean, minimal LaTeX starter.",
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

