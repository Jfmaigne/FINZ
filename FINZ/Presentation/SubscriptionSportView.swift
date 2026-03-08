import SwiftUI
import UIKit

struct SubscriptionSportView: View {
    var onCompleted: () -> Void = {}
    @EnvironmentObject private var vm: QuestionnaireViewModel

    private struct Option: Identifiable, Hashable {
        let id = UUID()
        let type: QuestionnaireViewModel.SubscriptionSportType
        let assetName: String
        let fallbackSystemName: String
        let remoteLogoURL: String?
        let title: String
    }

    private let options: [Option] = [
        Option(type: .BasicFit,    assetName: "logo_basicfit",    fallbackSystemName: "dumbbell.fill", remoteLogoURL: "https://logo.clearbit.com/basic-fit.com",     title: "Basic-Fit"),
        Option(type: .WeFit,       assetName: "logo_wefit",       fallbackSystemName: "figure.run",    remoteLogoURL: nil,                                          title: "WeFit"),
        Option(type: .KeepCool,    assetName: "logo_keepcool",    fallbackSystemName: "figure.walk",   remoteLogoURL: "https://logo.clearbit.com/keepcool.fr",      title: "KeepCool"),
        Option(type: .FitnessPark, assetName: "logo_fitnesspark", fallbackSystemName: "dumbbell",      remoteLogoURL: "https://logo.clearbit.com/fitnesspark.fr",   title: "Fitness Park"),
        Option(type: .ClubLocal,   assetName: "logo_club_local",  fallbackSystemName: "building.2",    remoteLogoURL: nil,                                          title: "Club local")
    ]

    private var canProceed: Bool { !vm.selectedSubscriptionsSport.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Salle de sport / Fitness")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(options) { option in
                        SubscriptionSportOptionCard(
                            assetName: option.assetName,
                            fallbackSystemName: option.fallbackSystemName,
                            remoteLogoURL: option.remoteLogoURL,
                            title: option.title,
                            selected: vm.selectedSubscriptionsSport.contains(option.type),
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
        .finzHeader(title: "Abonnements Sport")
        .stickyNextButton(enabled: canProceed, action: onNext)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ type: QuestionnaireViewModel.SubscriptionSportType) {
        let willSelect = !vm.selectedSubscriptionsSport.contains(type)
        let generator = UIImpactFeedbackGenerator(style: willSelect ? .medium : .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if vm.selectedSubscriptionsSport.contains(type) {
                vm.selectedSubscriptionsSport.remove(type)
            } else {
                vm.selectedSubscriptionsSport.insert(type)
            }
        }
    }

    private func onNext() {
        // Notify parent to push next step
        onCompleted()
    }
}

struct SubscriptionSportOptionCard: View {
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
        SubscriptionSportView()
            .environmentObject(QuestionnaireViewModel())
    }
}

