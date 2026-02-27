import Foundation
import Security

// MARK: - Keychain Helper

final class KeychainHelper {
    static let shared = KeychainHelper()
    
    private let service = "com.finz.auth"
    
    func save(_ value: String, forKey key: String) throws {
        let data = value.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Supprime l'ancienne valeur si elle existe
        SecItemDelete(query as CFDictionary)
        
        // Ajoute la nouvelle valeur
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func retrieve(forKey key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        
        return value
    }
    
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Erreur lors de la sauvegarde Keychain: \(status)"
        case .retrieveFailed(let status):
            return "Erreur lors de la récupération Keychain: \(status)"
        case .deleteFailed(let status):
            return "Erreur lors de la suppression Keychain: \(status)"
        case .decodingFailed:
            return "Erreur de décodage des données Keychain"
        }
    }
}

// Extension pour stocker/récupérer AuthUser de manière sécurisée
extension KeychainHelper {
    func saveAuthUser(_ user: AuthUser) throws {
        let encoded = try JSONEncoder().encode(user)
        let jsonString = String(data: encoded, encoding: .utf8) ?? ""
        try save(jsonString, forKey: "authUser")
    }
    
    func retrieveAuthUser() throws -> AuthUser? {
        guard let jsonString = try retrieve(forKey: "authUser") else {
            return nil
        }
        guard let data = jsonString.data(using: .utf8) else {
            throw KeychainError.decodingFailed
        }
        do {
            return try JSONDecoder().decode(AuthUser.self, from: data)
        } catch {
            throw KeychainError.decodingFailed
        }
    }
    
    func deleteAuthUser() throws {
        try delete(forKey: "authUser")
    }
    
    func saveToken(_ token: String, forKey key: String = "authToken") throws {
        try save(token, forKey: key)
    }
    
    func retrieveToken(forKey key: String = "authToken") throws -> String? {
        return try retrieve(forKey: key)
    }
}
