import SwiftUI
import SwiftData
import UIKit

struct DepensesFixesSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allOccurrences: [BudgetEntryOccurrence]
    @Query(filter: #Predicate<DeferredCard> { $0.isActive == true }, sort: \DeferredCard.name) private var deferredCards: [DeferredCard]
    @Query private var deferredCardExpenses: [DeferredCardExpense]
    
    @State private var editedOccurrence: BudgetEntryOccurrence?
    @State private var showEditSheet: Bool = false
    
    // State for editing deferred card expenses
    @State private var editedDeferredExpense: DeferredCardExpense?
    @State private var showEditDeferredExpenseSheet: Bool = false

    private let monthKey: String
    private let monthDate: Date

    init(monthKey: String) {
        self.monthKey = monthKey
        
        // Parse monthDate from monthKey (format: "yyyy-MM")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        self.monthDate = formatter.date(from: monthKey) ?? Date()

        let predicate = #Predicate<BudgetEntryOccurrence> { occurrence in
            occurrence.monthKey == monthKey && occurrence.kind == "expense"
        }

        _allOccurrences = Query(
            filter: predicate,
            sort: [SortDescriptor(\.date, order: .forward)]
        )
    }
    
    /// Dépenses différées pour le cycle de la carte correspondant au mois sélectionné
    /// Utilise le cycle de la carte (basé sur cutoffDay) et non le mois calendaire
    private func deferredExpensesForCycle(card: DeferredCard) -> [DeferredCardExpense] {
        let cycle = DeferredCardService.getCurrentCycle(for: card, referenceDate: monthDate)
        
        return deferredCardExpenses
            .filter { $0.cardID == card.id && $0.expenseDate >= cycle.start && $0.expenseDate <= cycle.cutoff && !$0.isSettled }
            .sorted { $0.expenseDate < $1.expenseDate }
    }
    
    private func deleteDeferredExpense(_ expense: DeferredCardExpense) {
        modelContext.delete(expense)
        do {
            try modelContext.save()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Failed to delete deferred expense: \(error.localizedDescription)")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private var occurrences: [BudgetEntryOccurrence] {
        allOccurrences.filter { $0.monthKey == monthKey && $0.kind == "expense" }
    }

    private var fixedExpenses: [BudgetEntryOccurrence] {
        occurrences.filter { $0.isManual == false }
    }

    private var complementaryExpenses: [BudgetEntryOccurrence] {
        occurrences.filter { $0.isManual == true }
    }

    private func todayInsertionIndex(in items: [BudgetEntryOccurrence]) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for (idx, item) in items.enumerated() {
            let day = cal.startOfDay(for: item.date)
            if day >= today { return idx }
        }
        return items.count
    }

    private func startEditing(_ occurrence: BudgetEntryOccurrence) {
        editedOccurrence = occurrence
        showEditSheet = true
    }

    private func deleteOccurrence(_ occurrence: BudgetEntryOccurrence) {
        modelContext.delete(occurrence)
        do {
            try modelContext.save()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Failed to delete occurrence: \(error.localizedDescription)")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private struct TodaySeparatorView: View {
        var body: some View {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 1)
                Text("Aujourd’hui")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.52, green: 0.21, blue: 0.93).opacity(0.12),
                                        Color(red: 1.00, green: 0.29, blue: 0.63).opacity(0.12)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .foregroundColor(Color.secondary)
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 1)
            }
            .padding(.vertical, 4)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Cartes à débit différé - affichage avec enveloppe ou montant réel selon la bascule
                ForEach(deferredCards) { card in
                    let cardExpenses = deferredExpensesForCycle(card: card)
                    let cycleSummary = DeferredCardService.getCycleSummary(for: card, expenses: Array(deferredCardExpenses), referenceDate: monthDate)
                    
                    // Afficher seulement si il y a une enveloppe configurée ou des dépenses
                    if card.monthlyBudget > 0 || !cardExpenses.isEmpty {
                        Section(header: DeferredCardSectionHeader(
                            card: card,
                            cycleSummary: cycleSummary
                        )) {
                            // Afficher les dépenses individuelles pour permettre l'édition/suppression
                            ForEach(cardExpenses) { expense in
                                DeferredExpenseRow(
                                    expense: expense,
                                    card: card,
                                    onEdit: {
                                        editedDeferredExpense = expense
                                        showEditDeferredExpenseSheet = true
                                    },
                                    onDelete: {
                                        deleteDeferredExpense(expense)
                                    }
                                )
                            }
                            
                            // Si avant la bascule et pas de dépenses, afficher un message
                            if cardExpenses.isEmpty && cycleSummary.isBeforeCutoff {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundStyle(.secondary)
                                    Text("Aucune dépense enregistrée pour ce cycle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
                
                // Dépenses fixes
                if !fixedExpenses.isEmpty {
                    Section(header: Text("Dépenses fixes").font(.headline)) {
                        let fixedIdx = todayInsertionIndex(in: fixedExpenses)
                        ForEach(Array(fixedExpenses.enumerated()), id: \.element.id) { offset, occurrence in
                            if offset == fixedIdx {
                                TodaySeparatorView()
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowSeparator(.hidden)
                            }
                            ExpenseRow(occurrence: occurrence, onEdit: { startEditing(occurrence) }, onDelete: { deleteOccurrence(occurrence) })
                        }
                        if fixedIdx == fixedExpenses.count {
                            TodaySeparatorView()
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                        }
                    }
                }

                // Dépenses complémentaires
                if !complementaryExpenses.isEmpty {
                    Section(header: Text("Dépenses complémentaires").font(.headline)) {
                        let compIdx = todayInsertionIndex(in: complementaryExpenses)
                        ForEach(Array(complementaryExpenses.enumerated()), id: \.element.id) { offset, occurrence in
                            if offset == compIdx {
                                TodaySeparatorView()
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowSeparator(.hidden)
                            }
                            ExpenseRow(occurrence: occurrence, onEdit: { startEditing(occurrence) }, onDelete: { deleteOccurrence(occurrence) })
                        }
                        if compIdx == complementaryExpenses.count {
                            TodaySeparatorView()
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .listSectionSpacing(.compact)
            .navigationTitle("Dépenses du mois")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let occurrence = editedOccurrence {
                    EditExpenseOccurrenceSheet(occurrence: occurrence) { _ in
                        do {
                            try modelContext.save()
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        } catch {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                            print("Failed to save expense occurrence: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditDeferredExpenseSheet) {
                if let expense = editedDeferredExpense {
                    EditDeferredExpenseSheet(expense: expense) {
                        do {
                            try modelContext.save()
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        } catch {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                            print("Failed to save deferred expense: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}

private struct ExpenseRow: View {
    let occurrence: BudgetEntryOccurrence
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: occurrence.date)
    }

    private var amountFormatted: String {
        let val = Int(abs(occurrence.amount))
        return "-\(val) €"
    }

    var body: some View {
        HStack {
            Text(dateFormatted)
                .font(.callout)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(occurrence.title ?? "")
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(amountFormatted)
                .foregroundColor(.red)
                .font(.body.monospacedDigit())
                .frame(alignment: .trailing)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
        )
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button { onEdit() } label: {
                Label("Modifier", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { onDelete() } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}

private struct EditExpenseOccurrenceSheet: View {
    @Bindable var occurrence: BudgetEntryOccurrence
    var onSave: (BudgetEntryOccurrence) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Title field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Titre").font(.headline)
                        TextField("Titre", text: $title)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                    // Amount field (styled like AddExpenseQuickSheet)
                    VStack(alignment: .center, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Spacer()
                            TextField("0", text: $amountText)
                                .keyboardType(.decimalPad)
                                .focused($amountFocused)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(white: 0.1))
                                .minimumScaleFactor(0.8)
                            Text("€")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                    // Date field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date").font(.headline)
                        HStack { Spacer()
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            Spacer() }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                    Spacer()
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.04),
                        Color.purple.opacity(0.04),
                        Color.pink.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .onTapGesture {
                amountFocused = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle("Modifier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                title = occurrence.title ?? ""
                amountText = String(Int(abs(occurrence.amount)))
                date = occurrence.date
            }
        }
    }

    private func saveChanges() {
        occurrence.title = title
        let cleanAmount = amountText.replacingOccurrences(of: ",", with: ".")
        if let amount = Double(cleanAmount) {
            occurrence.amount = -abs(amount)
        }
        occurrence.date = date
        occurrence.isManual = true
        onSave(occurrence)
        dismiss()
    }
}

// MARK: - Deferred Card Section Header
private struct DeferredCardSectionHeader: View {
    let card: DeferredCard
    let cycleSummary: DeferredCardService.CycleSummary
    
    /// Montant à afficher : enveloppe avant bascule, réel après
    private var displayAmount: Double {
        if cycleSummary.isBeforeCutoff {
            // Avant la bascule : afficher l'enveloppe (ou le réel si supérieur)
            return max(card.monthlyBudget, cycleSummary.totalExpenses)
        } else {
            // Après la bascule : afficher le montant réel
            return cycleSummary.totalExpenses
        }
    }
    
    /// Indique si on affiche une estimation
    private var isEstimate: Bool {
        cycleSummary.isBeforeCutoff && cycleSummary.totalExpenses < card.monthlyBudget
    }
    
    /// Jour de bascule formaté
    private var cutoffInfo: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: cycleSummary.cycleCutoff)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                // Card icon
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 20, height: 12)
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(.white)
                }
                
                Text(card.name)
                    .font(.headline)
                
                if let digits = card.lastFourDigits, !digits.isEmpty {
                    Text("•••• \(digits)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("-\(Int(displayAmount)) €")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                    
                    if isEstimate {
                        Text("(enveloppe)")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            // Info sur le cycle
            HStack(spacing: 4) {
                if cycleSummary.isBeforeCutoff {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Bascule le \(cutoffInfo)")
                        .font(.caption2)
                    if cycleSummary.totalExpenses > 0 {
                        Text("• Dépenses: \(Int(cycleSummary.totalExpenses)) €")
                            .font(.caption2)
                    }
                } else {
                    Image(systemName: "checkmark.circle")
                        .font(.caption2)
                    Text("Cycle clôturé")
                        .font(.caption2)
                }
            }
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Deferred Expense Row
private struct DeferredExpenseRow: View {
    let expense: DeferredCardExpense
    let card: DeferredCard
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: expense.expenseDate)
    }
    
    private var amountFormatted: String {
        let val = Int(expense.amount)
        return "-\(val) €"
    }
    
    var body: some View {
        HStack {
            Text(dateFormatted)
                .font(.callout)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            
            Text(expense.expenseDescription ?? "Dépense carte")
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(amountFormatted)
                .foregroundColor(.red)
                .font(.body.monospacedDigit())
                .frame(alignment: .trailing)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
        )
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button { onEdit() } label: {
                Label("Modifier", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { onDelete() } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}

// MARK: - Edit Deferred Expense Sheet
private struct EditDeferredExpenseSheet: View {
    @Bindable var expense: DeferredCardExpense
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var description: String = ""
    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @FocusState private var amountFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Description field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description").font(.headline)
                        TextField("Description", text: $description)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    
                    // Amount field
                    VStack(alignment: .center, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Spacer()
                            TextField("0", text: $amountText)
                                .keyboardType(.decimalPad)
                                .focused($amountFocused)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(white: 0.1))
                                .minimumScaleFactor(0.8)
                            Text("€")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    
                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date").font(.headline)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
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
            .onTapGesture {
                amountFocused = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle("Modifier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                description = expense.expenseDescription ?? ""
                amountText = String(Int(expense.amount))
                date = expense.expenseDate
            }
        }
    }
    
    private func saveChanges() {
        expense.expenseDescription = description.isEmpty ? nil : description
        let cleanAmount = amountText.replacingOccurrences(of: ",", with: ".")
        if let amount = Double(cleanAmount) {
            expense.amount = abs(amount)
        }
        expense.expenseDate = date
        onSave()
        dismiss()
    }
}
