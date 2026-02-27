import SwiftUI
import UIKit
import Foundation
import CoreData
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
    @Environment(\.managedObjectContext) var context

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
    private let carouselTimer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()

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
                .onReceive(carouselTimer) { _ in
                    withAnimation { carouselIndex = (carouselIndex + 1) % max(banners.count, 1) }
                }

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
                        ArticlesListView(assetName: item.asset, title: item.title)
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
                        .scaledToFit()
                        .frame(height: 120) // autorise le logo à déborder visuellement de la carte
                        .padding(.vertical, -6)
                } else {
                    Image(systemName: "book.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.purple)
                }
            }
        }
        .frame(height: 96)
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
    @Environment(\.managedObjectContext) private var context
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
                            .environment(\.managedObjectContext, context)
                    } label: {
                        Label("Modifier les recettes fixes", systemImage: "arrow.up.circle")
                    }
                    NavigationLink {
                        ExpensesView()
                            .environmentObject(vm)
                            .environment(\.managedObjectContext, context)
                    } label: {
                        Label("Modifier les dépenses fixes", systemImage: "arrow.down.circle")
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
        let entityNames = ["Income", "Expense", "BudgetEntryOccurrence"]
        do {
            for name in entityNames {
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetch)
                deleteRequest.resultType = .resultTypeObjectIDs
                if let result = try context.execute(deleteRequest) as? NSBatchDeleteResult,
                   let objectIDs = result.result as? [NSManagedObjectID],
                   !objectIDs.isEmpty {
                    let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                }
            }
            if context.hasChanges {
                try context.save()
            }
            // Notify UI and switch to questionnaire tab
            NotificationCenter.default.post(name: .didResetAllData, object: nil)
            showingSuccessAlert = true
        } catch {
            resetError = "Échec de la réinitialisation: \(error.localizedDescription)"
        }
        isResetting = false
    }
    
    private func exportBackup() async {
        let entityNames = ["Income", "Expense", "BudgetEntryOccurrence"]
        let iso = ISO8601DateFormatter()
        var payload: [String: Any] = [
            "version": 1,
            "exportedAt": iso.string(from: Date()),
            "profile": ["firstName": AppSettings.firstName],
            "entities": [:]
        ]

        do {
            var entitiesData: [String: [[String: Any]]] = [:]
            for name in entityNames {
                let fetch = NSFetchRequest<NSManagedObject>(entityName: name)
                let objects = try context.fetch(fetch)
                let mapped: [[String: Any]] = objects.compactMap { obj in
                    let entity = obj.entity.attributesByName
                    var dict: [String: Any] = [:]
                    for key in entity.keys {
                        let raw = obj.value(forKey: key)
                        if let date = raw as? Date {
                            dict[key] = iso.string(from: date)
                        } else if let uuid = raw as? UUID {
                            dict[key] = uuid.uuidString
                        } else if let data = raw as? Data {
                            dict[key] = data.base64EncodedString()
                        } else if let number = raw as? NSNumber {
                            dict[key] = number
                        } else if let str = raw as? String {
                            dict[key] = str
                        }
                    }
                    return dict.isEmpty ? nil : dict
                }
                entitiesData[name] = mapped
            }
            payload["entities"] = entitiesData

            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("finz_backup.json")
            try data.write(to: tmp, options: .atomic)

            DispatchQueue.main.async {
                exportURL = tmp
                showingExportSheet = true
            }
        } catch {
            exportError = "Erreur lors de l'export : \(error.localizedDescription)"
        }
    }
    
    private func importBackup(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let entities = json["entities"] as? [String: Any]
            else {
                importError = "Fichier invalide"
                return
            }
            if let profile = json["profile"] as? [String: Any], let first = profile["firstName"] as? String {
                AppSettings.firstName = first
                await MainActor.run { firstName = first }
            }

            let iso = ISO8601DateFormatter()
            let entityNames = ["Income", "Expense", "BudgetEntryOccurrence"]

            // Purge existing data
            for name in entityNames {
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                let delete = NSBatchDeleteRequest(fetchRequest: fetch)
                _ = try context.execute(delete)
            }
            context.reset()

            // Import
            for name in entityNames {
                guard let array = entities[name] as? [[String: Any]] else { continue }
                guard let entityDesc = NSEntityDescription.entity(forEntityName: name, in: context) else { continue }
                for dict in array {
                    let obj = NSManagedObject(entity: entityDesc, insertInto: context)
                    for (key, value) in dict {
                        guard let attr = entityDesc.attributesByName[key] else { continue }
                        let attrType = attr.attributeType
                        switch attrType {
                        case .UUIDAttributeType:
                            if let str = value as? String, let uuid = UUID(uuidString: str) { obj.setValue(uuid, forKey: key) }
                        case .dateAttributeType:
                            if let str = value as? String, let date = iso.date(from: str) { obj.setValue(date, forKey: key) }
                        case .stringAttributeType:
                            obj.setValue(value as? String, forKey: key)
                        case .doubleAttributeType, .floatAttributeType, .decimalAttributeType:
                            if let num = value as? NSNumber { obj.setValue(num, forKey: key) }
                        case .integer16AttributeType, .integer32AttributeType, .integer64AttributeType:
                            if let num = value as? NSNumber { obj.setValue(num.int64Value, forKey: key) }
                        case .booleanAttributeType:
                            if let num = value as? NSNumber { obj.setValue(num.boolValue, forKey: key) }
                        case .binaryDataAttributeType:
                            if let str = value as? String, let data = Data(base64Encoded: str) { obj.setValue(data, forKey: key) }
                        default:
                            obj.setValue(value, forKey: key)
                        }
                    }
                }
            }

            if context.hasChanges {
                try context.save()
            }
            await MainActor.run {
                pendingImportURL = nil
                showingImportConfirm = false
                showingImportSuccess = true
            }
        } catch {
            importError = "Erreur lors de l'import : \(error.localizedDescription)"
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
