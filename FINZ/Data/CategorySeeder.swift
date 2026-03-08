import Foundation
import SwiftData

@MainActor
struct CategorySeeder {
    
    /// Initialise ou met à jour les catégories dans la base de données
    static func seedCategories(in modelContext: ModelContext) async throws {
        // Fetch all existing categories
        let allExisting = try modelContext.fetch(FetchDescriptor<MainCategory>())
        
        // Index by (categoryType, name)
        var existingMap: [String: MainCategory] = [:]
        for cat in allExisting {
            existingMap["\(cat.categoryType)_\(cat.name)"] = cat
        }
        
        // Process expense categories
        for (mainCatData, subCatsData) in DefaultCategoryConfiguration.defaultExpenseCategories {
            seedOrUpdate(mainCatData: mainCatData, subCatsData: subCatsData,
                         categoryType: "expense", existingMap: &existingMap,
                         modelContext: modelContext)
        }
        
        // Process income categories
        for (mainCatData, subCatsData) in DefaultCategoryConfiguration.defaultIncomeCategories {
            seedOrUpdate(mainCatData: mainCatData, subCatsData: subCatsData,
                         categoryType: "income", existingMap: &existingMap,
                         modelContext: modelContext)
        }
        
        try modelContext.save()
    }
    
    private static func seedOrUpdate(
        mainCatData: (name: String, displayName: String, icon: String, color: String, order: Int),
        subCatsData: [(name: String, displayName: String, icon: String, order: Int)],
        categoryType: String,
        existingMap: inout [String: MainCategory],
        modelContext: ModelContext
    ) {
        let key = "\(categoryType)_\(mainCatData.name)"
        
        let mainCategory: MainCategory
        if let existing = existingMap[key] {
            mainCategory = existing
        } else {
            mainCategory = MainCategory(
                name: mainCatData.name,
                displayName: mainCatData.displayName,
                icon: mainCatData.icon,
                color: mainCatData.color,
                categoryType: categoryType,
                order: mainCatData.order
            )
            modelContext.insert(mainCategory)
            existingMap[key] = mainCategory
        }
        
        // Add missing subcategories
        let existingSubNames = Set(mainCategory.subCategories.map { $0.name })
        for subCatData in subCatsData {
            guard !existingSubNames.contains(subCatData.name) else { continue }
            let subCategory = SubCategory(
                name: subCatData.name,
                displayName: subCatData.displayName,
                icon: subCatData.icon,
                order: subCatData.order
            )
            subCategory.mainCategory = mainCategory
            mainCategory.subCategories.append(subCategory)
            modelContext.insert(subCategory)
        }
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
