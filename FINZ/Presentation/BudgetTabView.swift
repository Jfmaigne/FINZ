import SwiftUI
import UIKit
import Foundation
import SwiftData
import Combine
import UniformTypeIdentifiers

extension Notification.Name {
    static let didResetAllData = Notification.Name("didResetAllData")
    static let switchToProfile = Notification.Name("switchToProfile")
}

private func justified(_ string: String) -> AttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .justified
    let nsAttr = NSAttributedString(
        string: string,
        attributes: [
            .paragraphStyle: paragraphStyle
        ]
    )
    return AttributedString(nsAttr)
}

struct BudgetTabView: View {
    @State private var selectedTab: Tab = .budget
    @EnvironmentObject var vm: QuestionnaireViewModel
    @Environment(\.modelContext) var modelContext

    enum Tab: Hashable {
        case budget, stats, learn, lexicon, account

        var title: String {
            switch self {
            case .budget: return "Budget"
            case .stats: return "Stats"
            case .learn: return "Apprendre"
            case .lexicon: return "Lexique"
            case .account: return "Compte"
            }
        }

        var systemImage: String {
            switch self {
            case .budget: return "chart.pie.fill"
            case .stats: return "chart.bar.fill"
            case .learn: return "book.fill"
            case .lexicon: return "text.book.closed.fill"
            case .account: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            BudgetDashboardView()
                .tabItem {
                    Label(Tab.budget.title, systemImage: Tab.budget.systemImage)
                }
                .tag(Tab.budget)

            NavigationStack {
                StatisticsView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label(Tab.stats.title, systemImage: Tab.stats.systemImage)
            }
            .tag(Tab.stats)

            NavigationStack {
                LearnView()
                    .finzHeader(title: "Envie d'apprendre ?")
            }
            .tabItem {
                Label(Tab.learn.title, systemImage: Tab.learn.systemImage)
            }
            .tag(Tab.learn)

            // LexiconView is defined in LexiconModule.swift
            NavigationStack {
                LexiconView()
                    .finzHeader(title: "Lexique")
            }
            .tabItem {
                Label(Tab.lexicon.title, systemImage: Tab.lexicon.systemImage)
            }
            .tag(Tab.lexicon)

            AccountView()
                .tabItem {
                    Label(Tab.account.title, systemImage: Tab.account.systemImage)
                }
                .tag(Tab.account)
        }
    }
}

struct BudgetProfileSetupView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                Text("Création du profil de budget")
                    .font(.title2).bold()
                Text("Configure ton profil pour une projection plus précise.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .finzHeader()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LearnView: View {
    @State private var carouselIndex: Int = 0
    @State private var timerSubscription: AnyCancellable?
    @Environment(\.scenePhase) private var scenePhase

    // Carousel items (banners)
    private let banners: [CarouselItem] = [
        .init(category: "Catégorie Investissement", title: "PAR OU COMMENCER", subtitle: "Pour investir", gradient: [Color(red: 0.08, green: 0.22, blue: 0.78), Color(red: 0.74, green: 0.24, blue: 0.96)]),
        .init(category: "Catégorie Budget", title: "GÉRER SES DÉPENSES", subtitle: "1ère étape", gradient: [Color(red: 0.04, green: 0.50, blue: 0.73), Color(red: 0.35, green: 0.74, blue: 0.94)]),
        .init(category: "Catégorie Logement", title: "COMPRENDRE SON LOYER", subtitle: "Locataire / Propriétaire", gradient: [Color(red: 0.94, green: 0.43, blue: 0.31), Color(red: 0.98, green: 0.68, blue: 0.36)])
    ]

    // 9 themed buttons grouped by sections
    private let sections: [(title: String, items: [LearnItem])] = [
        ("Je débute", [
            LearnItem(title: "Les bases", imageName: "Bases", asset: "articles_budget_gestion_genz"),
            LearnItem(title: "Budget", imageName: "Budget", asset: "articles_budget_gestion_genz"),
            LearnItem(title: "Epargne", imageName: "Epargne", asset: "articles_budget_gestion_genz")
        ]),
        ("Je sécurise", [
            LearnItem(title: "Projets", imageName: "Projets", asset: "articles_logement_genz"),
            LearnItem(title: "Assurances", imageName: "Assurances", asset: "articles_logement_genz"),
            LearnItem(title: "Astuces", imageName: "Astuces", asset: "articles_budget_gestion_genz")
        ]),
        ("Je développe", [
            LearnItem(title: "Crédit", imageName: "Crédit", asset: "articles_budget_gestion_genz"),
            LearnItem(title: "Investissement", imageName: "Investissement", asset: "articles_investissement_genz"),
            LearnItem(title: "Bourse", imageName: "Bourse", asset: "articles_investissement_genz")
        ])
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                // En-tête "Les articles populaires" uniquement (le gros titre est désormais dans finzHeader)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Les articles populaires")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

                // Carrousel
                TabView(selection: $carouselIndex) {
                    ForEach(banners.indices, id: \.self) { idx in
                        let item = banners[idx]
                        NavigationLink {
                            let asset = idx == 0 ? "articles_investissement_genz" : (idx == 1 ? "articles_budget_gestion_genz" : "articles_logement_genz")
                            ArticlesListView(assetName: asset, title: item.title)
                        } label: {
                            CarouselBannerView(item: item)
                                .padding(.horizontal)
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: 120)

                // Sections with 9 buttons (inchangées)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(sections, id: \.title) { section in
                        LearnSection(title: section.title, items: section.items)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.04),
                    Color.purple.opacity(0.04),
                    Color.pink.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            startCarouselTimer()
        }
        .onDisappear {
            stopCarouselTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                startCarouselTimer()
            } else {
                stopCarouselTimer()
            }
        }
    }
    
