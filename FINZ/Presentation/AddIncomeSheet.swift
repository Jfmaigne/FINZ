import SwiftUI
import SwiftData
import UIKit

struct AddIncomeSheet: View {
    var defaultDate: Date
    var onSaved: () -> Void
    var onCancel: () -> Void

    @State private var amountText: String = ""
    @State private var date: Date
    @State private var note: String = ""
    @State private var error: String?
    @FocusState private var amountFocused: Bool
    @State private var pulse: Bool = false
    @State private var showSuccess: Bool = false
    @State private var isReady: Bool = false

    // Category states
    @State private var mainCategories: [MainCategory] = []
    @State private var selectedMainCategory: MainCategory?
    @State private var selectedSubCategory: SubCategory?

    @Environment(\.modelContext) private var modelContext

    // FINZ gradient colors
    private let finzPurple = Color(red: 0.52, green: 0.21, blue: 0.93)
    private let finzPink = Color(red: 1.00, green: 0.29, blue: 0.63)
    private let finzGradient = LinearGradient(colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)], startPoint: .leading, endPoint: .trailing)
    private let grayFill = LinearGradient(colors: [Color(.systemGray6), Color(.systemGray6)], startPoint: .top, endPoint: .bottom)
    private let clearGradient = LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)

    init(defaultDate: Date, onSaved: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.defaultDate = defaultDate
        self.onSaved = onSaved
        self.onCancel = onCancel
        _date = State(initialValue: defaultDate)
    }

    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    headerView
                    amountCardView
                    if isReady {
                        if !mainCategories.isEmpty {
                            categorySectionView
                            subCategorySectionView
                        }
                        dateSectionView
                        errorView
                        saveButtonView
                    }
                    Color.clear.frame(height: 40)
                }
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.immediately)

            // Success overlay
            if showSuccess {
                successOverlay
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .task {
            loadCategories()
            isReady = true
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { onCancel() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
            Text("Nouvelle recette")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Amount Card
    private var amountCardView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            TextField("0", text: $amountText)
                .keyboardType(.decimalPad)
                .focused($amountFocused)
                .multilineTextAlignment(.center)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Color(white: 0.1))
                .minimumScaleFactor(0.5)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("OK") { amountFocused = false }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(finzPurple)
                    }
                }
            Text("€")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    pulse ? finzGradient : clearGradient,
                    lineWidth: 2
                )
        )
        .scaleEffect(pulse ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: pulse)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Category Section
    private var categorySectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("CATÉGORIE", icon: "square.grid.2x2.fill")

            let columns = [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ]

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(mainCategories.sorted { $0.order < $1.order }) { category in
                    IncomeCategoryCellView(
                        category: category,
                        isSelected: selectedMainCategory?.id == category.id,
                        onSelect: {
                            amountFocused = false
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMainCategory = category
                                selectedSubCategory = category.subCategories.sorted { $0.order < $1.order }.first
                            }
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - SubCategory Section
    private var subCategorySectionView: some View {
        Group {
            if let mainCat = selectedMainCategory {
                let subs = mainCat.subCategories.sorted { $0.order < $1.order }
                if !subs.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("SOUS-CATÉGORIE", icon: "tag.fill")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(subs, id: \.id) { subCat in
                                    let isSelected = selectedSubCategory?.id == subCat.id
                                    Button {
                                        amountFocused = false
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedSubCategory = subCat
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(subCat.icon)
                                                .font(.system(size: 14))
                                            Text(subCat.displayName)
                                                .font(.system(size: 13, weight: .medium))
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 9)
                                        .background(
                                            Capsule()
                                                .fill(isSelected ? finzGradient : grayFill)
                                        )
                                        .foregroundStyle(isSelected ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
        }
    }

    // MARK: - Date & Comment Section (fusionnés)
    private var dateSectionView: some View {
        VStack(spacing: 0) {
            // Date row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(finzPurple)
                    Text("Date")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                }
                Spacer()
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(finzPurple)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().padding(.horizontal, 16)

            // Comment row
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(finzPurple)
                    .padding(.top, 2)
                TextField("Commentaire (optionnel)", text: $note, axis: .vertical)
                    .lineLimit(1...3)
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // commentSectionView supprimé et fusionné dans dateSectionView

    // MARK: - Error View
    @ViewBuilder
    private var errorView: some View {
        if let error = error {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.08))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Save Button
    private var saveButtonView: some View {
        Button(action: { save() }) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text("Enregistrer la recette")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(finzGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: finzPurple.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                Text("Recette enregistrée !")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        }
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - Section Label Helper
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(finzGradient)
            Text(text)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(1.5)
        }
    }

    // MARK: - Save Logic
    private func save() {
        error = nil
        let cleanAmountText = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amountDouble = Double(cleanAmountText), amountDouble > 0 else {
            withAnimation { error = "Montant invalide. Saisis un montant supérieur à zéro." }
            pulseAmountField()
            return
        }

        let amount = abs(amountDouble)
        let categoryName = selectedSubCategory?.displayName ?? selectedMainCategory?.displayName ?? "Recette"
        let title = note.isEmpty ? categoryName : "\(categoryName) - \(note)"

        let occurrence = BudgetEntryOccurrence(
            date: date,
            amount: amount,
            kind: "income",
            title: title,
            monthKey: BudgetProjectionManager.monthKey(for: date),
            isManual: true
        )

        if let subCat = selectedSubCategory {
            occurrence.mainCategoryID = subCat.mainCategory?.id
            occurrence.subCategoryID = subCat.id
        }

        modelContext.insert(occurrence)

        do {
            try modelContext.save()
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
            withAnimation(.spring(response: 0.3)) { showSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onSaved()
            }
        } catch {
            self.error = "Erreur lors de la sauvegarde."
            pulseAmountField()
        }
    }

    private func loadCategories() {
        let fetchDescriptor = FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.categoryType == "income" },
            sortBy: [SortDescriptor(\.order, order: .forward)]
        )
        do {
            let categories = try modelContext.fetch(fetchDescriptor)
            mainCategories = categories
            // Sélectionner la première catégorie après le rendu
            if let first = categories.first {
                selectedMainCategory = first
            }
        } catch {
            print("Erreur chargement catégories: \(error)")
        }
    }

    private func pulseAmountField() {
        withAnimation(.easeInOut(duration: 0.2)) { pulse = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) { pulse = false }
        }
    }
}

// MARK: - Income Category Cell (sous-vue isolée pour perf)
private struct IncomeCategoryCellView: View {
    let category: MainCategory
    let isSelected: Bool
    let onSelect: () -> Void

    private static let finzPurple = Color(red: 0.52, green: 0.21, blue: 0.93)
    private static let finzPink = Color(red: 1.00, green: 0.29, blue: 0.63)
    private static let finzGradient = LinearGradient(colors: [finzPurple, finzPink], startPoint: .leading, endPoint: .trailing)
    private static let grayFill = LinearGradient(colors: [Color(.systemGray6), Color(.systemGray6)], startPoint: .top, endPoint: .bottom)

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Text(category.icon)
                    .font(.system(size: 26))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(isSelected ? Self.finzGradient : Self.grayFill)
                    )
                Text(category.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Self.finzPurple.opacity(0.08) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Self.finzPurple.opacity(0.4) : Color(.systemGray5), lineWidth: isSelected ? 1.5 : 1)
            )
            .foregroundStyle(isSelected ? Self.finzPurple : .primary)
        }
        .buttonStyle(.plain)
    }
}
