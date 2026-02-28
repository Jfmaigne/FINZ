import Foundation
import SwiftData

// MARK: - Main Category Model

@Model
final class MainCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var displayName: String
    var icon: String
    var color: String
    var categoryType: String // "income" ou "expense"
    var order: Int
    
    @Relationship(deleteRule: .cascade, inverse: \SubCategory.mainCategory)
    var subCategories: [SubCategory]
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        icon: String,
        color: String,
        categoryType: String,
        order: Int
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.icon = icon
        self.color = color
        self.categoryType = categoryType
        self.order = order
        self.subCategories = []
    }
}

// MARK: - Sub Category Model

@Model
final class SubCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var displayName: String
    var icon: String
    var order: Int
    
    var mainCategory: MainCategory?
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        icon: String,
        order: Int
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.icon = icon
        self.order = order
        self.mainCategory = nil
    }
}

// MARK: - Category Reference Data

struct CategoryReference {
    // MARK: - Expense Categories
    
    static let expenseCategories: [(mainCat: (name: String, displayName: String, icon: String, color: String, order: Int), subCats: [(name: String, displayName: String, icon: String, order: Int)])] = [
        // LOGEMENT
        (
            mainCat: ("housing", "Logement", "🏠", "#FF6B6B", 1),
            subCats: [
                ("rent", "Loyer + charges", "🚪", 1),
                ("mortgage", "Crédit habitation", "🏦", 2),
                ("mortgage_insurance", "Assurance crédit", "🛡️", 3),
                ("property_tax", "Taxe foncière", "📋", 4),
                ("home_insurance", "Assurance habitation", "🏠", 5),
                ("electricity", "Électricité", "💡", 6),
                ("gas", "Gaz", "🔥", 7),
                ("water", "Eau", "💧", 8),
            ]
        ),
        // TRANSPORT
        (
            mainCat: ("transport", "Transport", "🚗", "#4ECDC4", 2),
            subCats: [
                ("car_loan", "Crédit auto/LOA/LLD", "🚗", 1),
                ("car_insurance", "Assurance auto", "🛡️", 2),
                ("maintenance", "Entretien/réparation", "🔧", 3),
                ("fuel", "Carburant", "⛽", 4),
                ("public_transport", "Abonnement transport", "🚌", 5),
                ("train", "Abonnement train", "🚂", 6),
                ("bike_insurance", "Assurance vélo/trottinette", "🚴", 7),
            ]
        ),
        // VIE COURANTE
        (
            mainCat: ("daily_life", "Vie courante", "🛍️", "#FFE66D", 3),
            subCats: [
                ("groceries", "Courses", "🛒", 1),
                ("restaurant", "Restaurant", "🍽️", 2),
                ("cafeteria", "Cantine", "🍴", 3),
                ("tolls", "Péage", "🛣️", 4),
                ("clothing", "Habillement", "👕", 5),
            ]
        ),
        // ABONNEMENTS
        (
            mainCat: ("subscriptions", "Abonnements", "📱", "#95E1D3", 4),
            subCats: [
                ("internet_mobile", "Abonnement internet fixe/mobile", "📡", 1),
                ("streaming", "Abonnement TV/Streaming", "📺", 2),
                ("music", "Abonnement musique", "🎵", 3),
                ("sports", "Abonnement sport", "⚽", 4),
                ("other_subscriptions", "Autres abonnements", "📦", 5),
            ]
        ),
        // LOISIRS
        (
            mainCat: ("entertainment", "Loisirs", "🎉", "#FFB3BA", 5),
            subCats: [
                ("cinema", "Sorties/concerts/cinéma", "🎬", 1),
                ("vacation", "Vacances", "✈️", 2),
                ("activities", "Activités", "🎪", 3),
                ("parks", "Parcs d'attraction", "🎢", 4),
            ]
        ),
        // INVESTISSEMENTS
        (
            mainCat: ("investments", "Investissements", "📈", "#A8E6CF", 6),
            subCats: [
                ("home_investment", "Crédit immobilier investissement", "🏗️", 1),
                ("works", "Crédit travaux/divers", "🔨", 2),
                ("property_taxes", "Impôts fonciers", "📋", 3),
                ("renovations", "Rénovations", "🏠", 4),
            ]
        ),
    ]
    
    // MARK: - Income Categories
    
    static let incomeCategories: [(mainCat: (name: String, displayName: String, icon: String, color: String, order: Int), subCats: [(name: String, displayName: String, icon: String, order: Int)])] = [
        // REVENUS PRINCIPAUX
        (
            mainCat: ("primary_income", "Revenus principaux", "💼", "#4ECDC4", 1),
            subCats: [
                ("salary", "Salaire", "💰", 1),
                ("self_employed", "Revenus auto-entrepreneur", "👨‍💼", 2),
                ("business", "Revenu entreprise", "🏢", 3),
            ]
        ),
        // REVENUS COMPLÉMENTAIRES
        (
            mainCat: ("secondary_income", "Revenus complémentaires", "💵", "#FFE66D", 2),
            subCats: [
                ("freelance", "Freelance/contrats", "💻", 1),
                ("tutoring", "Tutorat/cours", "📚", 2),
                ("rental", "Revenu locatif", "🏠", 3),
                ("investment_income", "Revenus d'investissement", "📈", 4),
                ("bonus", "Bonus/primes", "🎁", 5),
            ]
        ),
        // AIDES SOCIALES
        (
            mainCat: ("social_benefits", "Aides sociales", "🤝", "#FFB3BA", 3),
            subCats: [
                ("unemployment", "Allocation chômage", "📋", 1),
                ("disability", "Allocation handicap", "♿", 2),
                ("family_allowance", "Allocations familiales", "👨‍👩‍👧‍👦", 3),
                ("housing_allowance", "Allocation logement", "🏠", 4),
                ("rsa", "RSA", "💳", 5),
                ("other_benefits", "Autres aides", "🆘", 6),
            ]
        ),
        // BOURSES
        (
            mainCat: ("scholarships", "Bourses", "🎓", "#A8E6CF", 4),
            subCats: [
                ("university_scholarship", "Bourse universitaire", "🎓", 1),
                ("government_grant", "Bourse gouvernementale", "📜", 2),
                ("school_grant", "Bourse scolaire", "🏫", 3),
            ]
        ),
        // REVENUS EXCEPTIONNELS
        (
            mainCat: ("exceptional_income", "Revenus exceptionnels", "🎊", "#95E1D3", 5),
            subCats: [
                ("gifts", "Cadeaux/dons", "🎁", 1),
                ("inheritance", "Héritage", "💎", 2),
                ("tax_refund", "Remboursement d'impôts", "💸", 3),
                ("cashback", "Remises/cashback", "💰", 4),
                ("other", "Autre revenu", "❓", 5),
            ]
        ),
    ]
}
