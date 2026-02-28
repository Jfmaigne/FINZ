import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategoryType: String = "expense"
    @State private var mainCategories: [MainCategory] = []
    @State private var showAddMainCategorySheet = false
    @State private var showAddSubCategorySheet = false
    @State private var showEditSubCategorySheet = false
    @State private var selectedMainCategory: MainCategory?
    @State private var selectedSubCategory: SubCategory?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showResetConfirmation = false
    
    private let categoryTypes = [("expense", "Dépenses"), ("income", "Revenus")]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Picker
                HStack(spacing: 12) {
                    Button(action: {
                        selectedCategoryType = "expense"
                        loadCategories()
                    }) {
                        Text("Dépenses")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedCategoryType == "expense" ? .white : Color(red: 0.52, green: 0.21, blue: 0.93))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        selectedCategoryType == "expense"
                                        ? LinearGradient(
                                            colors: [
                                                Color(red: 0.52, green: 0.21, blue: 0.93),
                                                Color(red: 1.00, green: 0.29, blue: 0.63)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [Color.white, Color.white],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        selectedCategoryType == "expense"
                                        ? Color.clear
                                        : Color(red: 0.52, green: 0.21, blue: 0.93),
                                        lineWidth: 2
                                    )
                            )
                    }
                    
                    Button(action: {
                        selectedCategoryType = "income"
                        loadCategories()
                    }) {
                        Text("Revenus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedCategoryType == "income" ? .white : Color(red: 0.52, green: 0.21, blue: 0.93))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        selectedCategoryType == "income"
                                        ? LinearGradient(
                                            colors: [
                                                Color(red: 0.52, green: 0.21, blue: 0.93),
                                                Color(red: 1.00, green: 0.29, blue: 0.63)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [Color.white, Color.white],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        selectedCategoryType == "income"
                                        ? Color.clear
                                        : Color(red: 0.52, green: 0.21, blue: 0.93),
                                        lineWidth: 2
                                    )
                            )
                    }
                }
                .padding(16)
                .background(Color.white)
                
                // Liste des catégories
                List {
                    ForEach(mainCategories.sorted { $0.order < $1.order }) { mainCat in
                        Section {
                            // Sous-catégories
                    ForEach(mainCat.subCategories.sorted { $0.order < $1.order }) { subCat in
                        HStack {
                            Text(subCat.icon)
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subCat.displayName)
                                    .font(.body)
                            }
                            Spacer()
                        }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button(action: {
                                        selectedSubCategory = subCat
                                        showEditSubCategorySheet = true
                                    }) {
                                        Label("Modifier", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteSubCategory(subCat, from: mainCat)
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                }
                            }
                            
                            // Bouton pour ajouter une sous-catégorie
                            Button(action: {
                                selectedMainCategory = mainCat
                                showAddSubCategorySheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Ajouter une sous-catégorie")
                                        .foregroundColor(.blue)
                                }
                            }
                        } header: {
                            HStack {
                                Text(mainCat.icon)
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mainCat.displayName)
                                        .font(.headline)
                                }
                                Spacer()
                                Circle()
                                    .fill(Color(hex: mainCat.color) ?? .blue)
                                    .frame(width: 16, height: 16)
                            }
                        } footer: {
                            HStack {
                                Spacer()
                                Button(role: .destructive) {
                                    deleteMainCategory(mainCat)
                                } label: {
                                    Label("Supprimer cette catégorie", systemImage: "trash")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Gestion des Catégories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddMainCategorySheet = true }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.52, green: 0.21, blue: 0.93),
                                            Color(red: 1.00, green: 0.29, blue: 0.63)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 34, height: 34)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddMainCategorySheet) {
                AddMainCategorySheet(
                    categoryType: selectedCategoryType,
                    onSave: { newCategory in
                        modelContext.insert(newCategory)
                        try? modelContext.save()
                        loadCategories()
                    }
                )
            }
            .sheet(isPresented: $showAddSubCategorySheet) {
                if let mainCat = selectedMainCategory {
                    AddSubCategorySheet(
                        mainCategory: mainCat,
                        onSave: { newSubCategory in
                            mainCat.subCategories.append(newSubCategory)
                            try? modelContext.save()
                            loadCategories()
                        }
                    )
                }
            }
            .sheet(isPresented: $showEditSubCategorySheet) {
                if let subCat = selectedSubCategory {
                    EditSubCategorySheet(
                        subCategory: subCat,
                        onSave: { _ in
                            try? modelContext.save()
                            loadCategories()
                        }
                    )
                }
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Une erreur est survenue")
            }
            .alert("Réinitialiser les catégories ?", isPresented: $showResetConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Réinitialiser", role: .destructive) {
                    Task {
                        await resetToDefaults()
                    }
                }
            } message: {
                Text("Cela supprimera toutes vos catégories personnalisées et restaurera la configuration par défaut.\n\nVous aurez accès à 8 catégories de dépenses et 4 de revenus.")
            }
        }
        .onAppear {
            loadCategories()
        }
    }
    
    // MARK: - Private Methods
    
    private func resetToDefaults() async {
        do {
            try await DefaultCategoryConfiguration.resetToDefaults(in: modelContext)
            loadCategories()
            
            // Afficher un message de succès
            errorMessage = "Configuration par défaut restaurée avec succès"
            showError = true
        } catch {
            errorMessage = "Erreur lors de la réinitialisation: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func loadCategories() {
        let fetchDescriptor = FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.categoryType == selectedCategoryType },
            sortBy: [SortDescriptor(\.order, order: .forward)]
        )
        
        do {
            mainCategories = try modelContext.fetch(fetchDescriptor)
            print("📂 Catégories chargées: \(mainCategories.count) de type '\(selectedCategoryType)'")
            for cat in mainCategories {
                print("   - \(cat.icon) \(cat.displayName) (\(cat.subCategories.count) sous-cat)")
            }
        } catch {
            errorMessage = "Erreur lors du chargement des catégories: \(error.localizedDescription)"
            showError = true
            print("❌ Erreur de chargement: \(error.localizedDescription)")
        }
    }
    
    private func deleteMainCategory(_ category: MainCategory) {
        // Vérifier s'il y a des revenus/dépenses utilisant cette catégorie
        let categoryID = category.id
        
        let expenseFetch = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.mainCategoryID == categoryID }
        )
        
        let incomeFetch = FetchDescriptor<Income>(
            predicate: #Predicate { $0.mainCategoryID == categoryID }
        )
        
        do {
            let expenseCount = try modelContext.fetch(expenseFetch).count
            let incomeCount = try modelContext.fetch(incomeFetch).count
            
            if expenseCount > 0 || incomeCount > 0 {
                errorMessage = "Impossible de supprimer cette catégorie car elle est utilisée par \(expenseCount + incomeCount) élément(s)"
                showError = true
                return
            }
            
            modelContext.delete(category)
            try modelContext.save()
            loadCategories()
        } catch {
            errorMessage = "Erreur lors de la suppression: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func deleteSubCategory(_ subCategory: SubCategory, from mainCategory: MainCategory) {
        // Vérifier s'il y a des revenus/dépenses utilisant cette sous-catégorie
        let subCategoryID = subCategory.id
        
        let expenseFetch = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.subCategoryID == subCategoryID }
        )
        
        let incomeFetch = FetchDescriptor<Income>(
            predicate: #Predicate { $0.subCategoryID == subCategoryID }
        )
        
        do {
            let expenseCount = try modelContext.fetch(expenseFetch).count
            let incomeCount = try modelContext.fetch(incomeFetch).count
            
            if expenseCount > 0 || incomeCount > 0 {
                errorMessage = "Impossible de supprimer cette sous-catégorie car elle est utilisée par \(expenseCount + incomeCount) élément(s)"
                showError = true
                return
            }
            
            if let index = mainCategory.subCategories.firstIndex(where: { $0.id == subCategory.id }) {
                mainCategory.subCategories.remove(at: index)
                try modelContext.save()
                loadCategories()
            }
        } catch {
            errorMessage = "Erreur lors de la suppression: \(error.localizedDescription)"
            showError = true
        }
    }
}
