import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @ObservedObject var authService: AuthenticationService
    @State private var showingAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Logo / Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.purple)

                    Image("finz_logo_couleur")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)

                    Text("Gère ton budget comme jamais")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                Spacer()
                
                // Error Message
                if let error = authService.authError {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Apple Sign In Button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        handleAppleSignIn(result: result)
                    }
                )
                .frame(height: 50)
                .cornerRadius(12)
                
                // Google Sign In Button
                Button(action: {
                    authService.signInWithGoogle()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Continuer avec Google")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 50)
                    .foregroundStyle(.primary)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Divider
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    Text("ou")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.vertical, 8)
                
                // Email Sign In
                NavigationLink {
                    EmailAuthenticationView(authService: authService)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Continuer avec Email")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 50)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.52, green: 0.21, blue: 0.93),
                                    Color(red: 1.00, green: 0.29, blue: 0.63)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                // Terms
                VStack(spacing: 8) {
                    Text("En continuant, tu acceptes nos conditions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Link("Conditions d'utilisation", destination: URL(string: "https://finz.app/terms") ?? URL(fileURLWithPath: ""))
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("et")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Link("Politique de confidentialité", destination: URL(string: "https://finz.app/privacy") ?? URL(fileURLWithPath: ""))
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: authService.isAuthenticated) { oldValue, newValue in
            if newValue {
                // Navigate to main app
                NotificationCenter.default.post(name: NSNotification.Name("UserDidAuthenticate"), object: nil)
            }
        }
        .alert("Erreur d'authentification", isPresented: .constant(authService.authError != nil)) {
            Button("OK") {
                authService.authError = nil
            }
        } message: {
            if let error = authService.authError {
                Text(error)
            }
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let user = AuthUser(
                    id: appleIDCredential.user,
                    email: appleIDCredential.email ?? "unknown@apple.com",
                    fullName: appleIDCredential.fullName?.givenName ?? "Apple User",
                    provider: .apple,
                    token: String(data: appleIDCredential.identityToken ?? Data(), encoding: .utf8) ?? ""
                )
                authService.saveUser(user)
            }
        case .failure(let error):
            authService.authError = error.localizedDescription
        }
    }
}

struct EmailAuthenticationView: View {
    @ObservedObject var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(isSignUp ? "Créer un compte" : "Se connecter")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("Nom complet", text: $fullName)
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    SecureField("Mot de passe", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                Button(action: handleEmailAuth) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(isSignUp ? "Créer un compte" : "Se connecter")
                            .font(.headline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.52, green: 0.21, blue: 0.93),
                                Color(red: 1.00, green: 0.29, blue: 0.63)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                Button(action: { isSignUp.toggle() }) {
                    HStack(spacing: 4) {
                        Text(isSignUp ? "Déjà inscrit ?" : "Pas encore inscrit ?")
                            .foregroundStyle(.secondary)
                        Text(isSignUp ? "Se connecter" : "S'inscrire")
                            .foregroundStyle(.blue)
                    }
                    .font(.subheadline)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func handleEmailAuth() {
        isLoading = true
        // Simulate backend call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let user = AuthUser(
                id: UUID().uuidString,
                email: email,
                fullName: isSignUp ? fullName : email.split(separator: "@").first.map(String.init) ?? "User",
                provider: .google,
                token: password
            )
            authService.saveUser(user)
            isLoading = false
        }
    }
}

#Preview {
    AuthenticationView(authService: AuthenticationService())
}
