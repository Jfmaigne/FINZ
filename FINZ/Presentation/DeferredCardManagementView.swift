import SwiftUI
import SwiftData

struct DeferredCardManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DeferredCard.name) private var cards: [DeferredCard]
    
    @State private var showingAddCard = false
    @State private var cardToEdit: DeferredCard?
    
    var body: some View {
        List {
            if cards.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Aucune carte à débit différé")
                            .font(.headline)
                        Text("Ajoutez une carte pour gérer vos dépenses différées et définir une enveloppe mensuelle.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
                .listRowBackground(Color.clear)
            } else {
                Section(header: Text("Mes cartes")) {
                    ForEach(cards) { card in
                        CardRowView(card: card)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                cardToEdit = card
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteCard(card)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    cardToEdit = card
                                } label: {
                                    Label("Modifier", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                
                Section(header: Text("Informations")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Comment ça marche ?", systemImage: "info.circle")
                            .font(.headline)
                        Text("• L'enveloppe est utilisée dans le calcul du budget tant que le cycle n'est pas terminé")
                            .font(.caption)
                        Text("• Après la date de bascule, le montant réel des dépenses est pris en compte")
                            .font(.caption)
                        Text("• Le prélèvement effectif a lieu à la date définie")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Cartes différées")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddCard = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            AddEditDeferredCardView(card: nil) { newCard in
                modelContext.insert(newCard)
                try? modelContext.save()
            }
        }
        .sheet(item: $cardToEdit) { card in
            AddEditDeferredCardView(card: card) { updatedCard in
                // Update is automatic with SwiftData
                try? modelContext.save()
            }
        }
    }
    
    private func deleteCard(_ card: DeferredCard) {
        modelContext.delete(card)
        try? modelContext.save()
    }
}

// MARK: - Card Row View
private struct CardRowView: View {
    let card: DeferredCard
    
    var body: some View {
        HStack(spacing: 12) {
            // Card icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 28)
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(card.name)
                        .font(.headline)
                    if let digits = card.lastFourDigits, !digits.isEmpty {
                        Text("•••• \(digits)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 16) {
                    Label("Bascule: \(card.cutoffDay)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("Prélèvement: \(card.debitDay)", systemImage: "banknote")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(card.monthlyBudget))
                    .font(.headline)
                    .foregroundStyle(card.isActive ? .primary : .secondary)
                Text("/ mois")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(card.isActive ? 1.0 : 0.6)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value)) €"
    }
}

// MARK: - Add/Edit Deferred Card View
struct AddEditDeferredCardView: View {
    @Environment(\.dismiss) private var dismiss
    
    let card: DeferredCard?
    let onSave: (DeferredCard) -> Void
    
    @State private var name: String = ""
    @State private var lastFourDigits: String = ""
    @State private var cutoffDay: Int = 25
    @State private var debitDay: Int = 4
    @State private var monthlyBudgetText: String = ""
    @State private var isActive: Bool = true
    @State private var error: String?
    
    var isEditing: Bool { card != nil }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text(isEditing ? "Modifier la carte" : "Nouvelle carte")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                    
                    // Name card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nom de la carte").font(.headline)
                        TextField("Ex: Visa Gold, CB Principale...", text: $name)
                    }
                    .padding()
                    .background(cardBackground)
                    
                    // Last 4 digits card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("4 derniers chiffres (optionnel)").font(.headline)
                        TextField("1234", text: $lastFourDigits)
                            .keyboardType(.numberPad)
                            .onChange(of: lastFourDigits) { _, newValue in
                                if newValue.count > 4 {
                                    lastFourDigits = String(newValue.prefix(4))
                                }
                            }
                    }
                    .padding()
                    .background(cardBackground)
                    
                    // Monthly budget card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enveloppe mensuelle").font(.headline)
                        Text("Montant théorique utilisé dans le budget avant la bascule")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Spacer()
                            TextField("0", text: $monthlyBudgetText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.8)
                            Text("€")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(cardBackground)
                    
                    // Cutoff day card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Jour de bascule du différé").font(.headline)
                        Text("Date à laquelle les dépenses basculent vers le prélèvement")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DayGrid(selectedDay: $cutoffDay)
                    }
                    .padding()
                    .background(cardBackground)
                    
                    // Debit day card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Jour de prélèvement").font(.headline)
                        Text("Date du prélèvement effectif sur le compte")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DayGrid(selectedDay: $debitDay)
                    }
                    .padding()
                    .background(cardBackground)
                    
                    // Active toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $isActive) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Carte active").font(.headline)
                                Text("Inclure cette carte dans les calculs du budget")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(Color(red: 0.52, green: 0.21, blue: 0.93))
                    }
                    .padding()
                    .background(cardBackground)
                    
                    if let error {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
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
            .navigationTitle(isEditing ? "Modifier" : "Nouvelle carte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let card {
                    name = card.name
                    lastFourDigits = card.lastFourDigits ?? ""
                    cutoffDay = Int(card.cutoffDay)
                    debitDay = Int(card.debitDay)
                    monthlyBudgetText = card.monthlyBudget > 0 ? String(Int(card.monthlyBudget)) : ""
                    isActive = card.isActive
                }
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func save() {
        error = nil
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            error = "Veuillez saisir un nom pour la carte"
            return
        }
        
        let budget = Double(monthlyBudgetText.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        if let existingCard = card {
            // Update existing card
            existingCard.name = trimmedName
            existingCard.lastFourDigits = lastFourDigits.isEmpty ? nil : lastFourDigits
            existingCard.cutoffDay = Int16(cutoffDay)
            existingCard.debitDay = Int16(debitDay)
            existingCard.monthlyBudget = budget
            existingCard.isActive = isActive
            existingCard.updatedAt = Date()
            onSave(existingCard)
        } else {
            // Create new card
            let newCard = DeferredCard(
                name: trimmedName,
                lastFourDigits: lastFourDigits.isEmpty ? nil : lastFourDigits,
                cutoffDay: Int16(cutoffDay),
                debitDay: Int16(debitDay),
                monthlyBudget: budget,
                isActive: isActive
            )
            onSave(newCard)
        }
        dismiss()
    }
}

// MARK: - Day Grid (reused from other views)
private struct DayGrid: View {
    @Binding var selectedDay: Int
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(1...31, id: \.self) { d in
                let isSelected = selectedDay == d
                Button(action: { selectedDay = d }) {
                    Text("\(d)")
                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                        .frame(width: 36, height: 36)
                        .background(
                            isSelected
                            ? LinearGradient(
                                colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(isSelected ? .white : .primary)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        DeferredCardManagementView()
    }
    .modelContainer(for: [DeferredCard.self, DeferredCardExpense.self], inMemory: true)
}
