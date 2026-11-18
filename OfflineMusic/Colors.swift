import SwiftUI

// MARK: - Streaming-app color palette
//
// Deep black/charcoal background with the vibrant green accent used by
// modern streaming apps. All colors are defined as static let values so
// they can be referenced anywhere without a namespace.

enum AppColor {
    // Backgrounds
    static let bg = Color(hex: 0x121212)          // deep black
    static let bgElevated = Color(hex: 0x1E1E1E)  // card / sheet surface
    static let bgHover = Color(hex: 0x2A2A2A)     // pressed / hovered row

    // Text
    static let primaryText = Color.white
    static let secondaryText = Color(hex: 0xB3B3B3)
    static let mutedText = Color(hex: 0x727272)

    // Accent
    static let accent = Color(hex: 0x1DB954)       // vibrant green
    static let accentHover = Color(hex: 0x1ED760)
    static let accentDim = Color(hex: 0x14633A)

    // Status
    static let success = Color(hex: 0x1DB954)
    static let warning = Color(hex: 0xFBC02D)
    static let error = Color(hex: 0xE23137)
}

extension Color {
    init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            .sRGB,
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Convenience modifiers

extension View {
    /// Applies the deep-black streaming background.
    func appBackground() -> some View {
        self.background(AppColor.bg.ignoresSafeArea())
    }

    /// Standard card surface.
    func appCard() -> some View {
        self.background(AppColor.bgElevated)
            .cornerRadius(12)
    }
}