    private func startCarouselTimer() {
        // Cancel any existing timer first
        timerSubscription?.cancel()
        // Create new timer that fires every 4 seconds
        timerSubscription = Timer.publish(every: 4.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation { carouselIndex = (carouselIndex + 1) % max(banners.count, 1) }
            }
    }
    
    private func stopCarouselTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
}

// MARK: - Models
private struct CarouselItem: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let subtitle: String
    let gradient: [Color]
}

private struct LearnItem: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String?
    let asset: String
}

// MARK: - Subviews
private struct CarouselBannerView: View {
    let item: CarouselItem

    var body: some View {
        ZStack(alignment: .center) {
            LinearGradient(gradient: Gradient(colors: item.gradient), startPoint: .topLeading, endPoint: .bottomTrailing)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

            VStack(alignment: .center, spacing: 2) {
                Text(item.category)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                Text(item.title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(item.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(item.gradient.last ?? .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .rotationEffect(.degrees(-3))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, -2) // légèrement remonté et collé sous le titre
            }
            .padding(18)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct LearnSection: View {
    let title: String
    let items: [LearnItem]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline).bold()
                .foregroundColor(.secondary)
                .padding(.horizontal, 2)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    NavigationLink {
                        // Use CategoryArticlesView for items with dedicated JSON files
                        if item.title == "Les bases" {
                            CategoryArticlesView(assetName: "lesbases")
                        } else {
                            ArticlesListView(assetName: item.asset, title: item.title)
                        }
                    } label: {
                        LearnGridButton(title: item.title, imageName: item.imageName)
                    }
                }
            }
        }
    }
}

private struct LearnGridButton: View {
    let title: String
    let imageName: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

