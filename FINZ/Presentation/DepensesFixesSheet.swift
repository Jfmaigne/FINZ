import SwiftUI
import SwiftData
import UIKit

struct DepensesFixesSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allOccurrences: [BudgetEntryOccurrence]
    @State private var editedOccurrence: BudgetEntryOccurrence?
    @State private var showEditSheet: Bool = false

    private let monthKey: String

    init(monthKey: String) {
        self.monthKey = monthKey

        let predicate = #Predicate<BudgetEntryOccurrence> { occurrence in
            occurrence.monthKey == monthKey && occurrence.kind == "expense"
        }

        _allOccurrences = Query(
            filter: predicate,
            sort: [SortDescriptor(\.date, order: .forward)]
        )
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
    @State private var amount: Double = 0
    @State private var date: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Informations") {
                    TextField("Titre", text: $title)
                    TextField("Montant", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
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
                amount = abs(occurrence.amount)
                date = occurrence.date
            }
        }
    }

    private func saveChanges() {
        occurrence.title = title
        occurrence.amount = -abs(amount)
        occurrence.date = date
        occurrence.isManual = true
        onSave(occurrence)
        dismiss()
    }
}
