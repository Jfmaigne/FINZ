import SwiftUI

struct StickyNextButton: ViewModifier {
    var enabled: Bool
    var title: String = "Suivant"
    var action: () -> Void

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Button(action: action) {
                        Text(title)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .primaryButtonStyle(enabled: enabled)
                    .disabled(!enabled)
                }
                .padding(.horizontal)
                .padding(.top, 6)
                .background(.ultraThinMaterial)
            }
    }
}

extension View {
    func stickyNextButton(enabled: Bool, title: String = "Suivant", action: @escaping () -> Void) -> some View {
        self.modifier(StickyNextButton(enabled: enabled, title: title, action: action))
    }
}

struct FinzHeader: ViewModifier {
    var title: String? = nil

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
                .padding(.top, title != nil ? 130 : 100)
            
            VStack(spacing: 0) {
                Image("finz_logo_couleur")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 130)
                    .accessibilityLabel("Finz")
                    .padding(.top, -30)
                
                if let title = title {
                    Text(title)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, -10)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.clear)
        }
    }
}

extension View {
    func finzHeader(title: String? = nil) -> some View { self.modifier(FinzHeader(title: title)) }
}
