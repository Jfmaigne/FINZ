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
    
    // SwiftData ModelContainer
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
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Seed categories on app launch
            let context = ModelContext(container)
            try? DataController.seedCategories(in: context)
            
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
        }
    }
}