            VStack(spacing: 0) {
                if let name = imageName, let ui = UIImage(named: name) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(1.15)
                        .frame(width: 96, height: 96)
                        .clipped()
                        .offset(y: -5)
                } else {
                    Image(systemName: "book.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.purple)
                }
            }
        }
        .frame(height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// Remove or keep previous LearnRowView stub if needed for other parts; provide a lightweight fallback implementation
private struct LearnRowView: View {
    let title: String
    let subtitle: String
    let imageName: String?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.black)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.85))
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            if let name = imageName, let ui = UIImage(named: name) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.system(size: 16, weight: .semibold))
                .padding(.leading, 2)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.12)))
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct AccountView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var vm: QuestionnaireViewModel
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingResetAlert = false
    @State private var showingSuccessAlert = false
    @State private var isResetting = false
    @State private var resetError: String? = nil
    @State private var showingProfileConfirm = false
    @State private var firstName: String = AppSettings.firstName
    
    @State private var showingExportSheet = false
    @State private var exportURL: URL? = nil
    @State private var exportError: String? = nil
    @State private var showingImportPicker = false
    @State private var importError: String? = nil
    @State private var showingImportConfirm = false
    @State private var showingImportSuccess = false
    @State private var pendingImportURL: URL? = nil
    @State private var showingSignOutAlert = false
    @State private var showingCategoryManagement = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Paramètres")) {
                    TextField("Prénom", text: $firstName)
                        .textInputAutocapitalization(.words)
                        .onChange(of: firstName) { newValue in
                            AppSettings.firstName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                }
                Section(header: Text("Données")) {
                    if let resetError {
                        Text(resetError)
                            .foregroundStyle(.red)
                    }
                    NavigationLink {
                        RecettesView()
                            .environmentObject(vm)
                    } label: {
                        Label("Modifier les recettes fixes", systemImage: "arrow.up.circle")
                    }
                    NavigationLink {
                        ExpensesView()
                            .environmentObject(vm)
                    } label: {
                        Label("Modifier les dépenses fixes", systemImage: "arrow.down.circle")
                    }
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        Label("Gérer les catégories", systemImage: "tag.circle")
                    }
                    NavigationLink {
                        DeferredCardManagementView()
                    } label: {
                        Label("Cartes à débit différé", systemImage: "creditcard.circle")
                    }
                    Button {
                        showingProfileConfirm = true
                    } label: {
                        Label("Modifier le profil", systemImage: "person.crop.circle")
                    }
                    Button {
                        Task { await exportBackup() }
                    } label: {
                        Label("Exporter les données", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("Importer des données", systemImage: "square.and.arrow.down")
                    }
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            if isResetting { ProgressView().padding(.trailing, 6) }
                            Text("Réinitialiser les données")
                        }
                    }
                    .disabled(isResetting)
                }

                Section(header: Text("Authentification")) {
                    if let user = authService.user {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Connecté en tant que:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(user.fullName)
                                .font(.headline)
                            Text(user.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Button(role: .destructive) {
                        showingSignOutAlert = true
                    } label: {
                        Label("Se déconnecter", systemImage: "arrow.right.circle")
                    }
                }

                Section(header: Text("À propos")) {
                    Text("Compte")
                        .foregroundStyle(.secondary)
                }
            }
//            .navigationTitle("Compte")
            .navigationBarTitleDisplayMode(.inline)
            .finzHeader()
            .onAppear {
                firstName = AppSettings.firstName
            }
            .alert("Confirmer la déconnexion", isPresented: $showingSignOutAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Se déconnecter", role: .destructive) {
                    authService.signOut()
                    NotificationCenter.default.post(name: NSNotification.Name("UserDidSignOut"), object: nil)
                }
            } message: {
                Text("Vous serez redirigé vers l'écran de connexion.")
            }
            .alert("Confirmer la réinitialisation", isPresented: $showingResetAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) { resetAllData() }
            } message: {
                Text("Cette action va supprimer toutes les données des tables Income, Expense et BudgetEntryOccurrence. Cette action est irréversible.")
            }
            .alert("Données réinitialisées", isPresented: $showingSuccessAlert) {
                Button("OK") {}
            } message: {
                Text("Vos données ont été supprimées. Vous pouvez relancer le questionnaire.")
            }
            .alert("Modifier le profil", isPresented: $showingProfileConfirm) {
                Button("Annuler", role: .cancel) {}
                Button("Continuer") {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    NotificationCenter.default.post(name: .switchToProfile, object: nil)
                }
            } message: {
                Text("Tu vas être redirigé vers l’onglet Profil pour modifier ta configuration.")
            }
            .alert("Erreur export", isPresented: Binding<Bool>(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = exportError { Text(error) }
            }
            .alert("Importer ces données ?", isPresented: $showingImportConfirm) {
                Button("Annuler", role: .cancel) {
                    pendingImportURL = nil
                }
                Button("Importer") {
                    guard let url = pendingImportURL else { return }
                    Task { await importBackup(from: url) }
                }
            } message: {
                if let url = pendingImportURL {
                    Text(url.lastPathComponent)
                }
            }
            .alert("Import terminé", isPresented: $showingImportSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Les données ont été importées avec succès.")
            }
            .alert("Erreur import", isPresented: Binding<Bool>(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = importError { Text(error) }
            }
        }
        .sheet(isPresented: $showingExportSheet, onDismiss: {
            cleanupExportFile()
        }) {
            if let url = exportURL, FileManager.default.fileExists(atPath: url.path) {
                ActivityView(activityItems: [url])
            } else {
                Text("Erreur d'accès au fichier exporté.").onAppear {
                    showingExportSheet = false
                    exportError = "Le fichier export n'est plus disponible."
                }
            }
        }
        .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [UTType.json], onCompletion: { result in
            switch result {
            case .success(let url):
                pendingImportURL = url
                showingImportConfirm = true
            case .failure(let error):
                importError = "Impossible d'ouvrir le fichier : \(error.localizedDescription)"
            }
        })
    }

    private func resetAllData() {
        isResetting = true
        resetError = nil
        
        do {
            // Fetch and delete all Income entities
            let incomeFetch = FetchDescriptor<Income>()
            let incomes = try modelContext.fetch(incomeFetch)
            for income in incomes {
                modelContext.delete(income)
            }
            
            // Fetch and delete all Expense entities
            let expenseFetch = FetchDescriptor<Expense>()
            let expenses = try modelContext.fetch(expenseFetch)
            for expense in expenses {
                modelContext.delete(expense)
            }
            
            // Fetch and delete all BudgetEntryOccurrence entities
            let occurrenceFetch = FetchDescriptor<BudgetEntryOccurrence>()
            let occurrences = try modelContext.fetch(occurrenceFetch)
            for occurrence in occurrences {
                modelContext.delete(occurrence)
            }
            
            try modelContext.save()
            
            // Notify UI and switch to questionnaire tab
            NotificationCenter.default.post(name: .didResetAllData, object: nil)
            showingSuccessAlert = true
        } catch {
            resetError = "Échec de la réinitialisation: \(error.localizedDescription)"
        }
        isResetting = false
    }
    
    private func exportBackup() async {
        let iso = ISO8601DateFormatter()
        var payload: [String: Any] = [
            "version": 1,
            "exportedAt": iso.string(from: Date()),
            "profile": ["firstName": AppSettings.firstName],
            "entities": [:]
        ]

        do {
            var entitiesData: [String: [[String: Any]]] = [:]
            
            // Export Income
            let incomeFetch = FetchDescriptor<Income>()
            let incomes = try modelContext.fetch(incomeFetch)
            entitiesData["Income"] = incomes.map { income in
                [
                    "id": income.id.uuidString,
                    "amount": income.amount,
                    "complement": income.complement ?? "",
                    "day": income.day,
                    "kind": income.kind,
                    "months": income.months ?? "",
                    "periodicity": income.periodicity
                ]
            }
            
            // Export Expense
            let expenseFetch = FetchDescriptor<Expense>()
            let expenses = try modelContext.fetch(expenseFetch)
            entitiesData["Expense"] = expenses.map { expense in
                var dict: [String: Any] = [
                    "id": expense.id.uuidString,
                    "amount": expense.amount,
                    "day": expense.day,
                    "kind": expense.kind,
                    "periodicity": expense.periodicity
                ]
                if let complement = expense.complement { dict["complement"] = complement }
                if let endDate = expense.endDate { dict["endDate"] = iso.string(from: endDate) }
                if let months = expense.months { dict["months"] = months }
                if let note = expense.note { dict["note"] = note }
                if let provider = expense.provider { dict["provider"] = provider }
                return dict
            }
            
            // Export BudgetEntryOccurrence
            let occurrenceFetch = FetchDescriptor<BudgetEntryOccurrence>()
            let occurrences = try modelContext.fetch(occurrenceFetch)
            entitiesData["BudgetEntryOccurrence"] = occurrences.map { occ in
                var dict: [String: Any] = [
                    "id": occ.id.uuidString,
                    "date": iso.string(from: occ.date),
                    "amount": occ.amount,
                    "kind": occ.kind,
                    "monthKey": occ.monthKey,
                    "isManual": occ.isManual,
                    "createdAt": iso.string(from: occ.createdAt),
                    "updatedAt": iso.string(from: occ.updatedAt)
                ]
                if let title = occ.title { dict["title"] = title }
                if let sourceid = occ.sourceid { dict["sourceid"] = sourceid.uuidString }
                return dict
            }
            
            payload["entities"] = entitiesData

            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("finz_backup.json")
            try data.write(to: tmp, options: .atomic)

            await MainActor.run {
                exportURL = tmp
                showingExportSheet = true
            }
        } catch {
            await MainActor.run {
                exportError = "Erreur lors de l'export : \(error.localizedDescription)"
            }
        }
    }
    
    private func importBackup(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let entities = json["entities"] as? [String: Any]
            else {
                await MainActor.run { importError = "Fichier invalide" }
                return
            }
            if let profile = json["profile"] as? [String: Any], let first = profile["firstName"] as? String {
                AppSettings.firstName = first
                await MainActor.run { firstName = first }
            }

            let iso = ISO8601DateFormatter()

            // Purge existing data
            let incomeFetch = FetchDescriptor<Income>()
            let incomes = try modelContext.fetch(incomeFetch)
            for income in incomes {
                modelContext.delete(income)
            }
            
            let expenseFetch = FetchDescriptor<Expense>()
            let expenses = try modelContext.fetch(expenseFetch)
            for expense in expenses {
                modelContext.delete(expense)
            }
            
            let occurrenceFetch = FetchDescriptor<BudgetEntryOccurrence>()
            let occurrences = try modelContext.fetch(occurrenceFetch)
            for occurrence in occurrences {
                modelContext.delete(occurrence)
            }

            // Import Income
            if let incomeArray = entities["Income"] as? [[String: Any]] {
                for dict in incomeArray {
                    guard let idStr = dict["id"] as? String,
                          let id = UUID(uuidString: idStr),
                          let kind = dict["kind"] as? String,
                          let periodicity = dict["periodicity"] as? String else { continue }
                    
                    let income = Income(
                        id: id,
                        amount: dict["amount"] as? Double ?? 0,
                        complement: dict["complement"] as? String,
                        day: Int16(dict["day"] as? Int ?? 0),
                        kind: kind,
                        months: dict["months"] as? String,
                        periodicity: periodicity
                    )
                    modelContext.insert(income)
                }
            }
            
            // Import Expense
            if let expenseArray = entities["Expense"] as? [[String: Any]] {
                for dict in expenseArray {
                    guard let idStr = dict["id"] as? String,
                          let id = UUID(uuidString: idStr),
                          let kind = dict["kind"] as? String,
                          let periodicity = dict["periodicity"] as? String else { continue }
                    
                    var endDate: Date? = nil
                    if let endDateStr = dict["endDate"] as? String {
                        endDate = iso.date(from: endDateStr)
                    }
                    
                    let expense = Expense(
                        id: id,
                        amount: dict["amount"] as? Double ?? 0,
                        complement: dict["complement"] as? String,
                        day: Int16(dict["day"] as? Int ?? 0),
                        endDate: endDate,
                        kind: kind,
                        months: dict["months"] as? String,
                        note: dict["note"] as? String,
                        periodicity: periodicity,
                        provider: dict["provider"] as? String
                    )
                    modelContext.insert(expense)
                }
            }
            
            // Import BudgetEntryOccurrence
            if let occurrenceArray = entities["BudgetEntryOccurrence"] as? [[String: Any]] {
                for dict in occurrenceArray {
                    guard let idStr = dict["id"] as? String,
                          let id = UUID(uuidString: idStr),
                          let dateStr = dict["date"] as? String,
                          let date = iso.date(from: dateStr),
                          let kind = dict["kind"] as? String,
                          let monthKey = dict["monthKey"] as? String else { continue }
                    
                    var sourceid: UUID? = nil
                    if let sourceidStr = dict["sourceid"] as? String {
                        sourceid = UUID(uuidString: sourceidStr)
                    }
                    
                    let createdAt = (dict["createdAt"] as? String).flatMap { iso.date(from: $0) } ?? Date()
                    let updatedAt = (dict["updatedAt"] as? String).flatMap { iso.date(from: $0) } ?? Date()
                    
                    let occurrence = BudgetEntryOccurrence(
                        id: id,
                        date: date,
                        amount: dict["amount"] as? Double ?? 0,
                        kind: kind,
                        title: dict["title"] as? String,
                        monthKey: monthKey,
                        isManual: dict["isManual"] as? Bool ?? false,
                        sourceid: sourceid,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                    modelContext.insert(occurrence)
                }
            }

            try modelContext.save()
            
            await MainActor.run {
                pendingImportURL = nil
                showingImportConfirm = false
                showingImportSuccess = true
            }
        } catch {
            await MainActor.run {
                importError = "Erreur lors de l'import : \(error.localizedDescription)"
            }
        }
    }

    private func cleanupExportFile() {
        if let url = exportURL {
            try? FileManager.default.removeItem(at: url)
            exportURL = nil
        }
    }
}

struct LogementView: View {
    var body: some View {
        NavigationStack {
            LogementArticlesView()
                .navigationTitle("Logement")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ImpotsTVAView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Impôts & TVA")
                    .font(.largeTitle.bold())
                Text(justified("Contenu pédagogique sur les impôts et la TVA…"))
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Impôts & TVA")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InvestissementView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Investissement")
                    .font(.largeTitle.bold())
                Text(justified("Bases de l’investissement, risques, horizons…"))
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Investissement")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BudgetGestionView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Budget & gestion")
                    .font(.largeTitle.bold())
                Text(justified("Suivi, catégories, objectifs, bonnes pratiques…"))
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Budget & gestion")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    BudgetTabView()
}

import UIKit
import SwiftUI
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
