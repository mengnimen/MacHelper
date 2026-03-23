import SwiftUI

enum Page { case main, settings }

struct ContentView: View {
    @StateObject private var vm = AppViewModel()
    @State private var currentPage: Page = .main
    @State private var showAbout = false
    @State private var colorScheme: ColorScheme = .dark
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Mac小助手")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    TBIconButton(icon: "house.fill", active: currentPage == .main) {
                        currentPage = .main
                    }
                    TBIconButton(icon: "gearshape.fill", active: currentPage == .settings) {
                        currentPage = .settings
                    }
                    TBIconButton(icon: "info.circle.fill", active: false) {
                        showAbout = true
                    }
                    Divider()
                        .frame(height: 16)
                        .padding(.horizontal, 2)
                    TBIconButton(
                        icon: colorScheme == .dark ? "moon.fill" : "sun.max.fill",
                        active: false
                    ) {
                        colorScheme = colorScheme == .dark ? .light : .dark
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(Divider(), alignment: .bottom)

            ScrollView {
                if currentPage == .main {
                    MainPageView()
                        .environmentObject(vm)
                        .padding(18)
                } else {
                    SettingsPageView()
                        .environmentObject(vm)
                        .padding(18)
                }
            }
            .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
        }
        .preferredColorScheme(colorScheme)
        .frame(width: 520)
        .onAppear {
            colorScheme = systemColorScheme
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
                .preferredColorScheme(colorScheme)
        }
    }
}

// MARK: - 图标按钮
struct TBIconButton: View {
    let icon: String
    let active: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(active ? .accentColor : .secondary)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(active
                              ? Color.accentColor.opacity(0.12)
                              : (hovering ? Color.primary.opacity(0.08) : Color.clear))
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

// MARK: - Color helpers
extension Color {
    static var cardSurface: Color { Color(NSColor.windowBackgroundColor) }

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double(rgb         & 0xFF) / 255
        )
    }
}
