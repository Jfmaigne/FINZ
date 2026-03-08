import SwiftUI

public struct FinzHeaderView: View {
    let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        VStack(spacing: 0) {
            Image("finz_logo_couleur")
                .resizable()
                .scaledToFit()
                .frame(height: 130)
                .accessibilityLabel("FINZ")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, -15)
            HStack {
                Text(title)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, -10)
        }
    }
}

public struct FinzHeaderModifier: ViewModifier {
    let title: String
    public func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            FinzHeaderView(title: title)
            content
        }
    }
}

// Extension finzHeader(title:) déplacée dans CommonLayoutModifiers pour unifier le header
// et éviter les conflits d’extension. Cette struct reste disponible si besoin de l’utiliser directement.
