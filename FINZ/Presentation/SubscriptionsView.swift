import SwiftUI
import UIKit

struct SubscriptionsView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel

    private enum Step {
        case sport, music, telecom, tv, personalSituation
    }

    @State private var isFlowActive = false
    @State private var currentStep: Step? = nil

    private struct Option: Identifiable, Hashable {
        let id = UUID()
        let type: QuestionnaireViewModel.SubscriptionType
        let icon: String
        let title: String
    }

    private let options: [Option] = [
        Option(type: .sport,   icon: "dumbbell.fill",                              title: "Sports"),
        Option(type: .music,   icon: "music.note.list",                            title: "Musique"),
        Option(type: .telecom, icon: "antenna.radiowaves.left.and.right",         title: "Télécom"),
        Option(type: .tv,      icon: "tv.fill",                                    title: "TV")
    ]

    private var canProceed: Bool { !vm.selectedSubscriptions.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Abonnements")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(options) { option in
                        SubscriptionOptionCard(
                            icon: option.icon,
                            title: option.title,
                            selected: vm.selectedSubscriptions.contains(option.type),
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
                
                Spacer(minLength: 0)
            }
            .safeAreaPadding(.bottom, 200)
            .padding(.horizontal)
            .padding(.top, 4)

            // Hidden link that drives the multi-step flow
            NavigationLink(destination: stepDestination(for: currentStep), isActive: $isFlowActive) { EmptyView() }
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
        .finzHeader(title: "Abonnements")
        .stickyNextButton(enabled: canProceed, action: startFlow)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ type: QuestionnaireViewModel.SubscriptionType) {
        let willSelect = !vm.selectedSubscriptions.contains(type)
        let generator = UIImpactFeedbackGenerator(style: willSelect ? .medium : .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if vm.selectedSubscriptions.contains(type) {
                vm.selectedSubscriptions.remove(type)
            } else {
                vm.selectedSubscriptions.insert(type)
            }
        }
    }

    private func startFlow() {
        guard canProceed else { return }
        vm.prepareSubscriptionFlow()
        goNext()
    }

    private func goNext() {
        if let next = vm.dequeueNextSubscriptionType() {
            switch next {
            case .sport:
                currentStep = .sport
            case .music:
                currentStep = .music
            case .telecom:
                currentStep = .telecom
            case .tv:
                currentStep = .tv
            }
            isFlowActive = true
        } else {
            currentStep = .personalSituation
            isFlowActive = true
        }
    }
    
    @ViewBuilder
    private func stepDestination(for step: Step?) -> some View {
        switch step {
        case .some(.sport):
            SubscriptionSportView(onCompleted: { goNext() })
                .environmentObject(vm)
        case .some(.music):
            SubscriptionsMusicView(onCompleted: { goNext() })
                .environmentObject(vm)
        case .some(.telecom):
            SubscriptionTelecomView(onCompleted: { goNext() })
                .environmentObject(vm)
        case .some(.tv):
            SubscriptionTVView(onCompleted: { goNext() })
                .environmentObject(vm)
        case .some(.personalSituation):
            PersonnalSituationView()
                .environmentObject(vm)
        case .none:
            EmptyView()
        }
    }
}

struct SubscriptionOptionCard: View {
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
        SubscriptionsView()
            .environmentObject(QuestionnaireViewModel())
    }
}

