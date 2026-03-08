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

struct BudgetTabView: View {
    @State private var selectedTab: Tab = .budget
    @EnvironmentObject var vm: QuestionnaireViewModel
    @Environment(\.modelContext) var modelContext
    @ObservedObject private var readTracker = ArticleReadTracker.shared

    private var totalNewArticles: Int {
        let _ = readTracker.lastUpdate
        return readTracker.totalNewCount
    }

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
            .badge(totalNewArticles)

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
            .finzHeader(title: "Profil Budget")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LearnView: View {
    @State private var carouselIndex: Int = 0
    @State private var timerSubscription: AnyCancellable?
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var readTracker = ArticleReadTracker.shared

    // Articles aléatoires pour le carrousel (chargés au lancement)
    @State private var carouselArticles: [(article: BasesArticleData, category: String, asset: String)] = []

    // Gradients pour le carrousel (cyclés)
    private let gradients: [[Color]] = [
        [Color(red: 0.08, green: 0.22, blue: 0.78), Color(red: 0.74, green: 0.24, blue: 0.96)],
        [Color(red: 0.04, green: 0.50, blue: 0.73), Color(red: 0.35, green: 0.74, blue: 0.94)],
        [Color(red: 0.94, green: 0.43, blue: 0.31), Color(red: 0.98, green: 0.68, blue: 0.36)],
        [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
        [Color(red: 0.20, green: 0.70, blue: 0.40), Color(red: 0.10, green: 0.85, blue: 0.65)]
    ]

    // 9 themed buttons grouped by sections
    private let sections: [(title: String, items: [LearnItem])] = [
        ("Je débute", [
            LearnItem(title: "Les bases", imageName: "Bases", asset: "bases"),
            LearnItem(title: "Budget", imageName: "Budget", asset: "budget"),
            LearnItem(title: "Epargne", imageName: "Epargne", asset: "epargne")
        ]),
        ("Je sécurise", [
            LearnItem(title: "Projets", imageName: "Projets", asset: "projets"),
            LearnItem(title: "Assurances", imageName: "Assurances", asset: "assurances"),
            LearnItem(title: "Astuces", imageName: "Astuces", asset: "astuces")
        ]),
        ("Je développe", [
            LearnItem(title: "Crédit", imageName: "Crédit", asset: "credits"),
            LearnItem(title: "Investissement", imageName: "Investissement", asset: "investissements"),
            LearnItem(title: "Bourse", imageName: "Bourse", asset: "bourse")
        ])
    ]

    /// Tous les assets des 9 catégories
    private var allLearnAssets: [(title: String, asset: String)] {
        sections.flatMap { section in
            section.items.map { ($0.title, $0.asset) }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                // En-tête
                VStack(alignment: .leading, spacing: 2) {
                    Text("Les articles populaires")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

                // Carrousel d'articles aléatoires
                if !carouselArticles.isEmpty {
                    TabView(selection: $carouselIndex) {
                        ForEach(carouselArticles.indices, id: \.self) { idx in
                            let item = carouselArticles[idx]
                            let gradient = gradients[idx % gradients.count]
                            NavigationLink {
                                BasesArticleDetailView(article: item.article)
                            } label: {
                                CarouselBannerView(item: CarouselItem(
                                    category: item.category,
                                    title: item.article.title,
                                    subtitle: "\(item.article.reading_time_minutes) min • \(item.article.level)",
                                    gradient: gradient
                                ))
                                .padding(.horizontal)
                            }
                            .tag(idx)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 120)
                }

                // Sections with 9 buttons
                VStack(alignment: .leading, spacing: 10) {
                    let _ = readTracker.lastUpdate // force refresh
                    ForEach(sections, id: \.title) { section in
                        LearnSection(
                            title: section.title,
                            items: section.items,
                            badgeCounts: Dictionary(uniqueKeysWithValues: section.items.map { ($0.asset, readTracker.newCount(forAsset: $0.asset)) })
                        )
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
            ArticleReadTracker.shared.preloadAllAssets()
            loadCarouselArticles()
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
    
    /// Charge 5 articles au hasard parmi les 9 catégories
    private func loadCarouselArticles() {
        guard carouselArticles.isEmpty else { return }
        var allArticles: [(article: BasesArticleData, category: String, asset: String)] = []
        
        for item in allLearnAssets {
            if let data = ArticleCacheService.shared.loadData(forAsset: item.asset) {
                if let envelope = try? JSONDecoder().decode(BasesDataEnvelope.self, from: data) {
                    for article in envelope.articles {
                        allArticles.append((article: article, category: envelope.category, asset: item.asset))
                    }
                }
            }
        }
        
        // Mélanger et prendre 5 articles
        carouselArticles = Array(allArticles.shuffled().prefix(5))
    }
    
    private func startCarouselTimer() {
        // Cancel any existing timer first
        timerSubscription?.cancel()
        // Create new timer that fires every 4 seconds
        timerSubscription = Timer.publish(every: 4.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation { carouselIndex = (carouselIndex + 1) % max(carouselArticles.count, 1) }
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
    var badgeCounts: [String: Int] = [:]

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
                        BasesArticlesView(
                            assetName: item.asset,
                            imageName: item.imageName ?? "Bases",
                            subtitle: subtitleFor(item.title),
                            levelLabel: levelFor(item.title)
                        )
                    } label: {
                        LearnGridButton(
                            title: item.title,
                            imageName: item.imageName,
                            badgeCount: badgeCounts[item.asset] ?? 0
                        )
                    }
                }
            }
        }
    }

    private func subtitleFor(_ title: String) -> String {
        switch title {
        case "Les bases": return "Apprends les fondamentaux 💡"
        case "Budget": return "Maîtrise ton budget au quotidien 📊"
        case "Epargne": return "Mets de côté intelligemment 🐷"
        case "Projets": return "Concrétise tes projets de vie 🎯"
        case "Assurances": return "Protège-toi sans te ruiner 🛡️"
        case "Astuces": return "Les bons plans pour économiser 🧠"
        case "Crédit": return "Comprends le crédit avant de signer ✍️"
        case "Investissement": return "Fais travailler ton argent 📈"
        case "Bourse": return "Découvre la bourse pas à pas 🏦"
        default: return "Découvre les articles 📚"
        }
    }

    private func levelFor(_ title: String) -> String {
        switch title {
        case "Les bases", "Budget", "Epargne", "Astuces": return "Débutant"
        case "Projets", "Assurances", "Crédit": return "Intermédiaire"
        case "Investissement", "Bourse": return "Avancé"
        default: return "Débutant"
        }
    }
}

private struct LearnGridButton: View {
    let title: String
    let imageName: String?
    var badgeCount: Int = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
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
        .overlay(alignment: .topTrailing) {
            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(
                        Circle()
                            .fill(Color.red)
                    )
                    .offset(x: 6, y: -6)
            }
        }
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
    @State private var showingResetFinalAlert = false
    @State private var showResetSuccess = false
    @State private var isResetting = false
    @State private var resetError: String? = nil
    @State private var showingProfileConfirm = false
    @State private var firstName: String = AppSettings.firstName
    
    @State private var exportURL: URL? = nil
    @State private var exportError: String? = nil
    @State private var showingImportPicker = false
    @State private var importError: String? = nil
    @State private var showingImportConfirm = false
    @State private var showingImportSuccess = false
    @State private var pendingImportURL: URL? = nil
    @State private var showingSignOutAlert = false
    @State private var showingCategoryManagement = false
    @State private var forecastDay: Int = AppSettings.forecastDay
    @State private var showForecastInfo = false

    // MARK: - Couleurs FINZ
    private let finzPurple = Color(red: 0.52, green: 0.21, blue: 0.93)
    private let finzPink = Color(red: 1.00, green: 0.29, blue: 0.63)
    private let accentGradient = LinearGradient(
        colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
        startPoint: .leading, endPoint: .trailing
    )

    var body: some View {
        ZStack {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    profileSection
                    settingsSection
                    dataSection
                    forecastSection
                    backupSection
                    dangerZoneSection
                    versionFooter
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.04), Color.purple.opacity(0.04), Color.pink.opacity(0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .finzHeader(title: "Compte")
            .onAppear {
                firstName = AppSettings.firstName
                forecastDay = AppSettings.forecastDay
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
            .alert("Réinitialiser les données ?", isPresented: $showingResetAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Continuer", role: .destructive) {
                    showingResetFinalAlert = true
                }
            } message: {
                Text("Tu es sur le point de supprimer toutes tes données (recettes, dépenses, opérations, cartes à débit différé). Les catégories par défaut seront conservées.")
            }
            .alert("⚠️ Dernière confirmation", isPresented: $showingResetFinalAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer définitivement", role: .destructive) { resetAllData() }
            } message: {
                Text("Cette action est irréversible. Toutes tes données seront définitivement supprimées.")
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
        } // NavigationStack
        
            // Overlay de confirmation suppression (style recette mais en rouge)
            if showResetSuccess {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.red)
                    Text("Données supprimées")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                }
                .padding(32)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .transition(.opacity.combined(with: .scale))
                .zIndex(100)
            }
        } // ZStack
        .animation(.spring(response: 0.3), value: showResetSuccess)
        .sheet(isPresented: Binding<Bool>(
            get: { exportURL != nil },
            set: { if !$0 { cleanupExportFile() } }
        )) {
            if let url = exportURL, FileManager.default.fileExists(atPath: url.path) {
                ActivityView(activityItems: [url])
            } else {
                Text("Erreur d'accès au fichier exporté.").onAppear {
                    exportURL = nil
                    exportError = "Le fichier export n'est plus disponible."
                }
            }
        }
        .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [UTType.json], onCompletion: { result in
            switch result {
            case .success(let url):
                pendingImportURL = url
                // Retarder pour laisser le fileImporter se fermer
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showingImportConfirm = true
                }
            case .failure(let error):
                importError = "Impossible d'ouvrir le fichier : \(error.localizedDescription)"
            }
        })
    }

