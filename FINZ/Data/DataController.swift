import Foundation
import SwiftData

@MainActor
final class DataController {
    
    // MARK: - Category Seeding (appelé par AuthApp au lancement)
    
    static func seedCategories(in context: ModelContext) throws {
        try seedCategoriesSyncStatic(in: context)
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
    static var previewContainer: ModelContainer = {
        let schema = Schema([
            BudgetEntryOccurrence.self,
            Income.self,
            Expense.self,
            MainCategory.self,
            SubCategory.self,
            DeferredCard.self,
            DeferredCardExpense.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            
            let sample = BudgetEntryOccurrence(
                date: Date(),
                amount: 100.0,
                kind: "income",
                title: "Salaire",
                monthKey: "2026-02",
                isManual: false
            )
            context.insert(sample)
            
            return container
        } catch {
            fatalError("Preview container failed: \(error)")
        }
    }()
}
