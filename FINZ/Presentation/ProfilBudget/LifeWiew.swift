//
//  LifeView.swift
//  Auth
//
//  Created by MAIGNE JEAN-FRANCOIS on 01/02/2026.
//


import SwiftUI
import UIKit

struct LifeView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @State private var goToHousingStatus = false
    @State private var goToTransportMode = false
    @State private var goToSubscriptions = false

    private struct Option: Identifiable, Hashable {
        let id = UUID()
        let mode: QuestionnaireViewModel.LivingSituation
        let icon: String
        let title: String
    }

    private var options: [Option] {
        [
            Option(mode: .alone,                icon: "person.fill",          title: "Seul"),
            Option(mode: .couple,               icon: "person.line.dotted.person.fill",          title: "En couple"),
            Option(mode: .colocation,           icon: "person.3.fill",           title: "En colocation"),
            Option(mode: .withParents,          icon: "figure.2.and.child.holdinghands", title: "Chez tes parents")
        ]
    }
    
    
    private var canProceed: Bool { !vm.selectedLifeModes.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Comment vis-tu ?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(options) { option in
                        LivingOptionCard(
                            icon: option.icon,
                            title: option.title,
                            selected: vm.selectedLifeModes.contains(option.mode),
                            action: { toggle(option.mode) }
                        )
                    }
                }

                Text("Sélectionne une seule option.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                
                if !canProceed {
                    Text("Sélectionne un mode pour continuer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 16)
                }
            }
            .safeAreaPadding(.bottom, 200)
            .padding(.horizontal)
            .padding(.top, 4)
            
            NavigationLink(destination: HousingStatusView().environmentObject(vm), isActive: $goToHousingStatus) { EmptyView() }
            NavigationLink(destination: TransportModeView(onCompleted: { goToSubscriptions = true }).environmentObject(vm), isActive: $goToTransportMode) { EmptyView() }
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
        .finzHeader(title: "Mode de vie")
        .stickyNextButton(enabled: canProceed, action: onNext)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ mode: QuestionnaireViewModel.LivingSituation) {
        let willSelect = !vm.selectedLifeModes.contains(mode)
        let generator = UIImpactFeedbackGenerator(style: willSelect ? .medium : .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            // For single selection, clear previous selection and set only the tapped mode
            vm.selectedLifeModes.removeAll()
            vm.selectedLifeModes.insert(mode)
        }
        // Persist the selected mode for downstream logic
        vm.LifeModeVar = mode
    }

    private func onNext() {
        // Store selected life mode in LifeModeVar (single selection enforced)
        vm.LifeModeVar = vm.selectedLifeModes.first
        // Navigate to next screen depending on selection
        if let mode = vm.LifeModeVar {
            switch mode {
            case .alone, .couple:
                goToHousingStatus = true
            case .colocation, .withParents:
                goToTransportMode = true
            }
        }
    }
}

struct LivingOptionCard: View {
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
            .frame(maxWidth: .infinity, minHeight: 120)
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
        LifeView()
            .environmentObject(QuestionnaireViewModel())
    }
}

