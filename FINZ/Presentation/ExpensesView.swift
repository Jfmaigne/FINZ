import SwiftUI
import SwiftData
import Combine

struct ExpensesView: View {
    @EnvironmentObject var vm: QuestionnaireViewModel
    @Environment(\.modelContext) var modelContext
    @Environment(\.continueAction) private var continueAction
    @Environment(\.dismiss) private var dismissView

    enum ExpenseCategory: String, CaseIterable, Hashable {
        case logement = "Liées au logement"
        case transport = "Liés au mode de transport"
        case vieCourante = "Liés à la vie courante"
        case abonnements = "Liés aux abonnements réguliers"
        case investissements = "Dépenses liées aux investissements"
        case plaisir = "Dépenses liées au plaisir"
    }

    enum ExpenseKind: String, CaseIterable, Hashable {
        case creditHabitation = "Crédit habitation"
        case assuranceCredit = "Assurance crédit"
        case taxeFonciere = "Taxe foncière"
        case loyerCharges = "Loyer + charges"
        case assuranceHabitation = "Assurance habitation"
        case gaz = "Gaz"
        case electricite = "Électricité"
        case eau = "Eau"
        case creditAuto = "Crédit auto/LOA/LLD"
        case assuranceAuto = "Assurance auto"
        case carburant = "Carburant"
        case abonnementTransport = "Abonnement transport"
        case assuranceVeloTrottinette = "Assurance vélo/trottinette"
        case abonnement = "Abonnement"
        
        var category: ExpenseCategory {
            switch self {
            case .loyerCharges, .creditHabitation, .assuranceHabitation, .electricite, .gaz, .eau:
                return .logement
            case .creditAuto, .assuranceAuto, .entretienReparation, .abonnementTrain, .assuranceVeloTrottinette, .abonnementTransport:
                return .transport
            case .courses, .essences, .cantine, .peage, .carburant:
                return .vieCourante
            case .abonnementTVStreaming, .abonnementMusique, .abonnementInternetFixeMobile, .abonnementSport, .abonnement:
                return .abonnements
            case .creditImmobilierInvest, .assuranceCredit, .taxeFonciere, .impotsFonciers, .creditTravauxDivers:
                return .investissements
            case .habillement, .restaurant, .sortiesConcertCinema, .vacances, .activitesAutres, .parcsAttraction:
                return .plaisir
            }
        }
        
        static var availableKinds: [ExpenseKind] {
            return [
                // Logement
                .loyerCharges, .creditHabitation, .assuranceHabitation, .electricite, .gaz, .eau,
                // Transport (including legacy to preserve edits)
                .creditAuto, .assuranceAuto, .entretienReparation, .abonnementTrain, .assuranceVeloTrottinette, .abonnementTransport,
                // Vie courante (including legacy carburant)
                .courses, .essences, .cantine, .peage, .carburant,
                // Abonnements
                .abonnementTVStreaming, .abonnementMusique, .abonnementInternetFixeMobile, .abonnementSport, .abonnement,
                // Investissements (include both labels)
                .creditImmobilierInvest, .assuranceCredit, .taxeFonciere, .impotsFonciers, .creditTravauxDivers,
                // Plaisir
                .habillement, .restaurant, .sortiesConcertCinema, .vacances, .activitesAutres, .parcsAttraction
            ]
        }
        
        // To avoid compile errors due to legacy kinds not declared, we add them here as cases with raw values:
        case entretienReparation = "Entretien/réparation"
        case abonnementTrain = "Abonnement train"
        case courses = "Courses"
        case essences = "Essences"
        case cantine = "Cantine"
        case peage = "Péage"
        case abonnementTVStreaming = "Abonnement TV/Streaming"
        case abonnementMusique = "Abonnement musique"
        case abonnementInternetFixeMobile = "Abonnement internet fixe/mobile"
        case abonnementSport = "Abonnement sport"
        case creditImmobilierInvest = "Crédit immobilier investissement"
        case impotsFonciers = "Impôts fonciers"
        case creditTravauxDivers = "Crédit travaux/divers"
        case habillement = "Habillement"
        case restaurant = "Restaurant"
        case sortiesConcertCinema = "Sorties/concerts/cinéma"
        case vacances = "Vacances"
        case activitesAutres = "Activités autres"
        case parcsAttraction = "Parcs d’attraction"
    }

