import Foundation

/// Helper pour mapper les nouvelles catégories vers les anciennes ExpenseKind
struct CategoryToExpenseMapper {
    
    /// Mappe une sous-catégorie vers un ExpenseKind
    static func mapSubCategoryToExpenseKind(_ subCategory: SubCategory) -> ExpensesView.ExpenseKind? {
        let subCatName = subCategory.name
        
        let mapping: [String: ExpensesView.ExpenseKind] = [
            // Logement
            "rent": .loyerCharges,
            "electricity": .electricite,
            "gas": .gaz,
            "water": .eau,
            "home_insurance": .assuranceHabitation,
            "mortgage": .creditHabitation,
            "mortgage_insurance": .assuranceCredit,
            "property_tax": .taxeFonciere,
            
            // Transport
            "fuel": .carburant,
            "car_insurance": .assuranceAuto,
            "maintenance": .entretienReparation,
            "public_transport": .abonnementTransport,
            "train": .abonnementTrain,
            "car_loan": .creditAuto,
            "bike_insurance": .assuranceVeloTrottinette,
            
            // Alimentation
            "groceries": .courses,
            "restaurant": .restaurant,
            "cafeteria": .cantine,
            "tolls": .peage,
            
            // Abonnements
            "internet_mobile": .abonnementInternetFixeMobile,
            "streaming": .abonnementTVStreaming,
            "music": .abonnementMusique,
            "sports": .abonnementSport,
            "other_subscriptions": .abonnement,
            
            // Vêtements
            "clothing": .habillement,
            "shoes": .habillement,
            "accessories": .habillement,
            
            // Loisirs
            "cinema": .sortiesConcertCinema,
            "vacation": .vacances,
            "hobbies": .activitesAutres,
            "parks": .parcsAttraction,
            
            // Santé
            "doctor": .assuranceHabitation,
            "pharmacy": .assuranceHabitation,
            "dentist": .assuranceHabitation,
            
            // Éducation
            "courses": .courses,
            "books": .courses,
            "school": .courses,
        ]
        
        return mapping[subCatName]
    }
}
