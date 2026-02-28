# 📋 Configuration Par Défaut des Catégories

## Vue d'Ensemble

La gestion des catégories inclut maintenant une **configuration par défaut** qui s'applique automatiquement à la première utilisation et peut être réinitialisée à tout moment.

---

## 💰 **DÉPENSES - 8 Catégories Principales**

### 1. 🏠 **Logement** (#FF6B6B)
Le poste de dépense le plus important !
- 🚪 Loyer + charges
- 💡 Électricité
- 🔥 Gaz
- 💧 Eau
- 🛡️ Assurance habitation

### 2. 🚗 **Transport** (#4ECDC4)
Mobilité et déplacements
- ⛽ Carburant
- 🛡️ Assurance auto
- 🔧 Entretien/réparation
- 🚌 Transports en commun

### 3. 🛒 **Alimentation** (#FFE66D)
Nourriture et restauration
- 🛍️ Courses
- 🍽️ Restaurant/Café
- 🍔 Livraison de repas

### 4. 📱 **Abonnements** (#95E1D3)
Services réguliers
- 📡 Internet/Téléphone
- 📺 Streaming (Netflix, etc)
- 💪 Gym/Sport
- 📦 Autres abonnements

### 5. 🎉 **Loisirs** (#FFB3BA)
Divertissement et culture
- 🎬 Cinéma/Théâtre
- ✈️ Vacances/Voyage
- 🎨 Hobbies/Loisirs

### 6. ⚕️ **Santé** (#A8E6CF)
Bien-être médical
- 👨‍⚕️ Médecin/Consultation
- 💊 Pharmacie
- 🦷 Dentiste

### 7. 👕 **Vêtements** (#C7B3E5)
Mode et accessoires
- 👔 Vêtements
- 👞 Chaussures
- 👜 Accessoires

### 8. 📚 **Éducation** (#FFDAB9)
Formation et apprentissage
- 🎓 Cours/Formation
- 📖 Livres
- 🏫 Frais scolaires

---

## 💵 **REVENUS - 4 Catégories Principales**

### 1. 💼 **Revenus Principaux** (#4ECDC4)
Les sources principales de revenus
- 💰 Salaire
- 👨‍💼 Auto-entrepreneur

### 2. 💵 **Revenus Complémentaires** (#FFE66D)
Revenus supplémentaires
- 💻 Freelance
- 🎁 Bonus/Primes
- 🏠 Location

### 3. 🤝 **Aides & Allocations** (#FFB3BA)
Aide de l'État
- 📋 Allocation chômage
- 👨‍👩‍👧‍👦 Allocations familiales
- 🏠 Allocation logement

### 4. 🎊 **Revenus Exceptionnels** (#A8E6CF)
Revenus non réguliers
- 🎁 Cadeaux/Dons
- 💎 Héritage
- 💸 Remboursement impôts

---

## ⚙️ **Fonctionnalités**

### Activation Automatique
✅ Les catégories par défaut s'appliquent automatiquement au premier lancement de l'app

### Réinitialisation
Les utilisateurs peuvent à tout moment restaurer la configuration par défaut :

**Procédure :**
1. Ouvre **Gestion des Catégories**
2. Clique sur le menu `⋯` (3 points) en haut à droite
3. Sélectionne **"Réinitialiser par défaut"**
4. Confirme dans l'alerte
5. Les catégories existantes sont supprimées
6. La configuration par défaut est restaurée

### Protection des Données
⚠️ **Important** : Seules les catégories **vides** (sans dépenses/revenus) sont supprimées lors de la réinitialisation. Les catégories avec données ne peuvent pas être supprimées automatiquement.

---

## 📊 **Statistiques de la Configuration**

| Type | Catégories | Sous-catégories | Total |
|------|-----------|-----------------|-------|
| **Dépenses** | 8 | 24 | 32 |
| **Revenus** | 4 | 11 | 15 |
| **TOTAL** | **12** | **35** | **47** |

---

## 🎯 **Design des Couleurs**

### Dépenses
- 🔴 Rouge (#FF6B6B) - Logement (crucial)
- 🔵 Turquoise (#4ECDC4) - Transport
- 🟡 Jaune (#FFE66D) - Alimentation
- 🟢 Vert menthe (#95E1D3) - Abonnements
- 🌸 Rose (#FFB3BA) - Loisirs
- 🟢 Vert (#A8E6CF) - Santé
- 🟣 Violet (#C7B3E5) - Vêtements
- 🟠 Pêche (#FFDAB9) - Éducation

### Revenus
- 🔵 Turquoise (#4ECDC4) - Revenus principaux
- 🟡 Jaune (#FFE66D) - Revenus complémentaires
- 🌸 Rose (#FFB3BA) - Aides & Allocations
- 🟢 Vert (#A8E6CF) - Revenus exceptionnels

---

## 🔄 **Scénarios d'Utilisation**

### ✅ Nouvel Utilisateur
1. Lance l'app
2. Les catégories par défaut sont automatiquement créées
3. Commence à enregistrer dépenses et revenus

### ✅ Réinitialisation Après Personnalisation
1. L'utilisateur a ajouté/supprimé des catégories
2. Accède à "Réinitialiser par défaut"
3. Les catégories sans données sont supprimées
4. Les catégories par défaut sont restaurées
5. Les catégories avec données restent intactes

### ❌ Impossible de Réinitialiser Complètement
**Situation :** L'utilisateur a lié des dépenses/revenus à des catégories
- Catégories avec données : **Conservées**
- Catégories vides : **Supprimées et restaurées**
- Requête : **Modifier manuellement les liens de données** puis réessayer

---

## 🛠️ **Implémentation Technique**

### Fichier Principal
`DefaultCategoryConfiguration.swift`

### Classes
- `DefaultCategoryConfiguration` - Configuration par défaut
- `CategorySeeder` - Initialisation des catégories
- `CategoryManagementView` - Interface de gestion

### Flux
```
App Launch
    ↓
DataController
    ↓
CategorySeeder.seedCategories()
    ↓
DefaultCategoryConfiguration
    ↓
✅ Catégories créées
```

---

## 📝 **Notes Importantes**

1. **Unicité** : Chaque catégorie/sous-catégorie a un code interne unique
2. **Couleurs** : Les couleurs sont fixes pour la cohérence visuelle
3. **Icônes** : Les emojis sont optimisés pour la reconnaissance visuelle
4. **Ordre** : Les catégories sont ordonnées par importance
5. **Flexibilité** : Les utilisateurs peuvent ajouter/supprimer/réinitialiser

---

## 🚀 **Prochaines Améliorations**

- [ ] Importer des templates de catégories externes
- [ ] Exporter/importer la configuration
- [ ] Profils de catégories (étudiant, freelance, famille, etc)
- [ ] Historique des modifications
- [ ] Fusionner catégories

---

*Configuration Par Défaut - FINZ v2.0+*  
*SwiftData - 27 Février 2026*
