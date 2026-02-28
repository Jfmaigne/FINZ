import Foundation

/// Helper pour mapper les nouvelles catégories vers les anciennes IncomeKind
struct CategoryToIncomeMapper {
    
    /// Mappe une sous-catégorie vers un IncomeKind
    static func mapSubCategoryToIncomeKind(_ subCategory: SubCategory) -> RecettesView.IncomeKind? {
        let subCatName = subCategory.name
        
        let mapping: [String: RecettesView.IncomeKind] = [
            // Revenus Principaux
            "salary": .salaire,
            "self_employed": .salaire,
            "business": .salaire,
            
            // Revenus Complémentaires
            "freelance": .prime,
            "tutoring": .remboursementFrais,
            "rental": .loyersPercus,
            "investment_income": .interets,
            "bonus": .prime,
            
            // Aides Sociales
            "unemployment": .allocationAutre,
            "disability": .allocationHandicap,
            "family_allowance": .allocationAutre,
            "housing_allowance": .allocationLogement,
            "rsa": .allocationAutre,
            "other_benefits": .allocation,
            
            // Bourses
            "university_scholarship": .bourse,
            "government_grant": .bourse,
            "school_grant": .bourse,
            
            // Revenus Exceptionnels
            "gifts": .parents,
            "inheritance": .venteBien,
            "tax_refund": .gainExceptionnel,
            "cashback": .gainExceptionnel,
            "other": .gainExceptionnel,
        ]
        
        return mapping[subCatName]
    }
}
