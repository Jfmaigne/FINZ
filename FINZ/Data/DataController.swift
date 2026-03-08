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
        // Fetch all existing categories
        let allExisting = try modelContext.fetch(FetchDescriptor<MainCategory>())
        
        // Index by (categoryType, name) for quick lookup
        var existingMap: [String: MainCategory] = [:]
        for cat in allExisting {
            existingMap["\(cat.categoryType)_\(cat.name)"] = cat
        }
        
        var addedCount = 0
        
        // Process expense categories
        for (mainCatData, subCatsData) in DefaultCategoryConfiguration.defaultExpenseCategories {
            addedCount += seedOrUpdateCategory(
                mainCatData: mainCatData, subCatsData: subCatsData,
                categoryType: "expense", existingMap: &existingMap,
                modelContext: modelContext
            )
        }
        
        // Process income categories
        for (mainCatData, subCatsData) in DefaultCategoryConfiguration.defaultIncomeCategories {
            addedCount += seedOrUpdateCategory(
                mainCatData: mainCatData, subCatsData: subCatsData,
                categoryType: "income", existingMap: &existingMap,
                modelContext: modelContext
            )
        }
        
        if addedCount > 0 {
            try modelContext.save()
        }
    }
    
    @MainActor
    private static func seedOrUpdateCategory(
        mainCatData: (name: String, displayName: String, icon: String, color: String, order: Int),
        subCatsData: [(name: String, displayName: String, icon: String, order: Int)],
        categoryType: String,
        existingMap: inout [String: MainCategory],
        modelContext: ModelContext
    ) -> Int {
        var added = 0
        let key = "\(categoryType)_\(mainCatData.name)"
        
        let mainCategory: MainCategory
        if let existing = existingMap[key] {
            // Category exists — check for missing subcategories
            mainCategory = existing
        } else {
            // New category — create it
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
            added += 1
        }
        
        // Check and add missing subcategories
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
            added += 1
        }
        
        return added
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
