//
//  AuthApp.swift
//  Auth
//
//  Created by MAIGNE JEAN-FRANCOIS on 01/02/2026.
//

import SwiftUI
import UIKit
import SwiftData

@main
struct AuthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sessionManager = SessionManager()
    
    // SwiftData ModelContainer avec CloudKit
    let modelContainer: ModelContainer = {
        let schema = Schema([
            BudgetEntryOccurrence.self,
            Income.self,
            Expense.self,
            MainCategory.self,
            SubCategory.self,
            DeferredCard.self,
            DeferredCardExpense.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            try? DataController.seedCategories(in: context)
            print("☁️ ModelContainer CloudKit créé avec succès")
            return container
        } catch {
            print("⚠️ CloudKit échoué: \(error). Fallback local...")
        }
        
        // Fallback local si CloudKit échoue
        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [localConfig])
            let context = ModelContext(container)
            try? DataController.seedCategories(in: context)
            print("📱 ModelContainer local créé")
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionManager)
                .modelContainer(modelContainer)
                .task {
                    // Rafraîchir les articles en tâche de fond au lancement
                    ArticleCacheService.shared.refreshAllArticles()
                    // Pré-charger le tracker d'articles pour le badge icône
                    ArticleReadTracker.shared.preloadAllAssets()
                }
        }
    }
}

