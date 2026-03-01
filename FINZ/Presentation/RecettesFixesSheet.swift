import SwiftUI
import SwiftData
import UIKit

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

    private var fixedIncomes: [BudgetEntryOccurrence] {
        occurrences.filter { $0.isManual == false }
    }

    private var complementaryIncomes: [BudgetEntryOccurrence] {
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
                Text("Aujourd'hui")
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
                            IncomeRow(occurrence: occurrence, onEdit: { startEditing(occurrence) }, onDelete: { deleteOccurrence(occurrence) })
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
                            IncomeRow(occurrence: occurrence, onEdit: { startEditing(occurrence) }, onDelete: { deleteOccurrence(occurrence) })
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
                    EditIncomeOccurrenceSheet(occurrence: occurrence) { _ in
                        do {
                            try modelContext.save()
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        } catch {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                            print("Failed to save income occurrence: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}

private struct IncomeRow: View {
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
        return "+\(val) €"
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
                .foregroundColor(.green)
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

private struct EditIncomeOccurrenceSheet: View {
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

                    // Amount field (styled like AddIncomeSheet)
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
            occurrence.amount = abs(amount)
        }
        occurrence.date = date
        occurrence.isManual = true
        onSave(occurrence)
        dismiss()
    }
}

#Preview {
    RecettesFixesSheet()
        .modelContainer(DataController.preview.modelContainer)
}
