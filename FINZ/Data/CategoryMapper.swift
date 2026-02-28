import Foundation
import SwiftData

/// Helper pour mapper les catégories antigas (ExpenseKind) vers les nouvelles catégories (MainCategory/SubCategory)
struct CategoryMapper {
    
    /// Mappe un ExpenseKind ancien vers les IDs de catégories
    static func mapExpenseKind(_ kind: String) -> (mainCategoryID: UUID?, subCategoryID: UUID?) {
        // Cette fonction devra être appelée après que les catégories soient chargées
        // Pour maintenant, on retourne nil - à mettre en place plus tard
        return (nil, nil)
    }
    
    /// Mappe un IncomeKind ancien vers les IDs de catégories
    static func mapIncomeKind(_ kind: String) -> (mainCategoryID: UUID?, subCategoryID: UUID?) {
        // Cette fonction devra être appelée après que les catégories soient chargées
        // Pour maintenant, on retourne nil - à mettre en place plus tard
        return (nil, nil)
    }
    
    /// Association entre les codes d'expenses anciennes et les nouvelles catégories
    static let expenseMappings: [String: (mainCategory: String, subCategory: String)] = [
        // Logement
        "loyerCharges": ("housing", "rent"),
        "creditHabitation": ("housing", "mortgage"),
        "assuranceCredit": ("housing", "mortgage_insurance"),
        "taxeFonciere": ("housing", "property_tax"),
        "assuranceHabitation": ("housing", "home_insurance"),
        "electricite": ("housing", "electricity"),
        "gaz": ("housing", "gas"),
        "eau": ("housing", "water"),
        
        // Transport
        "creditAuto": ("transport", "car_loan"),
        "assuranceAuto": ("transport", "car_insurance"),
        "entretienReparation": ("transport", "maintenance"),
        "carburant": ("transport", "fuel"),
        "abonnementTransport": ("transport", "public_transport"),
        "abonnementTrain": ("transport", "train"),
        "assuranceVeloTrottinette": ("transport", "bike_insurance"),
        
        // Vie courante
        "courses": ("daily_life", "groceries"),
        "essences": ("daily_life", "fuel"),
        "cantine": ("daily_life", "cafeteria"),
        "peage": ("daily_life", "tolls"),
        "restaurant": ("daily_life", "restaurant"),
        "habillement": ("daily_life", "clothing"),
        
        // Abonnements
        "abonnementInternetFixeMobile": ("subscriptions", "internet_mobile"),
        "abonnementTVStreaming": ("subscriptions", "streaming"),
        "abonnementMusique": ("subscriptions", "music"),
        "abonnementSport": ("subscriptions", "sports"),
        "abonnement": ("subscriptions", "other_subscriptions"),
        
        // Loisirs
        "sortiesConcertCinema": ("entertainment", "cinema"),
        "vacances": ("entertainment", "vacation"),
        "activitesAutres": ("entertainment", "activities"),
        "parcsAttraction": ("entertainment", "parks"),
        
        // Investissements
        "creditImmobilierInvest": ("investments", "home_investment"),
        "creditTravauxDivers": ("investments", "works"),
        "impotsFonciers": ("investments", "property_taxes"),
    ]
    
    /// Association entre les codes d'incomes anciennes et les nouvelles catégories
    static let incomeMappings: [String: (mainCategory: String, subCategory: String)] = [
        // Revenus principaux
        "salaire": ("primary_income", "salary"),
        "self_employed": ("primary_income", "self_employed"),
        "business": ("primary_income", "business"),
        
        // Revenus complémentaires
        "freelance": ("secondary_income", "freelance"),
        "tutoring": ("secondary_income", "tutoring"),
        "rental": ("secondary_income", "rental"),
        "investment_income": ("secondary_income", "investment_income"),
        "bonus": ("secondary_income", "bonus"),
        
        // Aides sociales
        "unemployment": ("social_benefits", "unemployment"),
        "disability": ("social_benefits", "disability"),
        "family_allowance": ("social_benefits", "family_allowance"),
        "housing_allowance": ("social_benefits", "housing_allowance"),
        "rsa": ("social_benefits", "rsa"),
        "other_benefits": ("social_benefits", "other_benefits"),
        
        // Bourses
        "university_scholarship": ("scholarships", "university_scholarship"),
        "government_grant": ("scholarships", "government_grant"),
        "school_grant": ("scholarships", "school_grant"),
        
        // Revenus exceptionnels
        "gifts": ("exceptional_income", "gifts"),
        "inheritance": ("exceptional_income", "inheritance"),
        "tax_refund": ("exceptional_income", "tax_refund"),
        "cashback": ("exceptional_income", "cashback"),
        "other": ("exceptional_income", "other"),
        
        // Allocations
        "allocation": ("social_benefits", "family_allowance"),
        "allocationLogement": ("social_benefits", "housing_allowance"),
        
        // Autres
        "parents": ("exceptional_income", "gifts"),
        "bourse": ("scholarships", "government_grant"),
        "autre": ("exceptional_income", "other"),
    ]
    
    /// Récupère la catégorie principale et sous-catégorie pour un ancien code de dépense
    static func getExpenseCategories(
        for code: String,
        mainCategories: [MainCategory]
    ) -> (main: MainCategory?, sub: SubCategory?) {
        guard let mapping = expenseMappings[code] else {
            return (nil, nil)
        }
        
        let mainCat = mainCategories.first { $0.name == mapping.mainCategory }
        let subCat = mainCat?.subCategories.first { $0.name == mapping.subCategory }
        
        return (mainCat, subCat)
    }
    
    /// Récupère la catégorie principale et sous-catégorie pour un ancien code de revenu
    static func getIncomeCategories(
        for code: String,
        mainCategories: [MainCategory]
    ) -> (main: MainCategory?, sub: SubCategory?) {
        guard let mapping = incomeMappings[code] else {
            return (nil, nil)
        }
        
        let mainCat = mainCategories.first { $0.name == mapping.mainCategory }
        let subCat = mainCat?.subCategories.first { $0.name == mapping.subCategory }
        
        return (mainCat, subCat)
    }
}