    // MARK: - Profil
    private var profileSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentGradient)
                    .frame(width: 72, height: 72)
                Text(String(firstName.prefix(1)).uppercased())
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            if let user = authService.user {
                Text(user.fullName)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(firstName.isEmpty ? "Mon compte" : firstName)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Paramètres
    private var settingsSection: some View {
        AccountSectionCard(title: "Paramètres", icon: "gearshape.fill", iconColor: .gray) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    accountIcon("person.fill", color: finzPurple)
                    TextField("Prénom", text: $firstName)
                        .textInputAutocapitalization(.words)
                        .onChange(of: firstName) { newValue in
                            AppSettings.firstName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                }
                .padding(.vertical, 12)
                
                Divider().padding(.leading, 44)
                
                accountRow(icon: "person.crop.circle", color: .blue, label: "Modifier le profil") {
                    showingProfileConfirm = true
                }
            }
        }
    }

    // MARK: - Données
    private var dataSection: some View {
        AccountSectionCard(title: "Données", icon: "square.stack.3d.up.fill", iconColor: finzPurple) {
            VStack(spacing: 0) {
                if let resetError {
                    Text(resetError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.vertical, 8)
                }
                
                accountNavRow(icon: "arrow.up.circle.fill", color: .green, label: "Recettes fixes") {
                    RecettesView().environmentObject(vm)
                }
                Divider().padding(.leading, 44)
                accountNavRow(icon: "arrow.down.circle.fill", color: finzPink, label: "Dépenses fixes") {
                    ExpensesView().environmentObject(vm)
                }
                Divider().padding(.leading, 44)
                accountNavRow(icon: "tag.circle.fill", color: .orange, label: "Catégories") {
                    CategoryManagementView()
                }
                Divider().padding(.leading, 44)
                accountNavRow(icon: "creditcard.circle.fill", color: .indigo, label: "Cartes à débit différé") {
                    DeferredCardManagementView()
                }
            }
        }
    }

    // MARK: - Prévisionnel
    private var forecastSection: some View {
        AccountSectionCard(title: "Prévisionnel", icon: "calendar.badge.clock", iconColor: .teal) {
            VStack(spacing: 12) {
                Picker("Date du prévisionnel", selection: $forecastDay) {
                    Text("Dernier jour du mois").tag(0)
                    ForEach(1...28, id: \.self) { day in
                        Text("Le \(day) du mois").tag(day)
                    }
                }
                .pickerStyle(.menu)
                .tint(finzPurple)
                .onChange(of: forecastDay) {
                    AppSettings.forecastDay = forecastDay
                }
                
                Button {
                    withAnimation { showForecastInfo.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                        Text("C'est quoi le prévisionnel ?")
                            .font(.caption)
                        Spacer()
                        Image(systemName: showForecastInfo ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                if showForecastInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Le prévisionnel, c'est ta projection de thunes 💰 à une date précise du mois.")
                            .font(.caption)
                        Text("💡 Notre conseil : mets la veille du jour où tu reçois ton salaire ou tes allocs.")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Sauvegarde
    private var backupSection: some View {
        AccountSectionCard(title: "Sauvegarde", icon: "icloud.fill", iconColor: .cyan) {
            VStack(spacing: 0) {
                accountRow(icon: "square.and.arrow.up.fill", color: .blue, label: "Exporter les données") {
                    Task { await exportBackup() }
                }
                Divider().padding(.leading, 44)
                accountRow(icon: "square.and.arrow.down.fill", color: .green, label: "Importer des données") {
                    showingImportPicker = true
                }
            }
        }
    }

    // MARK: - Zone dangereuse
    private var dangerZoneSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Text("Zone dangereuse")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.red)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                accountRow(icon: "trash.fill", color: .red, label: "Réinitialiser les données", isDestructive: true) {
                    showingResetAlert = true
                }
                Divider().padding(.leading, 44)
                accountRow(icon: "rectangle.portrait.and.arrow.right.fill", color: .red, label: "Se déconnecter", isDestructive: true) {
                    showingSignOutAlert = true
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.red.opacity(0.15), lineWidth: 1)
            )
        }
    }

    // MARK: - Version
    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text("FINZ")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(accentGradient)
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Row Helpers
    private func accountIcon(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
    
    private func accountRow(icon: String, color: Color, label: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                accountIcon(icon, color: color)
                Text(label)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(isDestructive ? .red : .primary)
                Spacer()
                if isResetting && label.contains("Réinitialiser") {
                    ProgressView()
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isResetting && label.contains("Réinitialiser"))
    }
    
    @ViewBuilder
    private func accountNavRow<Destination: View>(icon: String, color: Color, label: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                accountIcon(icon, color: color)
                Text(label)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 10)
        }
    }

    private func resetAllData() {
        isResetting = true
        resetError = nil
        
        do {
            // Fetch and delete all DeferredCardExpense entities
            let cardExpFetch = FetchDescriptor<DeferredCardExpense>()
            for item in try modelContext.fetch(cardExpFetch) { modelContext.delete(item) }
            
            // Fetch and delete all DeferredCard entities
            let cardFetch = FetchDescriptor<DeferredCard>()
            for item in try modelContext.fetch(cardFetch) { modelContext.delete(item) }
            
            // Fetch and delete all Income entities
            let incomeFetch = FetchDescriptor<Income>()
            for item in try modelContext.fetch(incomeFetch) { modelContext.delete(item) }
            
            // Fetch and delete all Expense entities
            let expenseFetch = FetchDescriptor<Expense>()
            for item in try modelContext.fetch(expenseFetch) { modelContext.delete(item) }
            
            // Fetch and delete all BudgetEntryOccurrence entities
            let occurrenceFetch = FetchDescriptor<BudgetEntryOccurrence>()
            for item in try modelContext.fetch(occurrenceFetch) { modelContext.delete(item) }
            
            // Les catégories et sous-catégories par défaut sont conservées
            
            try modelContext.save()
            
            // Notify UI and switch to questionnaire tab
            NotificationCenter.default.post(name: .didResetAllData, object: nil)
            
            // Haptic + overlay rouge
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
            withAnimation(.spring(response: 0.3)) { showResetSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showResetSuccess = false }
            }
        } catch {
            resetError = "Échec de la réinitialisation: \(error.localizedDescription)"
        }
        isResetting = false
    }
    
    private func exportBackup() async {
        let iso = ISO8601DateFormatter()

        do {
            // SwiftData fetches doivent rester sur le main thread
            let incomeFetch = FetchDescriptor<Income>()
            let incomes = try modelContext.fetch(incomeFetch)
            let incomeData: [[String: Any]] = incomes.map { income in
                var dict: [String: Any] = [
                    "id": income.id.uuidString,
                    "amount": income.amount,
                    "complement": income.complement ?? "",
                    "day": income.day,
                    "kind": income.kind,
                    "months": income.months ?? "",
                    "periodicity": income.periodicity
                ]
                if let mainCategoryID = income.mainCategoryID { dict["mainCategoryID"] = mainCategoryID.uuidString }
                if let subCategoryID = income.subCategoryID { dict["subCategoryID"] = subCategoryID.uuidString }
                return dict
            }

            let expenseFetch = FetchDescriptor<Expense>()
            let expenses = try modelContext.fetch(expenseFetch)
            let expenseData: [[String: Any]] = expenses.map { expense in
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
                if let mainCategoryID = expense.mainCategoryID { dict["mainCategoryID"] = mainCategoryID.uuidString }
                if let subCategoryID = expense.subCategoryID { dict["subCategoryID"] = subCategoryID.uuidString }
                return dict
            }

            let occurrenceFetch = FetchDescriptor<BudgetEntryOccurrence>()
            let occurrences = try modelContext.fetch(occurrenceFetch)
            let occurrenceData: [[String: Any]] = occurrences.map { occ in
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
                if let mainCategoryID = occ.mainCategoryID { dict["mainCategoryID"] = mainCategoryID.uuidString }
                if let subCategoryID = occ.subCategoryID { dict["subCategoryID"] = subCategoryID.uuidString }
                return dict
            }

            let cardFetch = FetchDescriptor<DeferredCard>()
            let cards = try modelContext.fetch(cardFetch)
            let cardData: [[String: Any]] = cards.map { card in
                var dict: [String: Any] = [
                    "id": card.id.uuidString,
                    "name": card.name,
                    "cutoffDay": card.cutoffDay,
                    "debitDay": card.debitDay,
                    "monthlyBudget": card.monthlyBudget,
                    "isActive": card.isActive,
                    "createdAt": iso.string(from: card.createdAt),
                    "updatedAt": iso.string(from: card.updatedAt)
                ]
                if let lastFour = card.lastFourDigits { dict["lastFourDigits"] = lastFour }
                return dict
            }

            let cardExpFetch = FetchDescriptor<DeferredCardExpense>()
            let cardExpenses = try modelContext.fetch(cardExpFetch)
            let cardExpData: [[String: Any]] = cardExpenses.map { ce in
                var dict: [String: Any] = [
                    "id": ce.id.uuidString,
                    "cardID": ce.cardID.uuidString,
                    "amount": ce.amount,
                    "expenseDate": iso.string(from: ce.expenseDate),
                    "cycleStartDate": iso.string(from: ce.cycleStartDate),
                    "cycleEndDate": iso.string(from: ce.cycleEndDate),
                    "isSettled": ce.isSettled,
                    "createdAt": iso.string(from: ce.createdAt)
                ]
                if let desc = ce.expenseDescription { dict["expenseDescription"] = desc }
                return dict
            }

            let mainCatFetch = FetchDescriptor<MainCategory>()
            let mainCategories = try modelContext.fetch(mainCatFetch)
            let mainCatData: [[String: Any]] = mainCategories.map { cat in
                [
                    "id": cat.id.uuidString,
                    "name": cat.name,
                    "displayName": cat.displayName,
                    "icon": cat.icon,
                    "color": cat.color,
                    "categoryType": cat.categoryType,
                    "order": cat.order
                ] as [String: Any]
            }

            let subCatFetch = FetchDescriptor<SubCategory>()
            let subCategories = try modelContext.fetch(subCatFetch)
            let subCatData: [[String: Any]] = subCategories.map { sub in
                var dict: [String: Any] = [
                    "id": sub.id.uuidString,
                    "name": sub.name,
                    "displayName": sub.displayName,
                    "icon": sub.icon,
                    "order": sub.order
                ]
                if let mainCat = sub.mainCategory { dict["mainCategoryID"] = mainCat.id.uuidString }
                return dict
            }

            // Sérialisation JSON + écriture fichier en background
            let profileName = AppSettings.firstName
            let profileForecast = AppSettings.forecastDay
            
            let tmp: URL = try await Task.detached(priority: .userInitiated) {
                let payload: [String: Any] = [
                    "version": 2,
                    "exportedAt": iso.string(from: Date()),
                    "profile": [
                        "firstName": profileName,
                        "forecastDay": profileForecast
                    ],
                    "entities": [
                        "Income": incomeData,
                        "Expense": expenseData,
                        "BudgetEntryOccurrence": occurrenceData,
                        "DeferredCard": cardData,
                        "DeferredCardExpense": cardExpData,
                        "MainCategory": mainCatData,
                        "SubCategory": subCatData
                    ]
                ]
                let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
                let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("finz_backup.json")
                try data.write(to: tmpURL, options: .atomic)
                return tmpURL
            }.value

            await MainActor.run {
                exportURL = tmp
            }
        } catch {
            await MainActor.run {
                exportError = "Erreur lors de l'export : \(error.localizedDescription)"
            }
        }
    }
    
    private func importBackup(from url: URL) async {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        // Lecture fichier + parsing JSON en background
        let parseResult: (json: [String: Any], entities: [String: Any])?
        do {
            parseResult = try await Task.detached(priority: .userInitiated) {
                let data = try Data(contentsOf: url)
                guard
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let entities = json["entities"] as? [String: Any]
                else { return nil }
                return (json, entities)
            }.value
        } catch {
            await MainActor.run { importError = "Impossible de lire le fichier : \(error.localizedDescription)" }
            return
        }
        
        guard let parseResult else {
            await MainActor.run { importError = "Fichier invalide" }
            return
        }
        
        let json = parseResult.json
        let entities = parseResult.entities
        
        do {
            
            // Restore profile
            if let profile = json["profile"] as? [String: Any] {
                if let first = profile["firstName"] as? String {
                    AppSettings.firstName = first
                    await MainActor.run { firstName = first }
                }
                if let fd = profile["forecastDay"] as? Int {
                    AppSettings.forecastDay = fd
                    await MainActor.run { forecastDay = fd }
                }
            }

            let iso = ISO8601DateFormatter()

            // Purge existing data (sauf catégories/sous-catégories par défaut)
            let cardExpFetch = FetchDescriptor<DeferredCardExpense>()
            for item in try modelContext.fetch(cardExpFetch) { modelContext.delete(item) }
            
            let cardFetch = FetchDescriptor<DeferredCard>()
            for item in try modelContext.fetch(cardFetch) { modelContext.delete(item) }

            let incomeFetch = FetchDescriptor<Income>()
            for item in try modelContext.fetch(incomeFetch) { modelContext.delete(item) }
            
            let expenseFetch = FetchDescriptor<Expense>()
            for item in try modelContext.fetch(expenseFetch) { modelContext.delete(item) }
            
            let occurrenceFetch = FetchDescriptor<BudgetEntryOccurrence>()
            for item in try modelContext.fetch(occurrenceFetch) { modelContext.delete(item) }

            // Merge MainCategory — mise à jour des existantes, insertion des nouvelles
            let existingMainCats = try modelContext.fetch(FetchDescriptor<MainCategory>())
            var mainCatByID: [UUID: MainCategory] = [:]
            for cat in existingMainCats { mainCatByID[cat.id] = cat }
            
            var mainCategoryMap: [String: MainCategory] = [:]
            if let array = entities["MainCategory"] as? [[String: Any]] {
                for dict in array {
                    guard let idStr = dict["id"] as? String,
                          let id = UUID(uuidString: idStr),
                          let name = dict["name"] as? String,
                          let displayName = dict["displayName"] as? String,
                          let icon = dict["icon"] as? String,
                          let color = dict["color"] as? String,
                          let categoryType = dict["categoryType"] as? String,
                          let order = dict["order"] as? Int else { continue }
                    
                    if let existing = mainCatByID[id] {
                        // Mettre à jour la catégorie existante
                        existing.name = name
                        existing.displayName = displayName
                        existing.icon = icon
                        existing.color = color
                        existing.categoryType = categoryType
                        existing.order = order
                        mainCategoryMap[idStr] = existing
                    } else {
                        // Nouvelle catégorie
                        let cat = MainCategory(id: id, name: name, displayName: displayName, icon: icon, color: color, categoryType: categoryType, order: order)
                        modelContext.insert(cat)
                        mainCategoryMap[idStr] = cat
                    }
                }
            }
            // Garder aussi les catégories existantes non présentes dans le backup dans le map
            for (_, cat) in mainCatByID {
                if mainCategoryMap[cat.id.uuidString] == nil {
                    mainCategoryMap[cat.id.uuidString] = cat
                }
            }
            
            // Merge SubCategory — mise à jour des existantes, insertion des nouvelles
            let existingSubCats = try modelContext.fetch(FetchDescriptor<SubCategory>())
            var subCatByID: [UUID: SubCategory] = [:]
            for sub in existingSubCats { subCatByID[sub.id] = sub }
            
            if let array = entities["SubCategory"] as? [[String: Any]] {
                for dict in array {
                    guard let idStr = dict["id"] as? String,
                          let id = UUID(uuidString: idStr),
                          let name = dict["name"] as? String,
                          let displayName = dict["displayName"] as? String,
                          let icon = dict["icon"] as? String,
                          let order = dict["order"] as? Int else { continue }
                    
                    let parentCat: MainCategory? = (dict["mainCategoryID"] as? String).flatMap { mainCategoryMap[$0] }
                    
                    if let existing = subCatByID[id] {
                        // Mettre à jour la sous-catégorie existante
                        existing.name = name
                        existing.displayName = displayName
                        existing.icon = icon
                        existing.order = order
                        if let parent = parentCat { existing.mainCategory = parent }
                    } else {
                        // Nouvelle sous-catégorie
                        let sub = SubCategory(id: id, name: name, displayName: displayName, icon: icon, order: order)
                        if let parent = parentCat { sub.mainCategory = parent }
                        modelContext.insert(sub)
                    }
                }
            }

            // Import Income
            if let incomeArray = entities["Income"] as? [[String: Any]] {
                for dict in incomeArray {
                    guard let idStr = dict["id"] as? String,
                          let id = UUID(uuidString: idStr),
                          let kind = dict["kind"] as? String,
                          let periodicity = dict["periodicity"] as? String else { continue }
                    
                    let mainCatID = (dict["mainCategoryID"] as? String).flatMap { UUID(uuidString: $0) }
                    let subCatID = (dict["subCategoryID"] as? String).flatMap { UUID(uuidString: $0) }
                    
                    let income = Income(
                        id: id,
                        amount: dict["amount"] as? Double ?? 0,
                        complement: dict["complement"] as? String,
                        day: Int16(dict["day"] as? Int ?? 0),
                        kind: kind,
                        months: dict["months"] as? String,
                        periodicity: periodicity,
                        mainCategoryID: mainCatID,
                        subCategoryID: subCatID
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
                    
                    let mainCatID = (dict["mainCategoryID"] as? String).flatMap { UUID(uuidString: $0) }
                    let subCatID = (dict["subCategoryID"] as? String).flatMap { UUID(uuidString: $0) }
                    
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
                        provider: dict["provider"] as? String,
                        mainCategoryID: mainCatID,
                        subCategoryID: subCatID
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
                    let mainCatID = (dict["mainCategoryID"] as? String).flatMap { UUID(uuidString: $0) }
                    let subCatID = (dict["subCategoryID"] as? String).flatMap { UUID(uuidString: $0) }
                    
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
                        updatedAt: updatedAt,
                        mainCategoryID: mainCatID,
                        subCategoryID: subCatID
                    )
                    modelContext.insert(occurrence)
                }
            }
            
            // Import DeferredCard
            if let cardArray = entities["DeferredCard"] as? [[String: Any]] {
                for dict in cardArray {
                    guard let idStr = dict["id"] as? String,
                          let id = UUID(uuidString: idStr),
                          let name = dict["name"] as? String else { continue }
                    
                    let card = DeferredCard(
                        id: id,
                        name: name,
                        lastFourDigits: dict["lastFourDigits"] as? String,
                        cutoffDay: Int16(dict["cutoffDay"] as? Int ?? 25),
                        debitDay: Int16(dict["debitDay"] as? Int ?? 4),
                        monthlyBudget: dict["monthlyBudget"] as? Double ?? 0,
                        isActive: dict["isActive"] as? Bool ?? true,
                        createdAt: (dict["createdAt"] as? String).flatMap { iso.date(from: $0) } ?? Date(),
                        updatedAt: (dict["updatedAt"] as? String).flatMap { iso.date(from: $0) } ?? Date()
                    )
                    modelContext.insert(card)
                }
            }
            
            // Import DeferredCardExpense
            if let ceArray = entities["DeferredCardExpense"] as? [[String: Any]] {
                for dict in ceArray {
                    guard let idStr = dict["id"] as? String,
                          let id = UUID(uuidString: idStr),
                          let cardIDStr = dict["cardID"] as? String,
                          let cardID = UUID(uuidString: cardIDStr),
                          let expenseDateStr = dict["expenseDate"] as? String,
                          let expenseDate = iso.date(from: expenseDateStr),
                          let cycleStartStr = dict["cycleStartDate"] as? String,
                          let cycleStartDate = iso.date(from: cycleStartStr),
                          let cycleEndStr = dict["cycleEndDate"] as? String,
                          let cycleEndDate = iso.date(from: cycleEndStr) else { continue }
                    
                    let ce = DeferredCardExpense(
                        id: id,
                        cardID: cardID,
                        amount: dict["amount"] as? Double ?? 0,
                        expenseDate: expenseDate,
                        expenseDescription: dict["expenseDescription"] as? String,
                        cycleStartDate: cycleStartDate,
                        cycleEndDate: cycleEndDate,
                        isSettled: dict["isSettled"] as? Bool ?? false,
                        createdAt: (dict["createdAt"] as? String).flatMap { iso.date(from: $0) } ?? Date()
                    )
                    modelContext.insert(ce)
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

// MARK: - AccountSectionCard
private struct AccountSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                content
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
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
