import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            .uppercased()
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let r: Double
        let g: Double
        let b: Double
        let a: Double

        switch cleaned.count {
        case 8:
            r = Double((int >> 24) & 0xFF) / 255
            g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >> 8) & 0xFF) / 255
            a = Double(int & 0xFF) / 255
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
            a = 1
        default:
            r = 0.247
            g = 0.165
            b = 0.42
            a = 1
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
