import SwiftUI
import SwiftData
import UIKit

struct AddExpenseQuickSheet: View {
    var defaultDate: Date
    var onSaved: () -> Void
    var onCancel: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var amountText: String = ""
    @State private var date: Date
    @State private var note: String = ""
    @State private var error: String? = nil
    @FocusState private var amountFocused: Bool
    @State private var pulse: Bool = false
    
    // Category states
    @State private var mainCategories: [MainCategory] = []
    @State private var selectedMainCategory: MainCategory?
    @State private var selectedSubCategory: SubCategory?

    init(defaultDate: Date = Date(), onSaved: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.defaultDate = defaultDate
        self.onSaved = onSaved
        self.onCancel = onCancel
        _date = State(initialValue: defaultDate)
    }

    var body: some View {
        ZStack {
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
            
            // EVERYTHING SCROLLABLE INCLUDING HEADER
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 12) {
                    // Header SCROLLABLE with buttons
                    HStack {
                        Button(action: { onCancel() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
                        }
                        Spacer()
                        Image("finz_logo_couleur")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 110)
                            .accessibilityLabel("Finz")
                        Spacer()
                        Button(action: { save() }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(
                                    LinearGradient(colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    VStack(spacing: 2) {
                        HStack { Spacer()
                            Text("Renseigne les infos de ta dépense")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)], startPoint: .leading, endPoint: .trailing)
                                )
                            Spacer() }
                    }
                    .padding(.bottom, 8)
                    
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
                    .padding(.horizontal, 20)
                    
                    // Category Selection
                    if !mainCategories.isEmpty {
                        VStack(spacing: 12) {
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
                        .padding()
                    }

                    // DatePicker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Spacer()
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            Spacer() }
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
                    .padding(.horizontal, 20)
                    
                    // Comment field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Commentaire (optionnel)").font(.headline)
                        TextField("Source, note…", text: $note)
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
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    
                    if let error = error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, 4)
                    }
                    
                    // Extra space to ensure we can scroll past keyboard
                    Color.clear.frame(height: 20)
                }
                .padding(.vertical, 12)
            }
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onTapGesture {
            // Dismiss keyboard when tapping anywhere
            amountFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            loadCategories()
        }
    }
    
    private func loadCategories() {
        let fetchDescriptor = FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.categoryType == "expense" },
            sortBy: [SortDescriptor(\.order, order: .forward)]
        )
        
        do {
            mainCategories = try modelContext.fetch(fetchDescriptor)
            if let first = mainCategories.first {
                selectedMainCategory = first
                selectedSubCategory = first.subCategories.first
            }
        } catch {
            print("Erreur lors du chargement des catégories: \(error)")
        }
    }

    private func save() {
        error = nil
        
        let cleanAmountText = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amountDouble = Double(cleanAmountText), amountDouble > 0 else {
            error = "Veuillez entrer un montant valide supérieur à zéro."
            pulseAmountField()
            return
        }
        
        let amount = -abs(amountDouble) // negative for expense
        
        let title = note.isEmpty ? "Dépense" : "\(note)"
        
        let occurrence = BudgetEntryOccurrence(
            date: date,
            amount: amount,
            kind: "expense",
            title: title,
            monthKey: BudgetProjectionManager.monthKey(for: date),
            isManual: true
        )
        
        // Ajouter les IDs des catégories si sélectionnées
        if let subCat = selectedSubCategory {
            occurrence.mainCategoryID = subCat.mainCategory?.id
            occurrence.subCategoryID = subCat.id
        }
        
        modelContext.insert(occurrence)
        
        do {
            try modelContext.save()
            let success = UINotificationFeedbackGenerator()
            success.notificationOccurred(.success)
            withAnimation(.easeInOut(duration: 0.12)) { pulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeOut(duration: 0.12)) { pulse = false }
                onSaved()
            }
        } catch {
            self.error = "Erreur lors de la sauvegarde."
            pulseAmountField()
        }
    }
    
    private func pulseAmountField() {
        withAnimation(.easeInOut(duration: 0.25)) {
            pulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.25)) {
                pulse = false
            }
        }
    }
}

#Preview {
    AddExpenseQuickSheet(defaultDate: Date(), onSaved: {}, onCancel: {})
        .modelContainer(DataController.preview.modelContainer)
}
