import SwiftUI
import UIKit

struct TransportModeView: View {
    var onCompleted: () -> Void = {}
    @EnvironmentObject private var vm: QuestionnaireViewModel

    private struct Option: Identifiable, Hashable {
        let id = UUID()
        let mode: QuestionnaireViewModel.TransportMode
        let icon: String
        let title: String
    }

    private var options: [Option] {
        [
            Option(mode: .car,              icon: "car.fill",          title: "Véhicule"),
            Option(mode: .publicTransport,  icon: "bus.fill",          title: "Transports"),
            Option(mode: .bike,             icon: "bicycle",           title: "Vélo / Trottinette"),
            Option(mode: .walk,             icon: "figure.walk",       title: "À pied")
        ]
    }
    
    private var canProceed: Bool { !vm.selectedTransportModes.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Mode(s) de transport")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(options) { option in
                        TransportOptionCard(
                            icon: option.icon,
                            title: option.title,
                            selected: vm.selectedTransportModes.contains(option.mode),
                            action: { toggle(option.mode) }
                        )
                    }
                }

                Text("Tu peux sélectionner plusieurs options.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                
                if !canProceed {
                    Text("Sélectionne au moins un mode pour continuer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 16)
                }
            }
            .safeAreaPadding(.bottom, 200)
            .padding([.top, .horizontal])
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
        .finzHeader(title: "Transports")
        .stickyNextButton(enabled: canProceed, action: onNext)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ mode: QuestionnaireViewModel.TransportMode) {
        let willSelect = !vm.selectedTransportModes.contains(mode)
        let generator = UIImpactFeedbackGenerator(style: willSelect ? .medium : .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if vm.selectedTransportModes.contains(mode) {
                vm.selectedTransportModes.remove(mode)
            } else {
                vm.selectedTransportModes.insert(mode)
            }
        }
    }

    private func onNext() {
        guard canProceed else { return }
        onCompleted()
    }
}

struct TransportOptionCard: View {
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
        TransportModeView()
            .environmentObject(QuestionnaireViewModel())
    }
}

