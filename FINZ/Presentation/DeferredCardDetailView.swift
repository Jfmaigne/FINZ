import SwiftUI
import SwiftData
import UIKit

struct DeferredCardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let card: DeferredCard
    let selectedMonthDate: Date
    let preloadedExpenses: [DeferredCardExpense]
    let cycleOffset: Int // 0 = cycle courant, -1 = cycle précédent (prélèvement)

    @State private var cycleExpenses: [DeferredCardExpense]
    @State private var editedExpense: DeferredCardExpense? = nil
    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var expenseToDelete: DeferredCardExpense? = nil

    init(card: DeferredCard, selectedMonthDate: Date, preloadedExpenses: [DeferredCardExpense], cycleOffset: Int = 0) {
        self.card = card
        self.selectedMonthDate = selectedMonthDate
        self.preloadedExpenses = preloadedExpenses
        self.cycleOffset = cycleOffset
        
        // Calculer la date de référence selon le cycle demandé
        let referenceDate: Date
        if cycleOffset < 0 {
            referenceDate = DeferredCardService.previousCycleReferenceDate(for: card, referenceDate: selectedMonthDate)
        } else {
            referenceDate = selectedMonthDate
        }
        
        // Filtrer les dépenses du cycle IMMÉDIATEMENT dans le init
        let cycle = DeferredCardService.getCurrentCycle(for: card, referenceDate: referenceDate)
        let cardID = card.id
        
        let filtered = preloadedExpenses
            .filter {
                $0.cardID == cardID &&
                $0.expenseDate >= cycle.start &&
                $0.expenseDate <= cycle.cutoff
            }
            .sorted { $0.expenseDate < $1.expenseDate }
        
        _cycleExpenses = State(initialValue: filtered)
    }

    // MARK: - Computed Properties

    private var effectiveReferenceDate: Date {
        if cycleOffset < 0 {
            return DeferredCardService.previousCycleReferenceDate(for: card, referenceDate: selectedMonthDate)
        }
        return selectedMonthDate
    }

    private var cycle: (start: Date, cutoff: Date, debit: Date) {
        DeferredCardService.getCurrentCycle(for: card, referenceDate: effectiveReferenceDate)
    }

    private var isBeforeCutoff: Bool {
        Date() <= cycle.cutoff
    }
    
    private var cycleStatusText: String {
        if cycleOffset < 0 {
            // Cycle précédent : vérifier si le prélèvement est passé
            if Date() >= cycle.debit {
                return "Cycle clôturé - Prélevé"
            } else {
                return "Cycle clôturé - Prélèvement à venir"
            }
        }
        return isBeforeCutoff ? "Cycle en cours - Bascule le \(Int(card.cutoffDay))" : "Cycle clôturé"
    }
    
    private var cycleStatusIcon: String {
        if cycleOffset < 0 {
            return Date() >= cycle.debit ? "checkmark.seal.fill" : "hourglass"
        }
        return isBeforeCutoff ? "clock.fill" : "checkmark.circle.fill"
    }
    
    private var cycleStatusColor: Color {
        if cycleOffset < 0 {
            return Date() >= cycle.debit ? .green : .blue
        }
        return isBeforeCutoff ? .orange : .green
    }

    private var totalExpenses: Double {
        cycleExpenses.reduce(0) { $0 + $1.amount }
    }

    private var usagePercent: Double {
        guard card.monthlyBudget > 0 else { return 0 }
        return min(totalExpenses / card.monthlyBudget, 1.0)
    }

    private var usageColor: Color {
        usagePercent > 0.9 ? .red : (usagePercent > 0.7 ? .orange : .green)
    }

    // MARK: - Data Loading

    private func filterExpenses(from source: [DeferredCardExpense]) -> [DeferredCardExpense] {
        let cardID = card.id
        let c = DeferredCardService.getCurrentCycle(for: card, referenceDate: effectiveReferenceDate)
        return source.filter {
            $0.cardID == cardID &&
            $0.expenseDate >= c.start &&
            $0.expenseDate <= c.cutoff
        }.sorted { $0.expenseDate < $1.expenseDate }
    }

    private func loadExpenses() {
        do {
            let descriptor = FetchDescriptor<DeferredCardExpense>(
                sortBy: [SortDescriptor(\.expenseDate, order: .forward)]
            )
            let all = try modelContext.fetch(descriptor)
            let filtered = filterExpenses(from: all)
            if !filtered.isEmpty || preloadedExpenses.isEmpty {
                cycleExpenses = filtered
                return
            }
        } catch { }
        cycleExpenses = filterExpenses(from: preloadedExpenses)
    }

    // MARK: - Formatters

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "dd MMM"
        return f.string(from: date)
    }

    private func formatAmount(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "\(value) €"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.04), Color.purple.opacity(0.04), Color.pink.opacity(0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // Header carte
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(
                                        colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 56, height: 36)
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                            }

                            VStack(spacing: 4) {
                                Text(card.name).font(.title3.bold())
                                if let digits = card.lastFourDigits, !digits.isEmpty {
                                    Text("•••• \(digits)").font(.subheadline).foregroundStyle(.secondary)
                                }
                                Text("Cycle : \(formatDate(cycle.start)) → \(formatDate(cycle.cutoff))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: cycleStatusIcon)
                                    .font(.caption)
                                Text(cycleStatusText)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(cycleStatusColor)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(cycleStatusColor.opacity(0.1)))
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4))

                        // Résumé financier
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Dépenses réelles").font(.caption).foregroundStyle(.secondary)
                                Text(formatAmount(totalExpenses)).font(.headline.bold())
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
                                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enveloppe").font(.caption).foregroundStyle(.secondary)
                                Text(formatAmount(card.monthlyBudget)).font(.headline.bold()).foregroundStyle(usageColor)
                                Text("\(Int(usagePercent * 100))% utilisé").font(.caption2).foregroundStyle(usageColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
                                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3))
                        }

                        // Barre de progression
                        if card.monthlyBudget > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Utilisation de l'enveloppe").font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(formatAmount(totalExpenses)) / \(formatAmount(card.monthlyBudget))")
                                        .font(.caption.weight(.semibold)).foregroundStyle(usageColor)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)).frame(height: 8)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(LinearGradient(
                                                colors: usagePercent > 0.9
                                                    ? [.red, Color.red.opacity(0.7)]
                                                    : [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
                                                startPoint: .leading, endPoint: .trailing
                                            ))
                                            .frame(width: geo.size.width * CGFloat(usagePercent), height: 8)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
                                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3))
                        }

                        // Liste des dépenses
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Dépenses du cycle").font(.headline)
                                Spacer()
                                Text("\(cycleExpenses.count) opération\(cycleExpenses.count > 1 ? "s" : "")")
                                    .font(.caption).foregroundStyle(.secondary)
                            }

                            if cycleExpenses.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "creditcard").font(.system(size: 32)).foregroundStyle(.secondary.opacity(0.5))
                                    Text("Aucune dépense sur ce cycle").font(.subheadline).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 24)
                            } else {
                                List {
                                    ForEach(cycleExpenses) { expense in
                                        DeferredExpenseDetailRow(expense: expense)
                                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                                Button {
                                                    editedExpense = expense
                                                    showEditSheet = true
                                                } label: { Label("Modifier", systemImage: "pencil") }
                                                .tint(.blue)
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    expenseToDelete = expense
                                                    showDeleteConfirm = true
                                                } label: { Label("Supprimer", systemImage: "trash") }
                                            }
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                    }
                                }
                                .listStyle(.plain)
                                .scrollDisabled(true)
                                .frame(height: CGFloat(cycleExpenses.count) * 64)
                            }

                            if !cycleExpenses.isEmpty {
                                Divider()
                                HStack {
                                    Text("Total").font(.headline)
                                    Spacer()
                                    Text(formatAmount(totalExpenses)).font(.headline.bold()).foregroundStyle(.red)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4))

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal).padding(.top, 16)
                }
            }
            .navigationTitle(card.name)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadExpenses()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                        .foregroundStyle(Color(red: 0.52, green: 0.21, blue: 0.93))
                }
            }
            .sheet(isPresented: $showEditSheet, onDismiss: { loadExpenses() }) {
                if let expense = editedExpense {
                    EditDeferredExpenseDetailSheet(expense: expense)
                }
            }
            .alert("Supprimer cette dépense ?", isPresented: $showDeleteConfirm) {
                Button("Supprimer", role: .destructive) {
                    if let expense = expenseToDelete {
                        modelContext.delete(expense)
                        try? modelContext.save()
                        loadExpenses()
                    }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action est irréversible.")
            }
        }
    }
}