    struct ExpenseEntry: Identifiable, Equatable {
        let id: UUID
        var kind: ExpenseKind
        var amount: String
        var periodicity: String = "Mensuel"
        var complement: String = ""
        var provider: String? = nil
        var endDate: Date? = nil
        var mainCategoryID: UUID? = nil
        var subCategoryID: UUID? = nil
    }

    @State private var entries: [ExpenseEntry] = []
    @State private var isSaving: Bool = false
    @State private var saveError: String? = nil
    @State private var editingEntry: ExpenseEntry? = nil
    @State private var showTabs: Bool = false

    let periodicities = ["Annuel", "Trimestriel", "Mensuel", "Hebdomadaire", "Quotidien"]
    
    private var groupedEntries: [(category: ExpenseCategory, items: [ExpenseEntry])] {
        let groups: [ExpenseCategory: [ExpenseEntry]] = Dictionary(grouping: entries) { $0.kind.category }
        let categoryOrder: [ExpenseCategory] = [.logement, .transport, .vieCourante, .abonnements, .investissements, .plaisir]

        var result: [(category: ExpenseCategory, items: [ExpenseEntry])] = []
        
        for cat in categoryOrder {
            guard var items = groups[cat], !items.isEmpty else { continue }
            
            // Create a simple order map
            let order = ExpenseKind.availableKinds.filter { $0.category == cat }
            var orderMap: [ExpenseKind: Int] = [:]
            for (index, kind) in order.enumerated() {
                orderMap[kind] = index
            }
            
            // Sort items by the order map
            items.sort { a, b in
                let aIndex = orderMap[a.kind] ?? Int.max
                let bIndex = orderMap[b.kind] ?? Int.max
                return aIndex < bIndex
            }
            
            result.append((cat, items))
        }
        
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dépenses")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        if entries.isEmpty {
                            Text("Aucune dépense enregistrée")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)

