# Configuration complète Apple Sign In et Google OAuth - FINZ

## 🍎 CONFIGURATION APPLE SIGN IN

### Étape 1 : Ajouter la capability dans Xcode

1. Ouvre **FINZ.xcodeproj** dans Xcode
2. Sélectionne le projet **FINZ**
3. Va dans l'onglet **Signing & Capabilities**
4. Clique sur **+ Capability**
5. Recherche et sélectionne **Sign in with Apple**

### Étape 2 : Configurer l'App ID (Apple Developer)

1. Va sur https://developer.apple.com/account/resources/identifiers/list
2. Clique sur **Identifiers**
3. Trouve ton **App ID** (commençant par `com.`)
4. Clique dessus et sélectionne **Edit**
5. Cocher **Sign in with Apple** sous **Capabilities**
6. Clique **Save**

### Étape 3 : Configurer les Services ID (requis pour Sign in with Apple)

1. Va sur https://developer.apple.com/account/resources/identifiers/list/serviceId
2. Clique **+ (Register a new identifier)**
3. Sélectionne **Service IDs**
4. Clique **Continue**
5. Rentre :
   - **Description**: `FINZ Sign In Service`
   - **Identifier**: `com.finz.signin` (ou `com.yourcompany.finz.signin`)
6. Clique **Register**
7. Clique sur ton nouveau Service ID
8. Cocher **Sign in with Apple**
9. Clique sur **Configure**
10. Sous "Web Authentication Configuration" :
    - **Domains and Subdomains**: `finz.app` (remplace par ton domaine)
    - **Return URLs**: `https://finz.app/oauth/callback`
11. Clique **Save**, puis **Continue**, puis **Register**

### Étape 4 : Info.plist (optionnel, généralement automatique)

Ajoute à ton Info.plist si manquant:
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

## 🔵 CONFIGURATION GOOGLE SIGN IN

### Étape 1 : Créer un projet Google Cloud

1. Va sur https://console.cloud.google.com
2. Crée un nouveau projet (ex: "FINZ Authentication")
3. Note le **Project ID** (tu en auras besoin)

### Étape 2 : Créer les identifiants OAuth 2.0

1. Va dans **APIs & Services > Credentials**
2. Clique **+ Create Credentials**
3. Sélectionne **OAuth 2.0 Client ID**
4. Type: **iOS**
5. Rentre :
   - **Name**: `FINZ iOS`
   - **Bundle ID**: `com.yourcompany.finz` (remplace par ton vrai Bundle ID)
   - **Team ID**: Trouve-le dans Xcode > Settings > Accounts > Team ID
6. Clique **Create**
7. Note le **Client ID** généré (format: `xxx.apps.googleusercontent.com`)

### Étape 3 : Activer l'API Google+ (ou OAuth 2.0)

1. Va dans **APIs & Services > Enabled APIs & services**
2. Clique **+ Enable APIs and Services**
3. Recherche **Google+ API** (ou **Google Identity Services**)
4. Clique **Enable**

### Étape 4 : Configurer le Custom URL Scheme

1. Ouvre ton **Info.plist**
2. Ajoute (ou complète) :

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>finz</string>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

Remplace `YOUR_CLIENT_ID` par le début de ton Client ID (avant `.apps.googleusercontent.com`).

### Étape 5 : Configurer le Client ID dans le code

Dans **AuthenticationService.swift**, ligne ~107, remplace :

```swift
let clientID = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
```

Par ton vrai Client ID.

---

## 🔧 CORRECTION DE L'ERREUR 1000 APPLE

**L'erreur 1000** signifie généralement un problème de configuration. Vérifie :

1. ✅ **Sign in with Apple capability** ajoutée dans Xcode
2. ✅ **Service ID** créé et configuré sur Apple Developer
3. ✅ **Bundle ID** correspond exactement entre Xcode et Apple Developer
4. ✅ **Team ID** correct
5. ✅ **Domaines et URLs** configurés correctement dans Service ID

Si l'erreur persiste :
- Régénère les identifiants sur Apple Developer
- Attends 5-10 minutes pour la propagation
- Réinstalle l'app sur le simulateur/device
- Clean build folder (Cmd+Shift+K)

---

## 🌐 CONFIGURATION DU BACKEND (Important pour Production)

### Pour Google OAuth :
Tu dois créer un backend endpoint qui :
1. Reçoit le `code` d'autorisation
2. L'échange contre un `access_token` via Google
3. Retourne un JWT ou session token à ton app

Exemple pseudo-code:
```
POST /auth/google
Body: { code: "..." }
Response: { token: "...", user: {...} }
```

### Pour Apple Sign In :
Apple fournit directement un `identityToken` (JWT) que tu peux :
1. Valider côté backend
2. Utiliser pour créer une session utilisateur

---

## 📝 CHECKLIST FINALE

- [ ] Apple capability "Sign in with Apple" activée
- [ ] Service ID créé sur Apple Developer
- [ ] Bundle ID vérifié (Xcode = Apple Developer)
- [ ] Team ID correct
- [ ] Google Project créé
- [ ] OAuth 2.0 Client ID généré
- [ ] Client ID mis à jour dans AuthenticationService.swift
- [ ] URL Schemes configurés dans Info.plist
- [ ] API Google+ activée
- [ ] Test sur simulateur/device réel
- [ ] Backend prêt pour valider les tokens (future)

---

## 🧪 TEST SANS BACKEND

Pour tester maintenant **sans backend** :
- L'app accepte les identifiants et crée un utilisateur local
- Le token n'est pas validé (only for demo)
- Pour production, tu dois implémenter la validation backend

---

## Support supplémentaire

- Apple Sign In: https://developer.apple.com/sign-in-with-apple/get-started/
- Google OAuth: https://developers.google.com/identity/sign-in/ios