// MARK: - Deferred Expense Detail Row
private struct DeferredExpenseDetailRow: View {
    let expense: DeferredCardExpense

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }

    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) €"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Date
            Text(formatDate(expense.expenseDate))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.expenseDescription ?? "Dépense carte")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if expense.isSettled {
                    Text("Prélevé")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            // Montant
            Text("-\(formatAmount(expense.amount))")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.red)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Edit Deferred Expense Detail Sheet
struct EditDeferredExpenseDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var expense: DeferredCardExpense

    @State private var amountText: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.04), Color.purple.opacity(0.04), Color.pink.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // Montant
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Montant")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            HStack {
                                TextField("0", text: $amountText)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .focused($amountFocused)
                                    .multilineTextAlignment(.center)
                                Text("€")
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                            )
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            TextField("Description...", text: $description)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                                )
                        }

                        // Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                                )
                        }

                        Spacer(minLength: 24)
                    }
                    .padding()
                }
                .onTapGesture {
                    amountFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .navigationTitle("Modifier la dépense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") { save() }
                        .foregroundStyle(Color(red: 0.52, green: 0.21, blue: 0.93))
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                amountText = String(format: "%.2f", expense.amount).replacingOccurrences(of: ".", with: ",")
                description = expense.expenseDescription ?? ""
                date = expense.expenseDate
            }
        }
    }

    private func save() {
        let cleanText = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleanText), amount > 0 else { return }

        expense.amount = amount
        expense.expenseDescription = description.isEmpty ? nil : description
        expense.expenseDate = date

        try? modelContext.save()
        dismiss()
    }
}
