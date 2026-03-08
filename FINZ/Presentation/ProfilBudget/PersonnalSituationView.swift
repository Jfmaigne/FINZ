//
//  PersonnalSituation.swift
//  Auth
//
//  Created by MAIGNE JEAN-FRANCOIS on 01/02/2026.
//

import SwiftUI
import UIKit

struct PersonnalSituationView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @State private var goToRecettes = false

    private struct Option: Identifiable, Hashable {
        let id = UUID()
        let mode: QuestionnaireViewModel.PersonnalSituation
        let icon: String
        let title: String
    }

    private var options: [Option] {
        [
            Option(mode: .Etudiant,              icon: "graduationcap.fill",          title: "Etudiant"),
            Option(mode: .Salarié,              icon: "eurosign.bank.building",          title: "Salarié"),
            Option(mode: .SansEmploi,             icon: "magnifyingglass",           title: "Sans Emploi"),
            Option(mode: .Handicap,             icon: "figure.roll",       title: "En situation de Handicap"),
            Option(mode: .Entrepreneur,          icon: "lightbulb.max",          title: "Entrepreneur")
        ]
    }
    
    private var canProceed: Bool { !vm.selectedPersonnalSituation.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Situation Personnelle")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(options) { option in
                        PersonnalSituationOptionCard(
                            icon: option.icon,
                            title: option.title,
                            selected: vm.selectedPersonnalSituation.contains(option.mode),
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
            .padding(.horizontal)
            .padding(.top, 4)
            
            NavigationLink(destination: RecettesView().environmentObject(vm), isActive: $goToRecettes) { EmptyView() }
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
        .finzHeader(title: "Situation Personnelle")
        .stickyNextButton(enabled: canProceed, action: onNext)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ mode: QuestionnaireViewModel.PersonnalSituation) {
        let willSelect = !vm.selectedPersonnalSituation.contains(mode)
        let generator = UIImpactFeedbackGenerator(style: willSelect ? .medium : .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if vm.selectedPersonnalSituation.contains(mode) {
                vm.selectedPersonnalSituation.remove(mode)
            } else {
                vm.selectedPersonnalSituation.insert(mode)
            }
        }
    }

    private func onNext() {
        // Après la situation personnelle, on passe à la saisie des recettes
        goToRecettes = true
    }
}

struct PersonnalSituationOptionCard: View {
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
        PersonnalSituationView()
            .environmentObject(QuestionnaireViewModel())
    }
}

