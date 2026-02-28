import Foundation
import SwiftData

@MainActor
struct CategorySeeder {
    
    /// Initialise ou met à jour les catégories dans la base de données
    static func seedCategories(in modelContext: ModelContext) async throws {
        // Vérifier si les catégories existent déjà
        let existingExpense = try modelContext.fetch(FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.categoryType == "expense" }
        ))
        
        if !existingExpense.isEmpty {
            // Les catégories existent déjà
            return
        }
        
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
            
            modelContext.insert(mainCategory)
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
            
            modelContext.insert(mainCategory)
        }
        
        try modelContext.save()
    }
    
    /// Récupère les catégories principales pour un type donné
    static func getMainCategories(for type: String, in modelContext: ModelContext) async throws -> [MainCategory] {
        let fetchDescriptor = FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.categoryType == type },
            sortBy: [SortDescriptor(\.order, order: .forward)]
        )
        return try modelContext.fetch(fetchDescriptor)
    }
    
    /// Récupère les sous-catégories pour une catégorie principale
    static func getSubCategories(for mainCategory: MainCategory, in modelContext: ModelContext) -> [SubCategory] {
        return mainCategory.subCategories.sorted { $0.order < $1.order }
    }
    
    /// Récupère une catégorie principale par ID
    static func getMainCategory(by id: UUID, in modelContext: ModelContext) async throws -> MainCategory? {
        let fetchDescriptor = FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(fetchDescriptor).first
    }
    
    /// Récupère une sous-catégorie par ID
    static func getSubCategory(by id: UUID, in modelContext: ModelContext) async throws -> SubCategory? {
        let fetchDescriptor = FetchDescriptor<SubCategory>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(fetchDescriptor).first
    }
}
