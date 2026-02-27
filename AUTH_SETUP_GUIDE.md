# Configuration d'Authentification Google et Apple pour FINZ

## 1. Configuration Apple Sign In

### Étapes dans Xcode:
1. Sélectionne le projet FINZ
2. Va dans "Signing & Capabilities"
3. Clique sur "+ Capability"
4. Recherche et ajoute "Sign in with Apple"

### Modifications requises dans Info.plist:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>finz</string>
    </array>
  </dict>
</array>
```

---

## 2. Configuration Google Sign In

### Prérequis:
1. Crée un projet sur Google Cloud Console (https://console.cloud.google.com)
2. Active Google+ API
3. Crée des identifiants OAuth 2.0:
   - Type: Application iOS
   - Bundle ID: com.yourcompany.finz (remplace avec ton vrai bundle ID)
   - Team ID: Trouve-le dans Xcode > Settings > Account > Team ID

### Info.plist - Ajoute:
```xml
<key>GIDClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>finz</string>
      <string>com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### Remplace:
- `YOUR_GOOGLE_CLIENT_ID` par ton Client ID depuis Google Cloud Console

---

## 3. Configuration URL Scheme Personnalisé

Pour intercepter les callbacks OAuth, ajoute à Info.plist:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>finz</string>
  <string>finzauth</string>
</array>
```

---

## 4. Intégration dans RootView ou AppDelegate

### Option 1: Via SessionManager (recommandé)
```swift
@StateObject var authService = AuthenticationService()

if authService.isAuthenticated {
    // Affiche l'app principale
    BudgetTabView()
} else {
    // Affiche l'écran de login
    AuthenticationView()
}
```

### Option 2: Via AppDelegate
```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLHandlerOptionKey : Any] = [:]) -> Bool {
    var handled: Bool
    
    // Google OAuth redirect
    if url.scheme == "com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID" {
        handled = GIDSignIn.sharedInstance.handle(url)
    } else {
        // Autres schemes
        handled = false
    }
    
    return handled
}
```

---

## 5. Dépendances Pod (si tu utilises CocoaPods)

Pour Google Sign-In via SDK officiel:
```ruby
pod 'GoogleSignIn', '~> 7.0'
```

Puis `pod install`

---

## 6. Variables d'Environnement pour la Sécurité

Stocke les identifiants sensibles dans des variables d'environnement:

### .env (à la racine du projet, NE PAS committer)
```
GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com
APPLE_TEAM_ID=YOUR_TEAM_ID
```

Puis charge-les dans le code:
```swift
let googleClientID = ProcessInfo.processInfo.environment["GOOGLE_CLIENT_ID"] ?? ""
```

---

## 7. Tests en Développement

### Tester Apple Sign In:
- Utilise un vrai device Apple ou le simulateur avec une compte Apple
- La signature est vérifiée localement via AuthenticationServices

### Tester Google Sign In:
- Utilise un vrai device ou un simulateur configuré avec Google Play Services
- Ou implémente un backend mock pour les tests

---

## 8. Points de Sécurité Importants

1. **Ne stocke JAMAIS les mots de passe** en clair dans UserDefaults
   → Utilise des tokens JWT/Bearer tokens stockés dans Keychain

2. **Valide les tokens côté backend** pour chaque requête API

3. **Utilise HTTPS** pour toutes les communications OAuth

4. **Renouvelle les tokens régulièrement** (refresh token pattern)

5. **Gère les erreurs d'expiration** et redirecte vers login si nécessaire

---

## 9. Exemple d'Intégration Complète

```swift
// Dans RootView.swift
@StateObject private var authService = AuthenticationService()

var body: some View {
    ZStack {
        if authService.isAuthenticated {
            BudgetTabView()
                .environmentObject(authService)
        } else {
            AuthenticationView()
                .environmentObject(authService)
        }
    }
    .onAppear {
        authService.checkAuthenticationStatus()
    }
}
```

---

## 10. Checklist d'Intégration

- [ ] AuthenticationService.swift créé et compilé
- [ ] AuthenticationView.swift remplacé
- [ ] Apple Sign In capability ajoutée dans Xcode
- [ ] Google Client ID généré et configuré
- [ ] Info.plist mis à jour avec CFBundleURLSchemes
- [ ] RootView intégre AuthenticationService
- [ ] Tests effectués sur device
- [ ] UserDefaults remplacé par Keychain pour les tokens sensibles (futur)
- [ ] Backend valide les tokens (futur)

---

Pour toute question ou problème, consulte:
- Apple: https://developer.apple.com/sign-in-with-apple/
- Google: https://developers.google.com/identity/sign-in/ios
