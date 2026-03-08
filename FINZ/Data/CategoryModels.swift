import Foundation
import SwiftData

// MARK: - Main Category Model

@Model
final class MainCategory {
    var id: UUID
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
        name: String = "",
        displayName: String = "",
        icon: String = "",
        color: String = "",
        categoryType: String = "",
        order: Int = 0
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
    var id: UUID
    var name: String
    var displayName: String
    var icon: String
    var order: Int
    
    var mainCategory: MainCategory?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        displayName: String = "",
        icon: String = "",
        order: Int = 0
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
                ("mortgage", "Crédit habitation", "🏦", 1),
                ("rent", "Loyer + charges", "🚪", 2),
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
                ("invest_credit_insurance", "Assurance crédit invest.", "🛡️", 2),
                ("invest_home_insurance", "Assurance logement invest.", "🏠", 3),
                ("works", "Crédit travaux/divers", "🔨", 4),
                ("property_taxes", "Impôts fonciers", "📋", 5),
                ("invest_misc", "Frais divers invest.", "📦", 6),
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
                ("bonus", "Bonus/primes", "🎁", 3),
            ]
        ),
        // INVESTISSEMENTS
        (
            mainCat: ("investment_income", "Investissements", "📈", "#6BCB77", 3),
            subCats: [
                ("interest", "Intérêts", "💹", 1),
                ("rental_income", "Loyers", "🏠", 2),
            ]
        ),
        // AIDES SOCIALES
        (
            mainCat: ("social_benefits", "Aides sociales", "🤝", "#FFB3BA", 4),
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
            mainCat: ("scholarships", "Bourses", "🎓", "#A8E6CF", 5),
            subCats: [
                ("university_scholarship", "Bourse universitaire", "🎓", 1),
                ("government_grant", "Bourse gouvernementale", "📜", 2),
                ("school_grant", "Bourse scolaire", "🏫", 3),
            ]
        ),
        // SANTÉ
        (
            mainCat: ("health_income", "Santé", "⚕️", "#81D4FA", 6),
            subCats: [
                ("social_security", "Sécurité Sociale", "🏛️", 1),
                ("mutual_refund", "Mutuelle", "🏥", 2),
            ]
        ),
        // REVENUS EXCEPTIONNELS
        (
            mainCat: ("exceptional_income", "Revenus exceptionnels", "🎊", "#95E1D3", 7),
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
