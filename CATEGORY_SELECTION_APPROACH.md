# 📊 Approche d'Intégration des Catégories dans AddExpenseSheet

## 🎯 Objectif
Intégrer une sélection de catégorie principale et sous-catégorie dans le flux d'ajout d'une dépense, tout en respectant le design FINZ existant.

---

## 🎨 Design Proposé

### Vue Actuelle
```
┌─────────────────────────────────┐
│  FINZ Logo                      │
│  "Renseigne ta dépense fixe"    │
├─────────────────────────────────┤
│  Montant: [      € ]            │
├─────────────────────────────────┤
│  Type de dépense: [   Picker   ]│
├─────────────────────────────────┤
│  Périodicité & autres...        │
└─────────────────────────────────┘
```

### Vue Proposée (avec Catégories)
```
┌─────────────────────────────────┐
│  FINZ Logo                      │
│  "Renseigne ta dépense fixe"    │
├─────────────────────────────────┤
│  Montant: [      € ]            │
├─────────────────────────────────┤
│  Catégorie Principale:          │
│  [🏠 Logement] [🚗 Transport]  │
│  [🛒 Alimen.] [📱 Abonne.]    │
│  (Grille 2x2 avec gradient)     │
├─────────────────────────────────┤
│  Sous-Catégorie:                │
│  [🚪 Loyer] [💡 Électricité]  │
│  (Grille adaptée à la sélection)│
├─────────────────────────────────┤
│  Type de dépense: [   Picker   ]│
├─────────────────────────────────┤
│  Périodicité & autres...        │
└─────────────────────────────────┘
```

---

## 📐 Structure Recommandée

### 1. **Sélection de Catégorie Principale** 🏠
- **Type** : Grille de boutons (2 colonnes, auto-rows)
- **Design** :
  - Boutons carré avec coins arrondis (12pt)
  - **Inactif** : Fond blanc, bordure grise fine
  - **Actif** : Gradient FINZ (purple → pink)
  - **Icône** : 28pt
  - **Texte** : 12pt, semibold
  - **Padding** : 12pt

### 2. **Sélection de Sous-Catégorie** 📦
- **Type** : Grille fluide (1-3 colonnes selon le nombre de sous-cat)
- **Design** :
  - Boutons pilules (coins arrondis 8pt)
  - **Inactif** : Fond gris clair, texte gris
  - **Actif** : Fond gradient FINZ, texte blanc
  - **Texte** : 11pt, medium
  - **Padding** : 8pt vertical, 12pt horizontal

### 3. **Synchronisation avec Type** 🔗
- Quand l'utilisateur sélectionne une catégorie/sous-catégorie
- Le picker "Type de dépense" se met à jour automatiquement (OLD system)
- **OU** On remplace le picker par une info de catégorie

---

## 🔄 Flux de Données

```
MainCategory sélectionnée
    ↓
Afficher ses SubCategories
    ↓
SubCategory sélectionnée
    ↓
Mapper vers ExpenseKind (ancien système)
    ↓
Sauvegarder mainCategoryID + subCategoryID
```

---

## 💾 Modifications Nécessaires

### 1. **ExpensesView.ExpenseEntry**
```swift
struct ExpenseEntry: Identifiable, Equatable {
    let id: UUID
    var kind: ExpenseKind          // Garder pour compatibilité
    var amount: String
    var periodicity: String
    var complement: String
    var provider: String?
    var endDate: Date?
    
    // NOUVEAU ✅
    var mainCategoryID: UUID?      // Référence à MainCategory
    var subCategoryID: UUID?       // Référence à SubCategory
}
```

### 2. **AddExpenseSheet**
Ajouter :
```swift
@State private var selectedMainCategory: MainCategory?
@State private var selectedSubCategory: SubCategory?
@State private var mainCategories: [MainCategory] = []

// Au init :
Task { await loadCategories() }

// Nouvelles vues :
CategorySelectionView()     // Grille catégories principales
SubCategorySelectionView()  // Grille sous-catégories
```

### 3. **Mapping Legacy**
Helper pour mapper catégories → ExpenseKind :
```swift
func mapCategoryToExpenseKind() -> ExpenseKind? {
    // Depuis mainCategoryID + subCategoryID
    // → Trouver le ExpenseKind correspondant
}
```

---

## 🎯 Avantages de cette Approche

✅ **Visuel**
- Intuitive et claire
- Respecte le design FINZ
- Catégories visibles avec icônes + couleurs
- Facile de scanner rapidement

✅ **UX**
- Sélection progressive (principale → sous-catégorie)
- Évite un long picker avec 40+ options
- Feedback visuel immédiat

✅ **Compatibilité**
- Garder l'ancien système `ExpenseKind`
- Migration progressive possible
- Pas de breaking changes

✅ **Données**
- Stocke les deux systèmes temporairement
- Permet la migration future
- Intégrité complète des données

---

## 📱 Exemple d'Écran Complet

```
┌─────────────────────────────────────┐
│ Renseigne ta dépense fixe          │
├─────────────────────────────────────┤
│           [    500 €    ]           │
├─────────────────────────────────────┤
│ Catégorie Principale:               │
│ ┌──────────┐  ┌──────────┐         │
│ │ 🏠       │  │ 🚗       │         │
│ │ Logement │  │ Transport│         │
│ └──────────┘  └──────────┘         │
│ ┌──────────┐  ┌──────────┐         │
│ │ 🛒       │  │ 📱       │         │
│ │ Alimen.  │  │ Abonne.  │         │
│ └──────────┘  └──────────┘         │
├─────────────────────────────────────┤
│ Sous-Catégorie:                     │
│ [🚪 Loyer] [💡 Élec] [🔥 Gaz]    │
├─────────────────────────────────────┤
│ Périodicité: [Mensuel ▼]           │
│ Mois: [J F M A M J J A S O N D]  │
├─────────────────────────────────────┤
│ [Annuler]      [Enregistrer]       │
└─────────────────────────────────────┘
```

---

## 🚀 Étapes d'Implémentation

1. ✅ **Étape 1** : Mettre à jour `ExpenseEntry` avec IDs catégories
2. ⏳ **Étape 2** : Créer `CategorySelectionView` (grille principale)
3. ⏳ **Étape 3** : Créer `SubCategorySelectionView` (grille sous-cat)
4. ⏳ **Étape 4** : Intégrer dans `AddExpenseSheet`
5. ⏳ **Étape 5** : Ajouter mapper legacy (`ExpenseKind`)
6. ⏳ **Étape 6** : Tester et itérer

---

## ❓ Questions de Design

**1. Garder le picker "Type" ?**
- Option A : Garder pour rétrocompatibilité
- Option B : Remplacer entièrement par catégories
- **Recommandation** : Option A pour migration progressive

**2. Ordre d'apparition ?**
- Avant ou après le montant ?
- **Recommandation** : Après le montant (comme "Type" actuellement)

**3. Obligatoire ou Optionnel ?**
- Les catégories doivent-elles être obligatoires ?
- **Recommandation** : Optionnel au début, obligatoire plus tard

---

**Cette approche balance entre :**
- 🎨 Design FINZ homogène
- 👥 UX intuitive et progressive
- 🔄 Compatibilité avec l'ancien système
- 📊 Flexibilité pour l'avenir

Qu'en penses-tu ? Des modifications à apporter ? 🤔
