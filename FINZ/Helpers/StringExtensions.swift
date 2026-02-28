import Foundation

extension String {
    /// Génère un slug depuis une chaîne (pour les codes internes)
    /// Exemple: "Loyer + Charges" -> "loyer_charges"
    var slugified: String {
        let lowercased = self.lowercased()
        let normalized = lowercased
            .folding(options: .diacriticInsensitive, locale: .current)
        
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
        let filtered = normalized
            .map { character -> String in
                if allowedCharacters.contains(UnicodeScalar(String(character))!) {
                    return String(character)
                } else if character.isWhitespace || character == "+" || character == "/" || character == "-" {
                    return "_"
                } else {
                    return ""
                }
            }
            .joined()
        
        // Supprimer les underscores en double
        var result = ""
        var lastWasUnderscore = false
        
        for char in filtered {
            if char == "_" {
                if !lastWasUnderscore {
                    result.append(char)
                    lastWasUnderscore = true
                }
            } else {
                result.append(char)
                lastWasUnderscore = false
            }
        }
        
        // Supprimer les underscores au début et à la fin
        return result.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}
