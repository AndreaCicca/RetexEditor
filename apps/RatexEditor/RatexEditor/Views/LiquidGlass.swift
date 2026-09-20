import SwiftUI
import AppKit

// MARK: - Liquid Glass Design System

/// ViewModifier providing the frosted, specular, layered "Liquid Glass" effect.
public struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    var cornerRadius: CGFloat
    var material: Material
    var isInteractive: Bool
    var isHovered: Bool
    var tint: Color?
    var specularBorderWidth: CGFloat
    
    public init(
        cornerRadius: CGFloat = 10,
        material: Material = .ultraThinMaterial,
        isInteractive: Bool = false,
        isHovered: Bool = false,
        tint: Color? = nil,
        specularBorderWidth: CGFloat = 1.0
    ) {
        self.cornerRadius = cornerRadius
        self.material = material
        self.isInteractive = isInteractive
        self.isHovered = isHovered
        self.tint = tint
        self.specularBorderWidth = specularBorderWidth
    }
    
    public func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base Translucent Material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(material)
                    
                    // Subtle Tint Layer if provided
                    if let tint = tint {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(isHovered ? 0.18 : 0.10))
                    }
                    
                    // Top-to-Bottom Gloss Sheen (Refractive Highlight)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? (isHovered ? 0.14 : 0.08) : (isHovered ? 0.35 : 0.22)),
                                    Color.white.opacity(0.01)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .allowsHitTesting(false)
            }
            .overlay {
                // Specular Light Rim (Border) - explicitly non-blocking for hit testing
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: borderColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: specularBorderWidth
                    )
                    .allowsHitTesting(false)
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? (isHovered ? 0.25 : 0.15) : (isHovered ? 0.10 : 0.05)),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 3 : 1.5
            )
    }
    
    private var borderColors: [Color] {
        if let tint = tint, isHovered {
            return [tint.opacity(0.8), tint.opacity(0.3)]
        }
        
        if colorScheme == .dark {
            return [
                Color.white.opacity(isHovered ? 0.40 : 0.22),
                Color.white.opacity(isHovered ? 0.15 : 0.06)
            ]
        } else {
            return [
                Color.white.opacity(isHovered ? 0.90 : 0.65),
                Color.black.opacity(isHovered ? 0.12 : 0.06)
            ]
        }
    }
}

/// ViewModifier for docked/floating bars (Editor Toolbar, Subheaders, Sidebars).
public struct LiquidGlassBarModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var hasBottomBorder: Bool
    var hasTopHighlight: Bool
    
    public init(hasBottomBorder: Bool = true, hasTopHighlight: Bool = true) {
        self.hasBottomBorder = hasBottomBorder
        self.hasTopHighlight = hasTopHighlight
    }
    
    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                if hasTopHighlight {
                    Rectangle()
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.40))
                        .frame(height: 0.75)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .bottom) {
                if hasBottomBorder {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08))
                        .frame(height: 0.75)
                        .allowsHitTesting(false)
                }
            }
    }
}

// MARK: - View Extensions for Liquid Glass

public extension View {
    /// Applies a standard rounded Liquid Glass surface.
    func liquidGlass(
        cornerRadius: CGFloat = 10,
        material: Material = .ultraThinMaterial,
        isInteractive: Bool = false,
        isHovered: Bool = false,
        tint: Color? = nil
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            material: material,
            isInteractive: isInteractive,
            isHovered: isHovered,
            tint: tint
        ))
    }
    
    /// Applies a Capsule-shaped Liquid Glass surface (ideal for badges, status indicators, steppers).
    func liquidGlassCapsule(
        tint: Color? = nil,
        isHovered: Bool = false,
        material: Material = .ultraThinMaterial
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: 100,
            material: material,
            isInteractive: true,
            isHovered: isHovered,
            tint: tint
        ))
    }
    
    /// Applies the Liquid Glass Bar material (for top toolbars, subheaders, and footer consoles).
    func liquidGlassBar(hasBottomBorder: Bool = true, hasTopHighlight: Bool = true) -> some View {
        modifier(LiquidGlassBarModifier(hasBottomBorder: hasBottomBorder, hasTopHighlight: hasTopHighlight))
    }
    
    /// Applies a Card-style Liquid Glass treatment with interactive hover dynamics.
    func liquidGlassCard(
        cornerRadius: CGFloat = 12,
        isHovered: Bool = false,
        accentTint: Color? = nil
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            material: .ultraThinMaterial,
            isInteractive: true,
            isHovered: isHovered,
            tint: accentTint,
            specularBorderWidth: isHovered ? 1.25 : 1.0
        ))
    }
}
