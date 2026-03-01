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

@Model
final class DeferredCard {
    @Attribute(.unique) var id: UUID
    var name: String                    // Nom de la carte (ex: "Visa Gold")
    var lastFourDigits: String?         // 4 derniers chiffres (optionnel)
    var cutoffDay: Int16                // Jour de bascule du différé (ex: 25)
    var debitDay: Int16                 // Jour de prélèvement (ex: 4 du mois suivant)
    var monthlyBudget: Double           // Enveloppe mensuelle théorique
    var isActive: Bool                  // Carte active ou non
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        lastFourDigits: String? = nil,
        cutoffDay: Int16 = 25,
        debitDay: Int16 = 4,
        monthlyBudget: Double = 0,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.lastFourDigits = lastFourDigits
        self.cutoffDay = cutoffDay
        self.debitDay = debitDay
        self.monthlyBudget = monthlyBudget
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class DeferredCardExpense {
    @Attribute(.unique) var id: UUID
    var cardID: UUID                    // Référence à la carte
    var amount: Double                  // Montant de la dépense
    var expenseDate: Date               // Date de la dépense
    var expenseDescription: String?     // Description de la dépense
    var cycleStartDate: Date            // Date de début du cycle de différé
    var cycleEndDate: Date              // Date de fin du cycle (bascule)
    var isSettled: Bool                 // Dépense déjà prélevée ou non
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        cardID: UUID,
        amount: Double,
        expenseDate: Date,
        expenseDescription: String? = nil,
        cycleStartDate: Date,
        cycleEndDate: Date,
        isSettled: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.cardID = cardID
        self.amount = amount
        self.expenseDate = expenseDate
        self.expenseDescription = expenseDescription
        self.cycleStartDate = cycleStartDate
        self.cycleEndDate = cycleEndDate
        self.isSettled = isSettled
        self.createdAt = createdAt
    }
}
