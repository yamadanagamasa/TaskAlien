import SwiftUI

extension Color {
    static let appBackground = Color(red: 0.97, green: 0.96, blue: 0.92)
    static let cardBackground = Color(red: 0.995, green: 0.992, blue: 0.985)
    static let accentInk = Color(red: 0.98, green: 0.73, blue: 0.05)
    static let accentSoft = Color(red: 1.0, green: 0.95, blue: 0.78)
    static let primaryInk = Color(red: 0.12, green: 0.12, blue: 0.13)
    static let secondaryInk = Color(red: 0.38, green: 0.37, blue: 0.34)
}

extension View {
    func appCardStyle(radius: CGFloat = 30) -> some View {
        self
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.primaryInk.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: Color.primaryInk.opacity(0.05), radius: 10, x: 0, y: 6)
    }
}
