import SwiftUI
import UIKit

struct HousingStatusView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @State private var selectedStatus: QuestionnaireViewModel.HousingStatus? = nil
    @State private var goToTransport = false
    @State private var goToSubscriptions = false

    private struct Option: Identifiable, Hashable {
        let id = UUID()
        let status: QuestionnaireViewModel.HousingStatus
        let icon: String
        let title: String
    }

    private var options: [Option] {
        [
            Option(status: .owner,  icon: "house.fill", title: "Propriétaire"),
            Option(status: .renter, icon: "key.fill",   title: "Locataire")
        ]
    }

    private var canProceed: Bool { selectedStatus != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Statut du logement")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(options) { option in
                        HousingOptionCard(
                            icon: option.icon,
                            title: option.title,
                            selected: selectedStatus == option.status,
                            action: { select(option.status) }
                        )
                    }
                }

                Text("Sélectionne une seule option.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                if !canProceed {
                    Text("Sélectionne une option pour continuer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            NavigationLink(destination: TransportModeView(onCompleted: { goToSubscriptions = true }).environmentObject(vm), isActive: $goToTransport) { EmptyView() }
            NavigationLink(destination: SubscriptionsView().environmentObject(vm), isActive: $goToSubscriptions) { EmptyView() }
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
        .finzHeader(title: "Habitation")
        .stickyNextButton(enabled: canProceed, action: onNext)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedStatus = vm.housingStatus
        }
    }

    private func select(_ status: QuestionnaireViewModel.HousingStatus) {
        let willSelect = selectedStatus != status
        let generator = UIImpactFeedbackGenerator(style: willSelect ? .medium : .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedStatus = status
            vm.housingStatus = status
        }
    }

    private func onNext() {
        if canProceed {
            goToTransport = true
        }
    }
}

struct HousingOptionCard: View {
    let icon: String
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
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .semibold))
                    .frame(width: 64, height: 64)
                    .background(
                        Circle().fill(selected ? Color.white.opacity(0.2) : Color(.systemBackground))
                    )
                    .scaleEffect(pulsing ? 1.08 : 1.0)
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .foregroundStyle(selected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 140)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .shadow(color: selected ? Color.pink.opacity(0.25) : Color.black.opacity(0.05), radius: selected ? 12 : 4, x: 0, y: selected ? 8 : 2)
            .animation(.easeInOut(duration: 0.2), value: selected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HousingStatusView()
            .environmentObject(QuestionnaireViewModel())
    }
}
