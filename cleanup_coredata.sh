#!/bin/bash

# Script de nettoyage post-migration SwiftData
# À exécuter APRÈS avoir testé que tout fonctionne !

echo "🧹 Nettoyage des fichiers Core Data obsolètes..."
echo ""

# Répertoire du projet
PROJECT_DIR="/Users/jfmaigne/Desktop/FINZ"

cd "$PROJECT_DIR" || exit 1

echo "⚠️  ATTENTION: Ce script va supprimer les fichiers Core Data obsolètes."
echo "Assurez-vous d'avoir:"
echo "  1. Testé l'app avec SwiftData"
echo "  2. Exporté vos données si nécessaire"
echo "  3. Fait un backup du projet"
echo ""
read -p "Continuer? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Annulé par l'utilisateur"
    exit 1
fi

echo ""
echo "🗑️  Suppression des fichiers Core Data..."

# Supprimer le modèle Core Data
if [ -d "FINZ/Data/FINZDataModel.xcdatamodeld" ]; then
    rm -rf "FINZ/Data/FINZDataModel.xcdatamodeld"
    echo "✅ Supprimé: FINZDataModel.xcdatamodeld"
else
    echo "⏭️  FINZDataModel.xcdatamodeld n'existe pas"
fi

# Supprimer l'ancien BudgetProjectionManager (backup)
if [ -f "FINZ/Core/BudgetProjectionManagerCoreData.swift.bak" ]; then
    rm "FINZ/Core/BudgetProjectionManagerCoreData.swift.bak"
    echo "✅ Supprimé: BudgetProjectionManagerCoreData.swift.bak"
else
    echo "⏭️  BudgetProjectionManagerCoreData.swift.bak n'existe pas"
fi

# Supprimer PersistenceController si existe
if [ -f "FINZ/Presentation/Persistence.swift" ]; then
    rm "FINZ/Presentation/Persistence.swift"
    echo "✅ Supprimé: Persistence.swift"
else
    echo "⏭️  Persistence.swift n'existe pas"
fi

# Supprimer PersistenceController du projet Xcode si existe
if [ -f "FINZ.xcodeproj/PersistenceController.swift" ]; then
    rm "FINZ.xcodeproj/PersistenceController.swift"
    echo "✅ Supprimé: PersistenceController.swift"
else
    echo "⏭️  PersistenceController.swift n'existe pas"
fi

# Supprimer l'ancienne version de RecettesFixesSheet (Core Data)
if [ -f "FINZ/Presentation/RecettesFixesSheet.swift" ]; then
    # Vérifier si c'est bien la version Core Data
    if grep -q "import CoreData" "FINZ/Presentation/RecettesFixesSheet.swift"; then
        rm "FINZ/Presentation/RecettesFixesSheet.swift"
        echo "✅ Supprimé: RecettesFixesSheet.swift (version Core Data)"
    else
        echo "⏭️  RecettesFixesSheet.swift existe mais n'est pas en Core Data"
    fi
else
    echo "⏭️  RecettesFixesSheet.swift n'existe pas"
fi

echo ""
echo "🔍 Recherche d'autres références à Core Data..."

# Chercher les imports CoreData restants
COREDATA_IMPORTS=$(find FINZ -name "*.swift" -type f -exec grep -l "import CoreData" {} \; 2>/dev/null | grep -v ".build")

if [ -n "$COREDATA_IMPORTS" ]; then
    echo "⚠️  Fichiers avec 'import CoreData' trouvés:"
    echo "$COREDATA_IMPORTS"
    echo ""
    echo "Vérifiez ces fichiers manuellement."
else
    echo "✅ Aucun 'import CoreData' trouvé!"
fi

echo ""
echo "🔍 Recherche de NSFetchRequest restants..."

# Chercher les NSFetchRequest restants
NSFETCHREQUEST=$(find FINZ -name "*.swift" -type f -exec grep -l "NSFetchRequest" {} \; 2>/dev/null | grep -v ".build")

if [ -n "$NSFETCHREQUEST" ]; then
    echo "⚠️  Fichiers avec 'NSFetchRequest' trouvés:"
    echo "$NSFETCHREQUEST"
    echo ""
    echo "Vérifiez ces fichiers manuellement."
else
    echo "✅ Aucun 'NSFetchRequest' trouvé!"
fi

echo ""
echo "🧹 Nettoyage du cache de build Xcode..."
echo "   (Vous devriez aussi faire: Product > Clean Build Folder dans Xcode)"

# Nettoyage des DerivedData (optionnel, décommenté si souhaité)
# rm -rf ~/Library/Developer/Xcode/DerivedData/FINZ-*
# echo "✅ Cache Xcode nettoyé"

echo ""
echo "✅ Nettoyage terminé!"
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Ouvrir le projet dans Xcode"
echo "   2. Product > Clean Build Folder (Cmd+Shift+K)"
echo "   3. Build (Cmd+B)"
echo "   4. Tester l'app sur simulateur"
echo "   5. Vérifier toutes les fonctionnalités"
echo ""
echo "🎉 Migration SwiftData complète!"
