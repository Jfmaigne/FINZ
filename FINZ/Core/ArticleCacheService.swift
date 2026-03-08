import Foundation
import UIKit
import Combine

// MARK: - ArticleCacheService
// Télécharge les JSON articles depuis Cloudflare en tâche de fond.
// Utilise ETag / If-None-Match pour éviter les téléchargements inutiles.
// Stocke les fichiers localement (Documents/) pour un accès hors ligne.
// Fallback sur les NSDataAsset embarqués si aucun cache n'existe.

final class ArticleCacheService: ObservableObject {
    
    @MainActor static let shared = ArticleCacheService()
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Configuration
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Base URL Cloudflare — modifier cette valeur avec votre domaine
    /// Format attendu : baseURL + "/" + assetName + ".json"
    /// Exemple: "https://finz-articles.votre-domaine.workers.dev"
    /// ⚠️ REMPLACEZ cette URL par votre URL Cloudflare Pages/Workers
    static let baseURL = "https://leajson-api.jfmaigne.workers.dev"
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Propriétés
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Publie quand un asset a été mis à jour (pour rafraîchir les vues)
    @Published var lastUpdated: Date = Date()
    
    private let session: URLSession
    private let cacheDirectory: URL
    private let etagStore: URL // fichier plist pour stocker les ETags
    private var etags: [String: String] = [:] // assetName → ETag
    private var lastRefreshDates: [String: Date] = [:] // cooldown per asset
    private let refreshCooldown: TimeInterval = 300 // 5 minutes
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Init
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private init() {
        // Configuration URLSession avec timeout raisonnables
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        
        // Dossier de cache dans Application Support (persistant)
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.cacheDirectory = appSupport.appendingPathComponent("ArticlesCache", isDirectory: true)
        self.etagStore = cacheDirectory.appendingPathComponent("etags.plist")
        
        // Créer le dossier si nécessaire
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Charger les ETags sauvegardés
        loadETags()
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - API publique
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Charge les données JSON d'un asset.
    /// 1. Retourne le cache local s'il existe (instantané)
    /// 2. Sinon retourne le NSDataAsset embarqué (fallback)
    /// 3. Lance un téléchargement en arrière-plan si nécessaire
    func loadData(forAsset assetName: String) -> Data? {
        // 1. Cache local
        if let cached = readFromCache(assetName: assetName) {
            return cached
        }
        
        // 2. Fallback sur l'asset embarqué
        let bundledData = NSDataAsset(name: assetName)?.data
        
        // 3. Télécharger en arrière-plan pour la prochaine fois (une seule fois)
        Task.detached(priority: .utility) { [weak self] in
            await self?.refreshIfNeeded(assetName: assetName)
        }
        
        return bundledData
    }
    
    /// Force le téléchargement de tous les assets articles connus
    func refreshAllArticles() {
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            for asset in Self.allAssetNames {
                await self.refreshIfNeeded(assetName: asset)
            }
        }
    }
    
    /// Liste de tous les assets articles connus
    static let allAssetNames: [String] = [
        "bases",
        "budget",
        "epargne",
        "projets",
        "assurances",
        "astuces",
        "credits",
        "investissements",
        "bourse"
    ]
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Téléchargement conditionnel
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func refreshIfNeeded(assetName: String) async {
        // Cooldown: skip if refreshed recently
        if let lastRefresh = lastRefreshDates[assetName],
           Date().timeIntervalSince(lastRefresh) < refreshCooldown {
            return
        }
        
        let urlString = "\(Self.baseURL)/\(assetName).json"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Si on a un ETag, envoyer If-None-Match pour download conditionnel
        if let etag = etags[assetName] {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else { return }
            
            // Mark as refreshed regardless of result
            lastRefreshDates[assetName] = Date()
            
            switch httpResponse.statusCode {
            case 304:
                // Pas de changement
                return
                
            case 200:
                // Compare with existing cache to avoid unnecessary UI refreshes
                let existingData = readFromCache(assetName: assetName)
                if let existingData, existingData == data {
                    // Same content — just update ETag and return
                    if let newETag = httpResponse.value(forHTTPHeaderField: "ETag") {
                        etags[assetName] = newETag
                        saveETags()
                    }
                    return
                }
                
                // New content → save
                writeToCache(data: data, assetName: assetName)
                
                // Store new ETag
                if let newETag = httpResponse.value(forHTTPHeaderField: "ETag") {
                    etags[assetName] = newETag
                    saveETags()
                }
                
                // Notify views on main thread
                await MainActor.run {
                    self.lastUpdated = Date()
                }
                
            default:
                break
            }
            
        } catch {
            // No connection or network error — use cache/embedded asset
            lastRefreshDates[assetName] = Date()
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Gestion du cache fichier
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func cacheFileURL(for assetName: String) -> URL {
        cacheDirectory.appendingPathComponent("\(assetName).json")
    }
    
    private func readFromCache(assetName: String) -> Data? {
        let fileURL = cacheFileURL(for: assetName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try? Data(contentsOf: fileURL)
    }
    
    private func writeToCache(data: Data, assetName: String) {
        let fileURL = cacheFileURL(for: assetName)
        try? data.write(to: fileURL, options: .atomic)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Gestion des ETags
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func loadETags() {
        guard let data = try? Data(contentsOf: etagStore),
              let dict = try? PropertyListDecoder().decode([String: String].self, from: data)
        else { return }
        etags = dict
    }
    
    private func saveETags() {
        if let data = try? PropertyListEncoder().encode(etags) {
            try? data.write(to: etagStore, options: .atomic)
        }
    }
}
