import SwiftUI
import Foundation
import AuthenticationServices
import Combine

// MARK: - Models

struct AuthUser: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let provider: AuthProvider
    let token: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, fullName, provider, token, createdAt
    }
    
    init(id: String, email: String, fullName: String, provider: AuthProvider, token: String) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.provider = provider
        self.token = token
        self.createdAt = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.email = try container.decode(String.self, forKey: .email)
        self.fullName = try container.decode(String.self, forKey: .fullName)
        self.provider = try container.decode(AuthProvider.self, forKey: .provider)
        self.token = try container.decode(String.self, forKey: .token)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(provider, forKey: .provider)
        try container.encode(token, forKey: .token)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

enum AuthProvider: String, Codable {
    case apple
    case google
}

// MARK: - Authentication Service

@MainActor
final class AuthenticationService: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: AuthUser?
    @Published var authError: String?
    @Published var isLoading = false
    
    private var currentAuthorizationController: ASAuthorizationController?
    
    override init() {
        super.init()
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    
    func checkAuthenticationStatus() {
        do {
            if let user = try KeychainHelper.shared.retrieveAuthUser() {
                self.user = user
                self.isAuthenticated = true
            }
        } catch {
            self.authError = error.localizedDescription
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        
        self.currentAuthorizationController = controller
        
        do {
            try controller.performRequests()
        } catch {
            self.authError = "Erreur lors de la tentative de connexion Apple : \(error.localizedDescription)"
        }
    }
    
    // MARK: - Google Sign In (Simplified - use browser based OAuth)
    
    func signInWithGoogle() {
        // Note: For production, you should use the official GoogleSignIn SDK
        // This is a simplified browser-based approach
        let clientID = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
        let redirectURI = "finz://oauth2callback"
        let scopes = "openid+email+profile"
        
        guard let encodedRedirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let authURL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(clientID)&redirect_uri=\(encodedRedirect)&response_type=code&scope=\(scopes)") else {
            self.authError = "Erreur de configuration Google"
            return
        }
        
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "finz") { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = "Erreur Google : \(error.localizedDescription)"
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    self?.authError = "Erreur : pas d'URL de callback"
                    return
                }
                
                self?.handleGoogleAuthCallback(callbackURL)
            }
        }
        
        session.presentationContextProvider = self
        
        do {
            let started = session.start()
            if !started {
                self.authError = "Impossible de démarrer la session d'authentification Google"
            }
        } catch {
            self.authError = "Erreur lors de la tentative de connexion Google : \(error.localizedDescription)"
        }
    }
    
    private func handleGoogleAuthCallback(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            self.authError = "Impossible d'extraire le code d'authentification Google"
            return
        }
        
        // Pour un vrai usage, échange le code contre un token via ton serveur backend
        let user = AuthUser(
            id: UUID().uuidString,
            email: "user@google.com",
            fullName: "Utilisateur Google",
            provider: .google,
            token: code
        )
        
        saveUser(user)
    }
    
    // MARK: - User Management
    
    func saveUser(_ user: AuthUser) {
        do {
            try KeychainHelper.shared.saveAuthUser(user)
            self.user = user
            self.isAuthenticated = true
            self.authError = nil
            
            // Post notification pour notifier les vues qu'on est authentifiés
            NotificationCenter.default.post(name: NSNotification.Name("UserDidAuthenticate"), object: nil)
        } catch {
            self.authError = "Erreur lors de la sauvegarde des données : \(error.localizedDescription)"
        }
    }
    
    func signOut() {
        do {
            try KeychainHelper.shared.deleteAuthUser()
            self.user = nil
            self.isAuthenticated = false
            self.authError = nil
        } catch {
            self.authError = "Erreur lors de la déconnexion : \(error.localizedDescription)"
        }
    }
}

// MARK: - Apple Sign In Delegate

extension AuthenticationService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            Task { @MainActor in
                self.authError = "Erreur : impossible de récupérer les identifiants Apple"
            }
            return
        }
        
        let userID = appleIDCredential.user
        let email = appleIDCredential.email ?? "unknown@apple.local"
        let fullName = appleIDCredential.fullName?.givenName ?? "Utilisateur Apple"
        
        let identityTokenData = appleIDCredential.identityToken ?? Data()
        let identityToken = String(data: identityTokenData, encoding: .utf8) ?? UUID().uuidString
        
        let user = AuthUser(
            id: userID,
            email: email,
            fullName: fullName,
            provider: .apple,
            token: identityToken
        )
        
        Task { @MainActor in
            self.saveUser(user)
        }
    }
    
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let nsError = error as NSError
        
        Task { @MainActor in
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                self.authError = "Connexion Apple annulée par l'utilisateur"
            } else if nsError.code == ASAuthorizationError.failed.rawValue {
                self.authError = "Erreur lors de la tentative de connexion Apple"
            } else if nsError.code == ASAuthorizationError.invalidResponse.rawValue {
                self.authError = "Réponse invalide d'Apple"
            } else {
                self.authError = "Erreur Apple (\(nsError.code)) : \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Presentation Context Providing

extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding, ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.getPresentationAnchor()
    }
    
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.getPresentationAnchor()
    }
    
    private nonisolated func getPresentationAnchor() -> ASPresentationAnchor {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?
            .windows
            .first else {
            fatalError("Impossible de trouver la fenêtre de présentation")
        }
        return window
    }
}

