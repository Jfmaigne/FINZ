# ✅ Checklist Migration SwiftData - FINZ

## 🎯 Migration Terminée - Actions Requises

### ✅ ÉTAPE 1 : Vérification (OBLIGATOIRE)
- [ ] Ouvrir le projet dans Xcode
- [ ] Product > Clean Build Folder (Cmd+Shift+K)
- [ ] Build (Cmd+B)
- [ ] Vérifier qu'il n'y a **aucune erreur de compilation**

### ✅ ÉTAPE 2 : Tests Fonctionnels (OBLIGATOIRE)
- [ ] **Lancer l'app sur simulateur**
  - [ ] L'app démarre sans crash
  - [ ] Splash screen s'affiche
  - [ ] Écran d'authentification fonctionne

- [ ] **Tester l'authentification**
  - [ ] Se connecter avec Email
  - [ ] Arriver sur le dashboard

- [ ] **Tester la création de revenus**
  - [ ] Onglet Budget > + > Revenu
  - [ ] Saisir un montant et une catégorie
  - [ ] Vérifier que ça s'enregistre

- [ ] **Tester la création de dépenses**
  - [ ] Onglet Budget > + > Dépense
  - [ ] Saisir un montant et une catégorie
  - [ ] Vérifier que ça s'enregistre

- [ ] **Tester le dashboard**
  - [ ] Le solde actuel s'affiche
  - [ ] Les jours restants s'affichent
  - [ ] Le prévisionnel se calcule
  - [ ] Les flèches ← → fonctionnent

- [ ] **Tester les recettes/dépenses fixes**
  - [ ] Compte > Modifier les recettes fixes
  - [ ] Compte > Modifier les dépenses fixes
  - [ ] Les données s'affichent et se modifient

- [ ] **Tester l'export/import**
  - [ ] Compte > Exporter les données
  - [ ] Fichier JSON créé
  - [ ] Compte > Importer des données
  - [ ] Données importées correctement

- [ ] **Tester la réinitialisation**
  - [ ] Compte > Réinitialiser les données
  - [ ] Confirmation demandée
  - [ ] Données supprimées
  - [ ] Questionnaire relancé

### ✅ ÉTAPE 3 : Nettoyage (RECOMMANDÉ)

Si tous les tests passent :

- [ ] **Exécuter le script de nettoyage**
  ```bash
  cd /Users/jfmaigne/Desktop/FINZ
  ./cleanup_coredata.sh
  ```

- [ ] **Ou supprimer manuellement :**
  - [ ] `FINZ/Data/FINZDataModel.xcdatamodeld/`
  - [ ] `FINZ/Core/BudgetProjectionManagerCoreData.swift.bak`
  - [ ] Autres fichiers Core Data obsolètes

- [ ] **Clean Build à nouveau**
  - [ ] Product > Clean Build Folder
  - [ ] Build
  - [ ] Vérifier aucune erreur

### ✅ ÉTAPE 4 : Validation Finale

- [ ] **Tester sur device réel** (iPhone/iPad)
- [ ] **Vérifier les performances**
  - [ ] Chargement rapide
  - [ ] Pas de ralentissement
  - [ ] Pas de crash

- [ ] **Vérifier la mémoire**
  - [ ] Instruments > Allocations
  - [ ] Pas de fuite mémoire

### ✅ ÉTAPE 5 : Documentation

- [ ] **Lire les guides créés**
  - [ ] `MIGRATION_COMPLETE_SWIFTDATA.md`
  - [ ] `MIGRATION_SWIFTDATA_GUIDE.md`
  - [ ] `AUTH_SETUP_GUIDE.md`

- [ ] **Noter les bugs éventuels**
  - Créer un fichier `BUGS_SWIFTDATA.md` si nécessaire

### ✅ ÉTAPE 6 : Déploiement (OPTIONNEL)

Si tout fonctionne parfaitement :

- [ ] **Mettre à jour le numéro de version**
  - Version: 2.0.0 (migration majeure)
  - Build: +1

- [ ] **Créer un commit Git**
  ```bash
  git add .
  git commit -m "feat: Migration complète Core Data → SwiftData

  - Remplacement de tous les NSFetchRequest par FetchDescriptor
  - Migration de 18 fichiers vers SwiftData
  - Suppression de 500+ lignes de boilerplate
  - Export/Import JSON fonctionnel
  - Performances identiques
  - Tests validés
  
  BREAKING CHANGE: Nécessite iOS 17+"
  ```

- [ ] **Créer un tag**
  ```bash
  git tag -a v2.0.0 -m "Migration SwiftData complète"
  git push origin v2.0.0
  ```

- [ ] **Tester le build de release**
  - Product > Archive
  - Vérifier que l'archive se crée

---

## 🐛 En Cas de Problème

### Si l'app ne démarre pas
1. Vérifier le Deployment Target ≥ iOS 17.0
2. Clean Build Folder
3. Supprimer l'app du simulateur
4. Rebuild

### Si les données ne s'affichent pas
1. Vérifier que `Models.swift` est dans le target
2. Vérifier `DataController.swift`
3. Vérifier les Preview providers

### Si des erreurs de compilation
1. Lire le message d'erreur complet
2. Vérifier les imports (SwiftData pas CoreData)
3. Vérifier les @Environment (modelContext pas managedObjectContext)

### Si les performances sont dégradées
1. Ajouter des index : `@Attribute(.indexed)`
2. Optimiser les FetchDescriptor
3. Utiliser des limites de fetch

---

## 📞 Support

### Fichiers de Référence
- `/Users/jfmaigne/Desktop/FINZ/MIGRATION_COMPLETE_SWIFTDATA.md`
- `/Users/jfmaigne/Desktop/FINZ/MIGRATION_SWIFTDATA_GUIDE.md`
- `/Users/jfmaigne/Desktop/FINZ/cleanup_coredata.sh`

### Ressources Externes
- [Documentation SwiftData](https://developer.apple.com/documentation/swiftdata)
- [WWDC 2023 - Meet SwiftData](https://developer.apple.com/videos/play/wwdc2023/10187/)

---

## ✅ Validation Finale

Une fois TOUS les tests passés :

- [ ] ✅ L'app compile sans erreur
- [ ] ✅ L'app démarre sans crash
- [ ] ✅ Toutes les fonctionnalités marchent
- [ ] ✅ Les performances sont bonnes
- [ ] ✅ Aucun bug détecté
- [ ] ✅ Les fichiers obsolètes sont supprimés
- [ ] ✅ Le code est clean

**🎉 MIGRATION SWIFTDATA VALIDÉE !**

---

*Checklist créée le 27 février 2026*  
*FINZ App - SwiftData Migration*
