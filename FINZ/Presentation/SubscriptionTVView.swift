import SwiftUI
import UIKit

struct SubscriptionTVView: View {
    var onCompleted: () -> Void = {}

    @EnvironmentObject private var vm: QuestionnaireViewModel

    private struct Option: Identifiable, Hashable {
        let id = UUID()
        let type: QuestionnaireViewModel.SubscriptionTVType
        let assetName: String
        let fallbackSystemName: String
        let remoteLogoURL: String?
        let title: String
    }

    private let options: [Option] = [
        Option(type: .Netflix,     assetName: "logo_netflix",      fallbackSystemName: "film",            remoteLogoURL: "https://logo.clearbit.com/netflix.com",      title: "Netflix"),
        Option(type: .CanalPlus,   assetName: "logo_canal_plus",   fallbackSystemName: "play.rectangle",  remoteLogoURL: "https://logo.clearbit.com/canalplus.com",    title: "Canal+"),
        Option(type: .BeinSport,   assetName: "logo_beinsport",    fallbackSystemName: "sportscourt",     remoteLogoURL: "https://logo.clearbit.com/beinsports.com",   title: "BeIN Sports"),
        Option(type: .AmazonPrime, assetName: "logo_amazon_prime", fallbackSystemName: "play.rectangle",  remoteLogoURL: "https://logo.clearbit.com/primevideo.com",   title: "Amazon Prime"),
        Option(type: .Other,       assetName: "logo_tv_other",     fallbackSystemName: "questionmark",    remoteLogoURL: nil,                                           title: "Autre")
    ]

    private var canProceed: Bool { !vm.selectedSubscriptionsTV.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("TV / Streaming vidéo")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(options) { option in
                        SubscriptionTVOptionCard(
                            assetName: option.assetName,
                            fallbackSystemName: option.fallbackSystemName,
                            remoteLogoURL: option.remoteLogoURL,
                            title: option.title,
                            selected: vm.selectedSubscriptionsTV.contains(option.type),
                            action: { toggle(option.type) }
                        )
                    }
                }

                Text("Tu peux sélectionner plusieurs options.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                if !canProceed {
                    Text("Sélectionne au moins une option pour continuer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .safeAreaPadding(.bottom, 200)
            .padding(.horizontal)
            .padding(.top, 4)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.08),
                    Color.pink.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .finzHeader(title: "Abonnements TV")
        .stickyNextButton(enabled: canProceed, action: onNext)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ type: QuestionnaireViewModel.SubscriptionTVType) {
        let willSelect = !vm.selectedSubscriptionsTV.contains(type)
        let generator = UIImpactFeedbackGenerator(style: willSelect ? .medium : .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if vm.selectedSubscriptionsTV.contains(type) {
                vm.selectedSubscriptionsTV.remove(type)
            } else {
                vm.selectedSubscriptionsTV.insert(type)
            }
        }
    }

    private func onNext() {
        // Notify parent to push next step
        onCompleted()
    }
}

struct SubscriptionTVOptionCard: View {
    let assetName: String
    let fallbackSystemName: String
    let remoteLogoURL: String?
    let title: String
    let selected: Bool
    let action: () -> Void

    @State private var pulsing = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                pulsing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.15)) {
                    pulsing = false
                }
            }
            action()
        }) {
            VStack(spacing: 6) {
                BrandImage(assetName: assetName, fallbackSystemName: fallbackSystemName, remoteLogoURL: remoteLogoURL)
                    .frame(width: 50, height: 50)
                    .padding(14)
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 118)
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: selected ? [Color.blue, Color.purple, Color.pink]
                                            : [Color(.secondarySystemBackground), Color(.secondarySystemBackground)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .shadow(color: selected ? Color.pink.opacity(0.2) : Color.black.opacity(0.05), radius: selected ? 8 : 3, x: 0, y: selected ? 6 : 2)
            .animation(.easeInOut(duration: 0.2), value: selected)
        }
        .buttonStyle(.plain)
    }
}

private struct BrandImage: View {
    let assetName: String
    let fallbackSystemName: String
    let remoteLogoURL: String?

    var body: some View {
        if let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else if let domain = extractDomain(from: remoteLogoURL) {
            GoogleFaviconView(domain: domain, fallbackSystemName: fallbackSystemName)
        } else {
            Image(systemName: fallbackSystemName)
                .resizable()
                .scaledToFit()
        }
    }

    private func extractDomain(from remoteLogoURL: String?) -> String? {
        guard let remoteLogoURL else { return nil }
        if let url = URL(string: remoteLogoURL) {
            if let host = url.host, host.contains("logo.clearbit.com") {
                let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                return path.isEmpty ? nil : path
            }
            return url.host ?? remoteLogoURL
        } else {
            return remoteLogoURL
        }
    }
}

private struct ClearbitLogoView: View {
    let domain: String
    let fallbackSystemName: String

    var body: some View {
        if let clearbit = URL(string: "https://logo.clearbit.com/\(domain)") {
            AsyncImage(url: clearbit) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Image(systemName: fallbackSystemName).resizable().scaledToFit()
                case .empty:
                    ProgressView()
                @unknown default:
                    Image(systemName: fallbackSystemName).resizable().scaledToFit()
                }
            }
        } else {
            DuckDuckGoFaviconView(domain: domain, fallbackSystemName: fallbackSystemName)
        }
    }
}

private struct DuckDuckGoFaviconView: View {
    let domain: String
    let fallbackSystemName: String

    var body: some View {
        if let duck = URL(string: "https://icons.duckduckgo.com/ip3/\(domain).ico") {
            AsyncImage(url: duck) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    ClearbitLogoView(domain: domain, fallbackSystemName: fallbackSystemName)
                case .empty:
                    ProgressView()
                @unknown default:
                    Image(systemName: fallbackSystemName).resizable().scaledToFit()
                }
            }
        } else {
            GoogleFaviconView(domain: domain, fallbackSystemName: fallbackSystemName)
        }
    }
}

private struct GoogleFaviconView: View {
    let domain: String
    let fallbackSystemName: String

    var body: some View {
        if let google = URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=256") {
            AsyncImage(url: google) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    DuckDuckGoFaviconView(domain: domain, fallbackSystemName: fallbackSystemName)
                case .empty:
                    ProgressView()
                @unknown default:
                    Image(systemName: fallbackSystemName).resizable().scaledToFit()
                }
            }
        } else {
            Image(systemName: fallbackSystemName).resizable().scaledToFit()
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionTVView()
            .environmentObject(QuestionnaireViewModel())
    }
}

