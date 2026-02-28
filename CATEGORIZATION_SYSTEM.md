# 📊 Système de Catégorisation FINZ

## Overview

Un nouveau système de catégorisation complet a été mis en place pour mieux organiser les revenus et dépenses. Le système utilise deux niveaux de catégories :

1. **Catégories Principales** - Groupes larges (ex: Logement, Transport)
2. **Sous-Catégories** - Éléments spécifiques (ex: Loyer, Carburant)

---

## 📋 Architecture

### Modèles SwiftData

#### MainCategory
```swift
@Model
final class MainCategory {
    var id: UUID          // Identifiant unique
    var name: String      // Code interne (ex: "housing")
    var displayName: String // Nom affiché (ex: "Logement")
    var icon: String      // Emoji/icône (ex: "🏠")
    var color: String     // Couleur en hex (ex: "#FF6B6B")
    var categoryType: String // "income" ou "expense"
    var order: Int        // Ordre d'affichage
    var subCategories: [SubCategory] // Sous-catégories
}
```

#### SubCategory
```swift
@Model
final class SubCategory {
    var id: UUID
    var name: String      // Code interne (ex: "rent")
    var displayName: String // Nom affiché (ex: "Loyer + charges")
    var icon: String      // Emoji/icône
    var order: Int        // Ordre d'affichage
    var mainCategory: MainCategory? // Catégorie parente
}
```

#### Income & Expense (mis à jour)
```swift
@Model
final class Income {
    // ...propriétés existantes...
    var mainCategoryID: UUID?     // Référence à MainCategory
    var subCategoryID: UUID?      // Référence à SubCategory
}

@Model
final class Expense {
    // ...propriétés existantes...
    var mainCategoryID: UUID?     // Référence à MainCategory
    var subCategoryID: UUID?      // Référence à SubCategory
}
```

---

## 💰 Catégories de Dépenses

### 1. **Logement** 🏠 (#FF6B6B)
- Loyer + charges
- Crédit habitation
- Assurance crédit
- Taxe foncière
- Assurance habitation
- Électricité
- Gaz
- Eau

### 2. **Transport** 🚗 (#4ECDC4)
- Crédit auto/LOA/LLD
- Assurance auto
- Entretien/réparation
- Carburant
- Abonnement transport
- Abonnement train
- Assurance vélo/trottinette

### 3. **Vie Courante** 🛍️ (#FFE66D)
- Courses
- Restaurant
- Cantine
- Péage
- Habillement

### 4. **Abonnements** 📱 (#95E1D3)
- Abonnement internet fixe/mobile
- Abonnement TV/Streaming
- Abonnement musique
- Abonnement sport
- Autres abonnements

### 5. **Loisirs** 🎉 (#FFB3BA)
- Sorties/concerts/cinéma
- Vacances
- Activités
- Parcs d'attraction

### 6. **Investissements** 📈 (#A8E6CF)
- Crédit immobilier investissement
- Crédit travaux/divers
- Impôts fonciers
- Rénovations

---

## 💵 Catégories de Revenus

### 1. **Revenus Principaux** 💼 (#4ECDC4)
- Salaire
- Revenus auto-entrepreneur
- Revenu entreprise

### 2. **Revenus Complémentaires** 💵 (#FFE66D)
- Freelance/contrats
- Tutorat/cours
- Revenu locatif
- Revenus d'investissement
- Bonus/primes

### 3. **Aides Sociales** 🤝 (#FFB3BA)
- Allocation chômage
- Allocation handicap
- Allocations familiales
- Allocation logement
- RSA
- Autres aides

### 4. **Bourses** 🎓 (#A8E6CF)
- Bourse universitaire
- Bourse gouvernementale
- Bourse scolaire

### 5. **Revenus Exceptionnels** 🎊 (#95E1D3)
- Cadeaux/dons
- Héritage
- Remboursement d'impôts
- Remises/cashback
- Autre revenu

---

## 🔧 Fichiers Créés

### 1. **CategoryModels.swift**
Contient les définitions des modèles `MainCategory`, `SubCategory` et les données de référence dans `CategoryReference`.

### 2. **CategorySeeder.swift**
Contient `CategorySeeder` pour initialiser les catégories dans la base de données. Fonction principale :
```swift
static func seedCategories(in modelContext: ModelContext) async throws
```

### 3. **CategoryMapper.swift**
Contient `CategoryMapper` pour mapper les anciennes catégories (ExpenseKind, IncomeKind) vers les nouvelles catégories. Utile pour la migration des données existantes.

### 4. **Models.swift** (mis à jour)
Ajout de `mainCategoryID` et `subCategoryID` aux modèles `Income` et `Expense`.

### 5. **DataController.swift** (mis à jour)
Intégration des nouveaux modèles dans le Schema et initialisation automatique des catégories.

---

## 📲 Utilisation

### Seed initial (automatique)
```swift
// Dans DataController, au démarrage :
try await CategorySeeder.seedCategories(in: modelContext)
```

### Récupérer les catégories
```swift
// Catégories principales
let expenseCategories = try await CategorySeeder.getMainCategories(
    for: "expense",
    in: modelContext
)

// Sous-catégories d'une catégorie
let subCats = CategorySeeder.getSubCategories(
    for: mainCategory,
    in: modelContext
)
```

### Mapper une ancienne catégorie
```swift
// Depuis ExpenseKind
let (mainCat, subCat) = CategoryMapper.getExpenseCategories(
    for: "loyerCharges",
    mainCategories: expenseCategories
)

// Assigner à une dépense
expense.mainCategoryID = mainCat?.id
expense.subCategoryID = subCat?.id
```

---

## 🔄 Prochaines Étapes

### Phase 2 : Migration des données
- [ ] Ajouter une migration pour assigner les catégories aux dépenses/revenus existants
- [ ] Mettre à jour ExpensesView pour utiliser les nouvelles catégories
- [ ] Mettre à jour RecettesView pour utiliser les nouvelles catégories

### Phase 3 : UI/UX
- [ ] Créer des pickers de catégories pour l'ajout de dépenses/revenus
- [ ] Afficher les icônes et couleurs des catégories
- [ ] Trier/filtrer par catégorie dans les statistiques

### Phase 4 : Analytics
- [ ] Utiliser les catégories dans StatisticsView
- [ ] Graphiques par catégorie principale
- [ ] Comparaison inter-catégories

---

## 📝 Notes Importantes

1. Les catégories sont seedées automatiquement au premier lancement
2. Les catégories sont stockées dans la base de données (pas en dur dans le code)
3. Les anciennes catégories (ExpenseKind, IncomeKind) peuvent coexister temporairement
4. Le CategoryMapper aide à la transition vers le nouveau système
5. Chaque catégorie a un code interne stable (`name`) et un nom affiché (`displayName`)

---

**Migration SwiftData - Catégorisation**  
*Version 1.0 - 27 Février 2026*
