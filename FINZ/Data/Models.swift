import Foundation
import SwiftData

@Model
final class BudgetEntryOccurrence {
    @Attribute(.unique) var id: UUID
    var date: Date
    var amount: Double
    var kind: String // "income", "expense", "balance"
    var title: String?
    var monthKey: String
    var isManual: Bool
    var sourceid: UUID?
    var createdAt: Date
    var updatedAt: Date
    var mainCategoryID: UUID?
    var subCategoryID: UUID?
    
    init(
        id: UUID = UUID(),
        date: Date,
        amount: Double,
        kind: String,
        title: String? = nil,
        monthKey: String,
        isManual: Bool = false,
        sourceid: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        mainCategoryID: UUID? = nil,
        subCategoryID: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.kind = kind
        self.title = title
        self.monthKey = monthKey
        self.isManual = isManual
        self.sourceid = sourceid
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.mainCategoryID = mainCategoryID
        self.subCategoryID = subCategoryID
    }
}

@Model
final class Income {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var complement: String?
    var day: Int16
    var kind: String
    var months: String?
    var periodicity: String
    
    // Nouvelles propriétés pour les catégories
    var mainCategoryID: UUID?
    var subCategoryID: UUID?
    
    init(
        id: UUID = UUID(),
        amount: Double,
        complement: String? = nil,
        day: Int16,
        kind: String,
        months: String? = nil,
        periodicity: String,
        mainCategoryID: UUID? = nil,
        subCategoryID: UUID? = nil
    ) {
        self.id = id
        self.amount = amount
        self.complement = complement
        self.day = day
        self.kind = kind
        self.months = months
        self.periodicity = periodicity
        self.mainCategoryID = mainCategoryID
        self.subCategoryID = subCategoryID
    }
}

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var complement: String?
    var day: Int16
    var endDate: Date?
    var kind: String
    var months: String?
    var note: String?
    var periodicity: String
    var provider: String?
    
    // Nouvelles propriétés pour les catégories
    var mainCategoryID: UUID?
    var subCategoryID: UUID?
    
    init(
        id: UUID = UUID(),
        amount: Double,
        complement: String? = nil,
        day: Int16,
        endDate: Date? = nil,
        kind: String,
        months: String? = nil,
        note: String? = nil,
        periodicity: String,
        provider: String? = nil,
        mainCategoryID: UUID? = nil,
        subCategoryID: UUID? = nil
    ) {
        self.id = id
        self.amount = amount
        self.complement = complement
        self.day = day
        self.endDate = endDate
        self.kind = kind
        self.months = months
        self.note = note
        self.periodicity = periodicity
        self.provider = provider
        self.mainCategoryID = mainCategoryID
        self.subCategoryID = subCategoryID
    }
}
