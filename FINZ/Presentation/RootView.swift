import SwiftUI
import CoreData

struct RootView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showSplash: Bool = true
    @StateObject private var authService = AuthenticationService()
    @StateObject private var questionnaireVM = QuestionnaireViewModel()
    @State private var hasIncomeData: Bool? = nil
    @State private var forceProfileCreation: Bool = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashGradientView()
                    .transition(.opacity)
                    .onAppear {
                        // Hide splash after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showSplash = false
                                Task { await determineInitialRoute() }
                            }
                        }
                    }
            } else {
                Group {
                    // Si l'utilisateur n'est pas authentifié, afficher l'écran d'authentification
                    if !authService.isAuthenticated {
                        AuthenticationView(authService: authService)
                    } else if forceProfileCreation {
                        NavigationStack {
                            LifeView()
                                .environmentObject(questionnaireVM)
                        }
                    } else if let hasIncomeData {
                        if hasIncomeData {
                            // If income rows exist, go straight to the budget dashboard
                            BudgetTabView()
                                .environmentObject(questionnaireVM)
                                .environmentObject(authService)
                        } else {
                            // Otherwise continue with the existing flow
                            FinanceProfilView()
                                .environmentObject(questionnaireVM)
                                .environmentObject(authService)
                        }
                    } else {
                        // While determining, show a lightweight placeholder
                        ProgressView().task {
                            await determineInitialRoute()
                        }
                    }
                }
                .transition(.opacity)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ProfileEditCompleted"))) { _ in
                    forceProfileCreation = false
                    Task { await determineInitialRoute() }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDidAuthenticate"))) { _ in
                    // Quand l'utilisateur s'authentifie, relancer la détermination de route
                    Task { await determineInitialRoute() }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDidSignOut"))) { _ in
                    // Quand l'utilisateur se déconnecte, réinitialiser l'authentification
                    authService.signOut()
                    showSplash = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didResetAllData)) { _ in
            print("RootView: didResetAllData reçu → lancement LifeView")
            forceProfileCreation = true
            hasIncomeData = false
            showSplash = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToProfile)) { _ in
            print("RootView: switchToProfile reçu → lancement LifeView")
            forceProfileCreation = true
            hasIncomeData = false
            showSplash = false
        }
    }

    private func determineInitialRoute() async {
        // If already decided, skip
        if hasIncomeData != nil { return }
        if forceProfileCreation {
            await MainActor.run { self.hasIncomeData = false }
            return
        }
        let context = viewContext
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "Income")
        fetch.fetchLimit = 1
        do {
            let result = try context.fetch(fetch)
            await MainActor.run {
                self.hasIncomeData = !result.isEmpty
            }
        } catch {
            // On error, default to questionnaire/auth flow
            await MainActor.run {
                self.hasIncomeData = false
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(SessionManager())
}

