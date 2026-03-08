import Foundation
import SwiftData

/// Helper pour réinitialiser les catégories avec les valeurs par défaut
@MainActor
struct DefaultCategoryConfiguration {
    
    /// Réinitialise toutes les catégories avec la configuration par défaut
    static func resetToDefaults(in modelContext: ModelContext) async throws {
        // Supprimer les catégories existantes
        let expenseFetch = FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.categoryType == "expense" }
        )
        let incomeFetch = FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.categoryType == "income" }
        )
        
        let existingExpenses = try modelContext.fetch(expenseFetch)
        let existingIncomes = try modelContext.fetch(incomeFetch)
        
        for cat in existingExpenses + existingIncomes {
            modelContext.delete(cat)
        }
        
        try modelContext.save()
        
        // Insérer les catégories par défaut
        try await CategorySeeder.seedCategories(in: modelContext)
    }
    
    /// Configuration des catégories de dépenses par défaut
    static let defaultExpenseCategories: [(mainCat: (name: String, displayName: String, icon: String, color: String, order: Int), subCats: [(name: String, displayName: String, icon: String, order: Int)])] = [
        // LOGEMENT - Le plus important
        (
            mainCat: ("housing", "Logement", "🏠", "#FF6B6B", 1),
            subCats: [
                ("mortgage", "Crédit immobilier", "🏦", 1),
                ("rent", "Loyer + charges", "🚪", 2),
                ("electricity", "Électricité", "💡", 3),
                ("gas", "Gaz", "🔥", 4),
                ("water", "Eau", "💧", 5),
                ("home_insurance", "Assurance habitation", "🛡️", 6),
            ]
        ),
        
        // TRANSPORT
        (
            mainCat: ("transport", "Transport", "🚗", "#4ECDC4", 2),
            subCats: [
                ("car_loan", "Crédit Auto/LOA/LLD", "🚗", 1),
                ("fuel", "Carburant", "⛽", 2),
                ("car_insurance", "Assurance auto", "🛡️", 3),
                ("maintenance", "Entretien/réparation", "🔧", 4),
                ("public_transport", "Transports en commun", "🚌", 5),
            ]
        ),
        
        // ALIMENTATION
        (
            mainCat: ("food", "Alimentation", "🛒", "#FFE66D", 3),
            subCats: [
                ("groceries", "Courses", "🛍️", 1),
                ("restaurant", "Restaurant/Café", "🍽️", 2),
                ("delivery", "Livraison de repas", "🍔", 3),
            ]
        ),
        
        // ABONNEMENTS
        (
            mainCat: ("subscriptions", "Abonnements", "📱", "#95E1D3", 4),
            subCats: [
                ("internet_mobile", "Internet/Téléphone", "📡", 1),
                ("streaming", "Streaming (Netflix, etc)", "📺", 2),
                ("gym", "Gym/Sport", "💪", 3),
                ("other_subscriptions", "Autres abonnements", "📦", 4),
            ]
        ),
        
        // LOISIRS
        (
            mainCat: ("entertainment", "Loisirs", "🎉", "#FFB3BA", 5),
            subCats: [
                ("cinema", "Cinéma/Théâtre", "🎬", 1),
                ("vacation", "Vacances/Voyage", "✈️", 2),
                ("hobbies", "Hobbies/Loisirs", "🎨", 3),
            ]
        ),
        
        // SANTÉ
        (
            mainCat: ("health", "Santé", "⚕️", "#A8E6CF", 6),
            subCats: [
                ("doctor", "Médecin/Consultation", "👨‍⚕️", 1),
                ("pharmacy", "Pharmacie", "💊", 2),
                ("dentist", "Dentiste", "🦷", 3),
                ("mutual_health", "Mutuelle", "🏥", 4),
            ]
        ),
        
        // VÊTEMENTS & ACCESSOIRES
        (
            mainCat: ("clothing", "Vêtements", "👕", "#C7B3E5", 7),
            subCats: [
                ("clothes", "Vêtements", "👔", 1),
                ("shoes", "Chaussures", "👞", 2),
                ("accessories", "Accessoires", "👜", 3),
            ]
        ),
        
        // ÉDUCATION
        (
            mainCat: ("education", "Éducation", "📚", "#FFDAB9", 8),
            subCats: [
                ("courses", "Cours/Formation", "🎓", 1),
                ("books", "Livres", "📖", 2),
                ("school", "Frais scolaires", "🏫", 3),
            ]
        ),
        
        // INVESTISSEMENTS
        (
            mainCat: ("investments", "Investissements", "📈", "#A8E6CF", 9),
            subCats: [
                ("invest_credit", "Crédit", "🏗️", 1),
                ("invest_credit_insurance", "Assurance Crédit", "🛡️", 2),
                ("invest_home_insurance", "Assurance Logement", "🏠", 3),
                ("invest_misc", "Frais divers", "📦", 4),
            ]
        ),
    ]
    
    /// Configuration des catégories de revenus par défaut
    static let defaultIncomeCategories: [(mainCat: (name: String, displayName: String, icon: String, color: String, order: Int), subCats: [(name: String, displayName: String, icon: String, order: Int)])] = [
        // REVENUS PRINCIPAUX
        (
            mainCat: ("primary_income", "Revenus Principaux", "💼", "#4ECDC4", 1),
            subCats: [
                ("salary", "Salaire", "💰", 1),
                ("self_employed", "Auto-entrepreneur", "👨‍💼", 2),
            ]
        ),
        
        // REVENUS COMPLÉMENTAIRES
        (
            mainCat: ("secondary_income", "Revenus Complémentaires", "💵", "#FFE66D", 2),
            subCats: [
                ("freelance", "Freelance", "💻", 1),
                ("bonus", "Bonus/Primes", "🎁", 2),
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
        
        // AIDES & ALLOCATIONS
        (
            mainCat: ("social_benefits", "Aides & Allocations", "🤝", "#FFB3BA", 4),
            subCats: [
                ("unemployment", "Allocation chômage", "📋", 1),
                ("family_allowance", "Allocations familiales", "👨‍👩‍👧‍👦", 2),
                ("housing_allowance", "Allocation logement", "🏠", 3),
            ]
        ),
        
        // SANTÉ
        (
            mainCat: ("health_income", "Santé", "⚕️", "#81D4FA", 5),
            subCats: [
                ("social_security", "Sécurité Sociale", "🏛️", 1),
                ("mutual_refund", "Mutuelle", "🏥", 2),
            ]
        ),
        
        // REVENUS EXCEPTIONNELS
        (
            mainCat: ("exceptional_income", "Revenus Exceptionnels", "🎊", "#A8E6CF", 6),
            subCats: [
                ("gifts", "Cadeaux/Dons", "🎁", 1),
                ("inheritance", "Héritage", "💎", 2),
                ("tax_refund", "Remboursement impôts", "💸", 3),
            ]
        ),
    ]
    
    /// Vérifie si la configuration par défaut est appliquée
    static func isDefaultConfigurationApplied(in modelContext: ModelContext) throws -> Bool {
        let expenseFetch = FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.categoryType == "expense" }
        )
        let expenses = try modelContext.fetch(expenseFetch)
        return !expenses.isEmpty
    }
}
