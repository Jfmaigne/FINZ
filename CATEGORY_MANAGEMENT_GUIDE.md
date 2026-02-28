# 📁 Guide d'Utilisation - Gestion des Catégories

## Accès au Menu

1. Ouvre l'app FINZ
2. Va dans l'onglet **Budget**
3. Accède au menu **Compte** (en bas à droite)
4. Clique sur **"Gérer les catégories"** (avec l'icône 🏷️)

---

## Interface Principale

### Vue d'ensemble

```
┌─────────────────────────────────┐
│  Gestion des Catégories         │
├─────────────────────────────────┤
│ [Dépenses | Revenus] (Picker)   │
├─────────────────────────────────┤
│ 🏠 Logement                     │
│   ├─ 🚪 Loyer + charges        │
│   ├─ 🏦 Crédit habitation       │
│   └─ [+ Ajouter sous-cat.]      │
│                                 │
│ 🚗 Transport                    │
│   ├─ 🚗 Crédit auto/LOA/LLD     │
│   ├─ ⛽ Carburant               │
│   └─ [+ Ajouter sous-cat.]      │
│                                 │
│ [+ Ajouter catégorie] (top right)│
└─────────────────────────────────┘
```

---

## Opérations Disponibles

### 1️⃣ **Basculer entre Dépenses et Revenus**

- Utilise le **Picker en haut** pour choisir :
  - **Dépenses** : Voir les catégories de dépenses
  - **Revenus** : Voir les catégories de revenus
- La liste se met à jour automatiquement

---

### 2️⃣ **Ajouter une Catégorie Principale**

**Bouton** : `+` en haut à droite

**Formulaire:**
```
┌─────────────────────────────────┐
│ Nouvelle Catégorie              │
├─────────────────────────────────┤
│ Nom affiché:  [Alimentation   ] │
│ Code interne: [food            ] │
│                                 │
│ Icône:        [🛒 (dropdown)   ] │
│ Couleur:      [Jaune (dropdown)] │
│                                 │
│ Prévisualisation:               │
│ 🛒 Alimentation (food)          │
│                  [Jaune]        │
├─────────────────────────────────┤
│  [Annuler]           [Ajouter] │
└─────────────────────────────────┘
```

**À remplir :**
- **Nom affiché** : Texte visible à l'utilisateur (ex: "Logement")
- **Code interne** : Identifiant technique unique (ex: "housing", sans espaces)
- **Icône** : Emoji pour la catégorie
- **Couleur** : Code couleur HEX parmi les prédéfinis

**Validation :**
- ✅ Le code interne doit être unique
- ✅ Les deux champs doivent être remplis
- ✅ Pas de doublons autorisés

---

### 3️⃣ **Ajouter une Sous-Catégorie**

**Bouton** : `[+ Ajouter une sous-catégorie]` sous chaque catégorie principale

**Formulaire :**
```
┌─────────────────────────────────┐
│ Nouvelle Sous-Catégorie         │
├─────────────────────────────────┤
│ Catégorie Parente:              │
│ 🏠 Logement (housing)           │
│                                 │
│ Nom affiché:  [Électricité    ] │
│ Code interne: [electricity     ] │
│                                 │
│ Icône:        [💡 (dropdown)   ] │
│                                 │
│ Prévisualisation:               │
│ 💡 Électricité (electricity)    │
├─────────────────────────────────┤
│  [Annuler]           [Ajouter] │
└─────────────────────────────────┘
```

**À remplir :**
- **Nom affiché** : Nom de la sous-catégorie
- **Code interne** : Identifiant unique dans sa catégorie
- **Icône** : Emoji pour la sous-catégorie

**Validation :**
- ✅ Le code interne doit être unique dans sa catégorie
- ✅ Les deux champs doivent être remplis

---

### 4️⃣ **Supprimer une Catégorie**

**Sous-catégorie :**
1. Glisse vers la gauche sur la sous-catégorie
2. Clique sur 🗑️ **Supprimer**

**Catégorie Principale :**
1. Scroll vers le bas de la section
2. Clique sur 🗑️ **Supprimer cette catégorie**

**⚠️ Restrictions :**
- ❌ Impossible de supprimer une catégorie **utilisée** par des dépenses/revenus
- ❌ Message d'erreur : "Impossible de supprimer. Utilisée par X élément(s)"
- ✅ Tu dois d'abord réassigner les éléments à une autre catégorie

---

## Exemples Pratiques

### ✅ Ajouter une nouvelle catégorie de dépense

**Objectif** : Créer une catégorie "Animaux de compagnie"

1. Ouvre **Gérer les catégories**
2. Sélectionne **Dépenses**
3. Clique sur `+` en haut à droite
4. Remplis :
   - Nom affiché : `Animaux de compagnie`
   - Code interne : `pets`
   - Icône : `🐕` ou `🐈`
   - Couleur : Rose ou Turquoise
5. Clique **Ajouter**

### ✅ Ajouter une sous-catégorie

**Objectif** : Ajouter "Vétérinaire" sous "Animaux"

1. Sous la catégorie "Animaux de compagnie"
2. Clique `[+ Ajouter une sous-catégorie]`
3. Remplis :
   - Nom affiché : `Vétérinaire`
   - Code interne : `veterinary`
   - Icône : `⚕️` ou `🩺`
4. Clique **Ajouter**

### ❌ Essayer de supprimer une catégorie utilisée

**Scénario** : Tu veux supprimer "Logement" mais tu as déjà 5 loyers enregistrés

1. Clique sur 🗑️ **Supprimer cette catégorie**
2. ❌ Erreur : "Impossible de supprimer. Utilisée par 5 élément(s)"
3. Pour supprimer, tu dois d'abord :
   - Modifier les 5 loyers pour utiliser une autre catégorie
   - OU supprimer les 5 loyers
   - PUIS supprimer la catégorie

---

## Conseils

### 🎯 Bonnes Pratiques

1. **Code interne** : Utilise des codes simples, en minuscules, sans accents
   - ✅ Bon : `food`, `electricity`, `vacation`
   - ❌ Mauvais : `Food`, `électricité`, `vacances été`

2. **Icône** : Choisis une icône pertinente et distinctive
   - Elle aide à identifier rapidement la catégorie

3. **Couleur** : Utilise des couleurs contrastées pour distinguer les catégories
   - Limite les doublons visuels

4. **Sous-catégories** : Ne crée qu'autant que nécessaire
   - Évite l'inflation de sous-catégories
   - Regroupe les éléments similaires

5. **Ordre** : Les catégories sont ordonnées automatiquement
   - Première créée = première affichée

---

## Limitations & Comportement

| Action | Autorisé | Note |
|--------|----------|------|
| Ajouter catégorie | ✅ | Automatiquement ordonnée |
| Supprimer catégorie vide | ✅ | Pas de dépenses/revenus dedans |
| Supprimer catégorie utilisée | ❌ | Message d'erreur |
| Modifier une catégorie | ❌ | Crée une nouvelle à la place |
| Réordonner catégories | ❌ | Ordre automatique (à venir) |
| Fusionner catégories | ❌ | À faire manuellement (à venir) |

---

## FAQ

**Q: Puis-je renommer une catégorie ?**  
A: Actuellement non. Tu dois la supprimer et la recréer avec le bon nom.

**Q: Combien de catégories puis-je créer ?**  
A: Illimité ! Mais garde-les organisées pour rester clair.

**Q: Que se passe-t-il si j'ajoute une catégorie en doublon ?**  
A: ❌ Erreur : "Un code interne avec ce nom existe déjà"

**Q: Comment migrer les anciennes dépenses vers les nouvelles catégories ?**  
A: Actuellement manuel (à faire via l'UI plus tard). Les anciennes restent sans catégorie.

**Q: Peux-tu supprimer les catégories par défaut ?**  
A: Oui, si aucune dépense/revenu ne les utilise.

---

## Prochaines Améliorations Prévues

- [ ] Modifier une catégorie existante (au lieu de recréer)
- [ ] Réordonner les catégories par drag & drop
- [ ] Fusion de catégories
- [ ] Migration automatique des anciennes catégories
- [ ] Exporter/importer les catégories
- [ ] Templates de catégories prédéfinies

---

*Guide d'utilisation - Gestion des Catégories*  
*FINZ v2.0+ - SwiftData*