                ForEach(groupedEntries, id: \.category) { group in
                    Section(group.category.rawValue) {
                        ForEach(group.items) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(label(for: entry))
                                        .font(.headline)
                                    Spacer()
                                    Text(entry.amount.isEmpty ? "—" : entry.amount + " €")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }
                                if let detail = detailText(for: entry), !detail.isEmpty {
                                    Text(detail)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                DispatchQueue.main.async {
                                    editingEntry = entry
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    deleteEntry(entry)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    DispatchQueue.main.async {
                                        editingEntry = entry
                                    }
                                } label: {
                                    Label("Modifier", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
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
            .finzHeader()
            .stickyNextButton(enabled: !entries.isEmpty, action: saveAll)
            .navigationTitle("Dépenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let newEntry = ExpenseEntry(id: UUID(), kind: .creditHabitation, amount: "")
                        DispatchQueue.main.async {
                            editingEntry = newEntry
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 34, height: 34)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .accessibilityLabel("Ajouter une dépense")
                }
            }
            .onAppear(perform: setupEntries)
            .sheet(item: $editingEntry) { item in
                AddExpenseSheet(entry: item) { updatedEntry in
                    if let idx = entries.firstIndex(where: { $0.id == updatedEntry.id }) {
                        entries[idx] = updatedEntry
                    } else {
                        entries.append(updatedEntry)
                    }
                    editingEntry = nil
                }
            }
            .alert("Erreur", isPresented: Binding<Bool>(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = saveError {
                    Text(error)
                }
            }
            .fullScreenCover(isPresented: $showTabs) {
                BudgetTabView()
                    .environmentObject(vm)
            }
        }
    }

    private func label(for entry: ExpenseEntry) -> String {
        return entry.kind.rawValue
    }

    private func detailText(for entry: ExpenseEntry) -> String? {
        var details: [String] = []

        if !entry.periodicity.isEmpty {
            details.append(entry.periodicity)
        }

        if let parsed = parseComplement(entry.complement) {
            if let monthsCSV = parsed.months, !monthsCSV.isEmpty {
                details.append("mois: \(monthShortNames(from: monthsCSV))")
            }
            if let day = parsed.day, day > 0 {
                details.append("jour \(Int(day))")
            }
        }

        if let endDate = entry.endDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr")
            formatter.dateStyle = .medium
            details.append("Jusqu’au \(formatter.string(from: endDate))")
        }

        if let comment = parseComment(entry.complement), !comment.isEmpty {
            details.append(comment)
        }

        return details.isEmpty ? nil : details.joined(separator: " • ")
    }

    private func setupEntries() {
        // Fetch existing expenses
        let fetchDescriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.kind, order: .forward)]
        )
        do {
            let fetched = try modelContext.fetch(fetchDescriptor)
            if !fetched.isEmpty {
                entries = fetched.map {
                    ExpenseEntry(
                        id: $0.id,
                        kind: ExpenseKind(rawValue: $0.kind) ?? .assuranceHabitation,
                        amount: String(format: "%.0f", $0.amount),
                        periodicity: $0.periodicity,
                        complement: $0.complement ?? "",
                        provider: $0.provider,
                        endDate: $0.endDate
                    )
                }
                return
            }
        } catch {
            print("Failed to fetch expenses: \(error)")
        }
        // do nothing, fallback to defaults below

        // Defaults based on housing status
        var defaults: [ExpenseEntry] = []

        switch vm.housingStatus {
        case .owner:
            defaults.append(contentsOf: [
                ExpenseEntry(id: UUID(), kind: .creditHabitation, amount: ""),
                ExpenseEntry(id: UUID(), kind: .assuranceCredit, amount: ""),
                ExpenseEntry(id: UUID(), kind: .taxeFonciere, amount: "")
            ])
        case .renter:
            defaults.append(ExpenseEntry(id: UUID(), kind: .loyerCharges, amount: ""))
        case .none:
            break
        }

        defaults.append(contentsOf: [
            ExpenseEntry(id: UUID(), kind: .assuranceHabitation, amount: ""),
            ExpenseEntry(id: UUID(), kind: .gaz, amount: ""),
            ExpenseEntry(id: UUID(), kind: .electricite, amount: ""),
            ExpenseEntry(id: UUID(), kind: .eau, amount: "")
        ])

        defaults.append(contentsOf: [
            ExpenseEntry(id: UUID(), kind: .abonnementInternetFixeMobile, amount: ""),
            ExpenseEntry(id: UUID(), kind: .abonnementTVStreaming, amount: "")
        ])
        
        entries = defaults
    }

    private func saveAll() {
        isSaving = true
        saveError = nil

        do {
            try persistEntries()
        } catch {
            saveError = error.localizedDescription
            isSaving = false
            return
        }

        do {
            try BudgetProjectionManager.projectExpenses(for: Date(), modelContext: modelContext)
        } catch {
            // non fatal error, just log or ignore
        }
        isSaving = false
        if let action = continueAction {
            action()
        } else {
            showTabs = true
        }
    }

    private func persistEntries() throws {
        let fetchDescriptor = FetchDescriptor<Expense>()
        let allIds = entries.map { $0.id }
        // Delete expenses not in entries
        let existing = try modelContext.fetch(fetchDescriptor)
        for expense in existing {
            if !allIds.contains(expense.id) {
                modelContext.delete(expense)
            }
        }

        for entry in entries {
            let entryID = entry.id
            let fetchSingle = FetchDescriptor<Expense>(
                predicate: #Predicate { $0.id == entryID }
            )
            let expensesFound = try modelContext.fetch(fetchSingle)
            let expense: Expense
            if let found = expensesFound.first {
                expense = found
            } else {
                expense = Expense(
                    id: entry.id,
                    amount: 0,
                    complement: entry.complement,
                    day: -1,
                    endDate: entry.endDate,
                    kind: entry.kind.rawValue,
                    months: nil,
                    note: nil,
                    periodicity: entry.periodicity,
                    provider: nil
                )
                modelContext.insert(expense)
            }
            expense.kind = entry.kind.rawValue
            expense.amount = Double(entry.amount.replacingOccurrences(of: ",", with: ".")) ?? 0
            expense.periodicity = entry.periodicity
            expense.complement = entry.complement
            if let (months, day) = parseComplement(entry.complement) {
                expense.months = months
                expense.day = day ?? -1
            } else {
                expense.months = nil
                expense.day = -1
            }
            expense.provider = nil
            expense.endDate = entry.endDate
        }

        try modelContext.save()
    }

    private func parseComplement(_ complement: String) -> (months: String?, day: Int16?)? {
        // Same logic as in RecettesView (stub implementation)
        // Format example: "mois=1,2,3;jour=15"
        // We'll parse months=CSV and day=Int if found
        let parts = complement.split(separator: ";")
        var monthsCSV: String?
        var dayInt: Int16?
        for part in parts {
            let keyVal = part.split(separator: "=")
            if keyVal.count == 2 {
                let key = keyVal[0].trimmingCharacters(in: .whitespaces)
                let val = keyVal[1].trimmingCharacters(in: .whitespaces)
                if key.lowercased() == "mois" || key.lowercased() == "months" {
                    monthsCSV = val
                } else if key.lowercased() == "jour" || key.lowercased() == "day" {
                    dayInt = Int16(val) ?? nil
                }
            }
        }
        if monthsCSV != nil || dayInt != nil {
            return (monthsCSV, dayInt)
        }
        return nil
    }
    
    private func parseComment(_ complement: String) -> String? {
        let parts = complement.split(separator: ";")
        for part in parts {
            let keyVal = part.split(separator: "=", maxSplits: 1)
            if keyVal.count == 2 {
                let key = keyVal[0].trimmingCharacters(in: .whitespaces).lowercased()
                let val = keyVal[1].trimmingCharacters(in: .whitespaces)
                if key == "comment" || key == "note" || key == "desc" {
                    return val.isEmpty ? nil : val
                }
            }
        }
        return nil
    }

    private func monthShortNames(from csv: String) -> String {
        // Parse CSV into concrete [Int]
        let components: [Substring] = csv.split(separator: ",")
        let months: [Int] = components.compactMap { comp in
            let trimmed = comp.trimmingCharacters(in: .whitespaces)
            return Int(trimmed)
        }

        let symbols: [String] = Calendar.current.shortMonthSymbols
        let names: [String] = months.compactMap { idx -> String? in
            guard idx >= 1, idx <= symbols.count else { return nil }
            return symbols[idx - 1].lowercased()
        }
        return names.joined(separator: ", ")
    }
    
    private func deleteEntry(_ entry: ExpenseEntry) {
        // Remove from in-memory list
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries.remove(at: idx)
        }
        
        // Remove from persistent store if present
        do {
            let entryID = entry.id
            let fetch = FetchDescriptor<Expense>(
                predicate: #Predicate { $0.id == entryID }
            )
            let matches = try modelContext.fetch(fetch)
            for exp in matches {
                modelContext.delete(exp)
            }
            if modelContext.hasChanges {
                try modelContext.save()
            }
        } catch {
            // Not fatal for UI; persistence will reconcile on next saveAll
            print("Failed to delete expense: \(error)")
        }
    }
}
