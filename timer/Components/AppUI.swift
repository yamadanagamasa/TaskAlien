import SwiftUI

struct AppScreen<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color.primaryInk)
                        .padding(.top, 16)
                }

                content
            }
            .padding(.horizontal, 22)
            .padding(.top, title.isEmpty ? 16 : 0)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            ZStack {
                Color.appBackground.ignoresSafeArea()

                LinearGradient(
                    colors: [Color.accentInk.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            }
        )
    }
}

struct PrimaryActionButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Color.primaryInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.accentInk.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.accentInk.opacity(configuration.isPressed ? 0.04 : 0.09), radius: 10, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryActionButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.primaryInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.cardBackground.opacity(configuration.isPressed ? 0.92 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primaryInk.opacity(0.07), lineWidth: 1)
            )
    }
}

struct AppInputFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primaryInk.opacity(0.07), lineWidth: 1)
            )
    }
}

struct MiniMetricCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.accentInk)

            Spacer(minLength: 12)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.secondaryInk)

            Text(value)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Color.primaryInk)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .appCardStyle(radius: 28)
    }
}

struct SectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(Color.secondaryInk)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.accentInk)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.primaryInk)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.secondaryInk)
            }
        }
        .padding(.vertical, 10)
    }
}
