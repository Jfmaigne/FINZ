import SwiftUI
import SwiftData

struct RecettesFixesSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allOccurrences: [BudgetEntryOccurrence]
    @State private var editedOccurrence: BudgetEntryOccurrence?
    @State private var showEditSheet: Bool = false

    private let monthKey: String

    init(monthDate: Date = Date()) {
        self.monthKey = BudgetProjectionManager.monthKey(for: monthDate)
        let predicate = #Predicate<BudgetEntryOccurrence> { occurrence in
            occurrence.monthKey == monthKey && occurrence.kind == "income"
        }
        _allOccurrences = Query(filter: predicate, sort: [SortDescriptor(\.date, order: .forward)])
    }

    private var occurrences: [BudgetEntryOccurrence] {
        allOccurrences.filter { $0.monthKey == monthKey && $0.kind == "income" }
    }

    private func todayInsertionIndex(in items: [BudgetEntryOccurrence]) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for (idx, item) in items.enumerated() {
            let day = cal.startOfDay(for: item.date)
            if day >= today {
                return idx
            }
        }
        return items.count
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
                // Recettes fixes
                if !fixedIncomes.isEmpty {
                    Section(header: Text("Recettes fixes").font(.headline)) {
                        let fixedIdx = todayInsertionIndex(in: fixedIncomes)
                        ForEach(Array(fixedIncomes.enumerated()), id: \.element.id) { offset, occurrence in
                            if offset == fixedIdx {
                                TodaySeparatorView()
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowSeparator(.hidden)
                            }
                            RowView(occurrence: occurrence, onEdit: { startEditing(occurrence) }) {
                                deleteOccurrence(occurrence)
                            }
                        }
                        if fixedIdx == fixedIncomes.count {
                            TodaySeparatorView()
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                        }
                    }
                }

                // Recettes complémentaires
                if !complementaryIncomes.isEmpty {
                    Section(header: Text("Recettes complémentaires").font(.headline)) {
                        let compIdx = todayInsertionIndex(in: complementaryIncomes)
                        ForEach(Array(complementaryIncomes.enumerated()), id: \.element.id) { offset, occurrence in
                            if offset == compIdx {
                                TodaySeparatorView()
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowSeparator(.hidden)
                            }
                            RowView(occurrence: occurrence, onEdit: { startEditing(occurrence) }) {
                                deleteOccurrence(occurrence)
                            }
                        }
                        if compIdx == complementaryIncomes.count {
                            TodaySeparatorView()
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .listSectionSpacing(.compact)
            .navigationTitle("Recettes du mois")
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
                    EditOccurrenceSheet(occurrence: occurrence) { _ in
                        do {
                            try modelContext.save()
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        } catch {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                            print("Failed to save occurrence: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    private var fixedIncomes: [BudgetEntryOccurrence] {
        occurrences.filter { $0.kind == "income" && $0.isManual == false }
    }
    private var complementaryIncomes: [BudgetEntryOccurrence] {
        occurrences.filter { $0.kind == "income" && $0.isManual == true }
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

    private func startEditing(_ occurrence: BudgetEntryOccurrence) {
        editedOccurrence = occurrence
        showEditSheet = true
    }

    private struct RowView: View {
        let occurrence: BudgetEntryOccurrence
        let onEdit: () -> Void
        let onDelete: () -> Void

        var body: some View {
            HStack {
                Text(dateFormatted(occurrence.date))
                    .font(.callout)
                    .frame(width: 70, alignment: .leading)
                VStack(alignment: .leading) {
                    Text(occurrence.title ?? "")
                        .font(.body)
                }
                Spacer()
                Text(amountFormatted(occurrence.amount))
                    .font(.body.monospacedDigit())
                    .foregroundColor(.green)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
            )
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                    onEdit()
                } label: {
                    Label("Modifier", systemImage: "pencil")
                }
                .tint(.blue)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }

        private func dateFormatted(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM"
            formatter.locale = Locale(identifier: "fr_FR")
            return formatter.string(from: date)
        }

        private func amountFormatted(_ amount: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "EUR"
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
            formatter.positivePrefix = "+"
            return formatter.string(from: NSNumber(value: amount)) ?? "+\(Int(amount))"
        }
    }
}

private struct EditOccurrenceSheet: View {
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
                        occurrence.title = title
                        occurrence.amount = amount
                        occurrence.date = date
                        occurrence.isManual = true
                        onSave(occurrence)
                        dismiss()
                    }
                }
            }
            .onAppear {
                title = occurrence.title ?? ""
                amount = occurrence.amount
                date = occurrence.date
            }
        }
    }
}

#Preview {
    RecettesFixesSheet()
        .modelContainer(DataController.preview.modelContainer)
}
