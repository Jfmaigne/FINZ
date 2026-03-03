import Foundation

enum AppSettings {
    private static let firstNameKey = "userFirstName"
    private static let forecastDayKey = "forecastDay"

    static var firstName: String {
        get { UserDefaults.standard.string(forKey: firstNameKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: firstNameKey) }
    }

    /// Jour du mois pour le calcul du prévisionnel.
    /// 0 = dernier jour du mois (par défaut)
    /// 1-31 = jour spécifique
    static var forecastDay: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: forecastDayKey)
            return val == 0 ? 0 : val // 0 = pas configuré = fin de mois
        }
        set { UserDefaults.standard.set(newValue, forKey: forecastDayKey) }
    }

    /// Libellé lisible du jour du prévisionnel
    static var forecastDayLabel: String {
        let day = forecastDay
        if day == 0 || day >= 28 {
            return "Dernier jour du mois"
        }
        return "Le \(day) du mois"
    }
}
