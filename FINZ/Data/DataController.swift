import Foundation
import SwiftData

@MainActor
final class DataController {
    static let shared = DataController()
    
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    private init() {
        let schema = Schema([
            BudgetEntryOccurrence.self,
            Income.self,
            Expense.self,
            MainCategory.self,
            SubCategory.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            modelContext = ModelContext(modelContainer)
            
            // Initialiser les catégories de manière synchrone
            do {
                try seedCategoriesSync()
            } catch {
                print("Erreur lors du seed des catégories: \(error.localizedDescription)")
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // Static method for seeding categories
    @MainActor
    static func seedCategories(in context: ModelContext) throws {
        try seedCategoriesSyncStatic(in: context)
    }
    
    // Instance method called from init
    private func seedCategoriesSync() throws {
        try Self.seedCategoriesSyncStatic(in: modelContext)
    }
    
    @MainActor
    private static func seedCategoriesSyncStatic(in modelContext: ModelContext) throws {
        // Vérifier si les catégories existent déjà
        let fetchDescriptor = FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.categoryType == "expense" }
        )
        
        let existing = try modelContext.fetch(fetchDescriptor)
        
        if !existing.isEmpty {
            // Les catégories existent déjà
            print("✅ Les catégories existent déjà (\(existing.count) catégories de dépenses)")
            return
        }
        
        print("🌱 Création des catégories par défaut...")
        
        // Insérer les catégories de dépenses par défaut
        for (mainCatData, subCatsData) in DefaultCategoryConfiguration.defaultExpenseCategories {
            let mainCategory = MainCategory(
                name: mainCatData.name,
                displayName: mainCatData.displayName,
                icon: mainCatData.icon,
                color: mainCatData.color,
                categoryType: "expense",
                order: mainCatData.order
            )
            
            // Insérer la catégorie principale
            modelContext.insert(mainCategory)
            
            // Créer et ajouter les sous-catégories
            for (index, subCatData) in subCatsData.enumerated() {
                let subCategory = SubCategory(
                    name: subCatData.name,
                    displayName: subCatData.displayName,
                    icon: subCatData.icon,
                    order: index + 1
                )
                subCategory.mainCategory = mainCategory
                mainCategory.subCategories.append(subCategory)
                modelContext.insert(subCategory)
            }
        }
        
        // Insérer les catégories de revenus par défaut
        for (mainCatData, subCatsData) in DefaultCategoryConfiguration.defaultIncomeCategories {
            let mainCategory = MainCategory(
                name: mainCatData.name,
                displayName: mainCatData.displayName,
                icon: mainCatData.icon,
                color: mainCatData.color,
                categoryType: "income",
                order: mainCatData.order
            )
            
            // Insérer la catégorie principale
            modelContext.insert(mainCategory)
            
            // Créer et ajouter les sous-catégories
            for (index, subCatData) in subCatsData.enumerated() {
                let subCategory = SubCategory(
                    name: subCatData.name,
                    displayName: subCatData.displayName,
                    icon: subCatData.icon,
                    order: index + 1
                )
                subCategory.mainCategory = mainCategory
                mainCategory.subCategories.append(subCategory)
                modelContext.insert(subCategory)
            }
        }
        
        try modelContext.save()
        print("✅ Catégories créées avec succès !")
    }
    
    // MARK: - Preview Support
    
    @MainActor
    static var preview: DataController = {
        let schema = Schema([
            BudgetEntryOccurrence.self,
            Income.self,
            Expense.self,
            MainCategory.self,
            SubCategory.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        let controller = DataController()
        
        // Ajouter des données de preview si besoin
        let sampleOccurrence = BudgetEntryOccurrence(
            date: Date(),
            amount: 100.0,
            kind: "income",
            title: "Salaire",
            monthKey: "2026-02",
            isManual: false
        )
        
        controller.modelContext.insert(sampleOccurrence)
        
        return controller
    }()
}
