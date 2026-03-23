import SwiftUI

enum ButtonSize { case small, normal }

struct PrimaryButtonStyle: ButtonStyle {
    var size: ButtonSize = .normal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size == .small ? 11 : 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, size == .small ? 10 : 14)
            .padding(.vertical, size == .small ? 5 : 7)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: size == .small ? 6 : 8))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    var size: ButtonSize = .normal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size == .small ? 11 : 13, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, size == .small ? 10 : 14)
            .padding(.vertical, size == .small ? 5 : 7)
            .background(Color.primary.opacity(configuration.isPressed ? 0.1 : 0.07))
            .clipShape(RoundedRectangle(cornerRadius: size == .small ? 6 : 8))
            .overlay(
                RoundedRectangle(cornerRadius: size == .small ? 6 : 8)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
