import SwiftUI
import SwiftData

struct AddFixedIncomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var entry: RecettesView.IncomeEntry?
    var onSave: (RecettesView.IncomeEntry?) -> Void

    @State private var localKind: RecettesView.IncomeKind = .salaire
    @State private var amountText: String = ""
    @State private var periodicity: String = "Mensuel"
    @State private var selectedMonths: Set<Int> = []
    @State private var day: Int = 1
    @State private var error: String? = nil
    @State private var comment: String = ""
    
    // Category states
    @State private var mainCategories: [MainCategory] = []
    @State private var selectedMainCategory: MainCategory?
    @State private var selectedSubCategory: SubCategory?
    
    @FocusState private var amountFieldFocused: Bool

    private let periodicities = ["Mensuel", "Mois spécifiques"]
    private let months = Array(1...12)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Renseigne ta recette fixe")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)

                    // Category Selection
                    if !mainCategories.isEmpty {
                        VStack(spacing: 16) {
                            CategorySelectionView(
                                selectedMainCategory: $selectedMainCategory,
                                selectedSubCategory: $selectedSubCategory,
                                mainCategories: mainCategories
                            )
                            
                            SubCategorySelectionView(
                                selectedSubCategory: $selectedSubCategory,
                                mainCategory: selectedMainCategory
                            )
                        }
                        .padding(.horizontal)
                    } else {
                        Text("Chargement des catégories...")
                            .foregroundColor(.secondary)
                    }

                    // Amount card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Montant").font(.headline)
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Spacer()
                            TextField("0", text: $amountText)
                                .keyboardType(.decimalPad)
                                .focused($amountFieldFocused)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.8)
                            Text("€")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(.secondarySystemBackground), Color(.secondarySystemBackground)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // Periodicity card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Périodicité").font(.headline)
                        Picker("Périodicité", selection: $periodicity) {
                            Text("Mensuel").tag("Mensuel")
                            Text("Mois spécifiques").tag("Mois spécifiques")
                        }
                        .pickerStyle(.segmented)

                        if periodicity == "Mois spécifiques" {
                            MonthGrid(selectedMonths: $selectedMonths)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(.secondarySystemBackground), Color(.secondarySystemBackground)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // Day card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Jour dans le mois").font(.headline)
                        DayGrid(selectedDay: $day)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(.secondarySystemBackground), Color(.secondarySystemBackground)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // Comment card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Commentaire (optionnel)").font(.headline)
                        TextField("Note, précision...", text: $comment)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(.secondarySystemBackground), Color(.secondarySystemBackground)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

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
            .navigationTitle("Nouvelle recette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { save() }
                        .disabled((Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0) <= 0 || (periodicity == "Mois spécifiques" && selectedMonths.isEmpty))
                }
            }
            .onAppear {
                loadCategories()
                loadFromBinding()
            }
        }
    }

    private func loadFromBinding() {
        guard let e = entry else { return }
        localKind = e.kind
        amountText = e.amount
        selectedMonths = []
        day = 1
        comment = ""

        var hasSpecificMonths = false
        let complement = e.complement
        if !complement.isEmpty {
            let parts = complement.split(separator: ";")
            for part in parts {
                let pair = part.split(separator: "=", maxSplits: 1)
                if pair.count == 2 {
                    let key = pair[0].trimmingCharacters(in: .whitespaces)
                    let value = String(pair[1]).trimmingCharacters(in: .whitespaces)
                    if key == "jour", let d = Int(value) {
                        day = d
                    } else if key == "mois" {
                        let monthsStr = value.split(separator: ",")
                        let monthsSet = Set(monthsStr.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
                        selectedMonths = monthsSet
                        hasSpecificMonths = !monthsSet.isEmpty
                    } else if key == "comment" {
                        comment = value.removingPercentEncoding ?? value
                    }
                }
            }
        }
        periodicity = hasSpecificMonths ? "Mois spécifiques" : "Mensuel"
    }

    private func save() {
        error = nil
        let amt = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard amt > 0 else {
            error = "Veuillez saisir un montant valide"
            return
        }
        if periodicity == "Mois spécifiques" && selectedMonths.isEmpty {
            error = "Sélectionnez au moins un mois"
            return
        }
        
        var updated = entry ?? RecettesView.IncomeEntry(kind: localKind)
        
        // Update category IDs if selected
        if let subCat = selectedSubCategory {
            updated.mainCategoryID = subCat.mainCategory?.id
            updated.subCategoryID = subCat.id
            // Update localKind based on the selected sub-category
            if let mappedKind = CategoryToIncomeMapper.mapSubCategoryToIncomeKind(subCat) {
                updated.kind = mappedKind
            }
        } else {
            updated.kind = localKind
        }
        
        updated.amount = amountText
        updated.periodicity = periodicity
        
        // Build complement with optional comment
        var complementParts: [String] = []
        if periodicity == "Mois spécifiques" {
            let monthsStr = selectedMonths.sorted().map(String.init).joined(separator: ",")
            complementParts.append("mois=\(monthsStr)")
        }
        complementParts.append("jour=\(day)")
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedComment.isEmpty {
            let encoded = trimmedComment.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? trimmedComment
            complementParts.append("comment=\(encoded)")
        }
        updated.complement = complementParts.joined(separator: ";")
        
        onSave(updated)
        dismiss()
    }
    
    private func loadCategories() {
        let fetchDescriptor = FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.categoryType == "income" },
            sortBy: [SortDescriptor(\.order, order: .forward)]
        )
        
        do {
            mainCategories = try modelContext.fetch(fetchDescriptor)
            // Sélectionner la première catégorie par défaut
            if let first = mainCategories.first {
                selectedMainCategory = first
                selectedSubCategory = first.subCategories.first
            }
        } catch {
            print("Erreur lors du chargement des catégories: \(error)")
        }
    }
}

private struct MonthGrid: View {
    @Binding var selectedMonths: Set<Int>
    private let monthSymbols = Calendar.current.monthSymbols

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(1...12, id: \.self) { m in
                let isOn = selectedMonths.contains(m)
                Button(action: { toggle(m) }) {
                    Text(shortName(for: m))
                        .font(.footnote)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(isOn ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }

    private func toggle(_ m: Int) {
        if selectedMonths.contains(m) {
            selectedMonths.remove(m)
        } else {
            selectedMonths.insert(m)
        }
    }

    private func shortName(for month: Int) -> String {
        let name = monthSymbols[month - 1]
        return String(name.prefix(3))
    }
}

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
