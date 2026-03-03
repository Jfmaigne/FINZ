import Foundation
import SwiftData

/// Service de gestion des cartes à débit différé
/// Gère le calcul de l'impact sur le budget selon le cycle de la carte
@MainActor
struct DeferredCardService {
    
    // MARK: - Cycle Calculation
    
    /// Calcule les dates du cycle en cours pour une carte
    /// - Parameters:
    ///   - card: La carte à débit différé
    ///   - referenceDate: Date de référence (par défaut aujourd'hui)
    /// - Returns: Tuple (dateDebut, dateBascule, datePrelevement)
    static func getCurrentCycle(for card: DeferredCard, referenceDate: Date = Date()) -> (start: Date, cutoff: Date, debit: Date) {
        let calendar = Calendar.current
        let cutoffDay = Int(card.cutoffDay)
        let debitDay = Int(card.debitDay)
        
        let currentDay = calendar.component(.day, from: referenceDate)
        let currentMonth = calendar.component(.month, from: referenceDate)
        let currentYear = calendar.component(.year, from: referenceDate)
        
        var cycleStartMonth: Int
        var cycleStartYear: Int
        var cutoffMonth: Int
        var cutoffYear: Int
        var debitMonth: Int
        var debitYear: Int
        
        // Déterminer dans quel cycle nous sommes
        if currentDay <= cutoffDay {
            // Nous sommes avant la bascule du mois en cours
            // Le cycle a commencé le mois précédent après la bascule
            if currentMonth == 1 {
                cycleStartMonth = 12
                cycleStartYear = currentYear - 1
            } else {
                cycleStartMonth = currentMonth - 1
                cycleStartYear = currentYear
            }
            cutoffMonth = currentMonth
            cutoffYear = currentYear
        } else {
            // Nous sommes après la bascule du mois en cours
            // Le cycle a commencé ce mois après la bascule
            cycleStartMonth = currentMonth
            cycleStartYear = currentYear
            if currentMonth == 12 {
                cutoffMonth = 1
                cutoffYear = currentYear + 1
            } else {
                cutoffMonth = currentMonth + 1
                cutoffYear = currentYear
            }
        }
        
        // Date de prélèvement
        // Si le jour de prélèvement est APRÈS le jour de bascule dans le mois,
        // le prélèvement a lieu dans le MÊME mois que la bascule.
        // Sinon (debitDay <= cutoffDay), le prélèvement est le mois suivant.
        if debitDay > cutoffDay {
            // Prélèvement dans le même mois que la bascule
            debitMonth = cutoffMonth
            debitYear = cutoffYear
        } else {
            // Prélèvement le mois suivant la bascule
            if cutoffMonth == 12 {
                debitMonth = 1
                debitYear = cutoffYear + 1
            } else {
                debitMonth = cutoffMonth + 1
                debitYear = cutoffYear
            }
        }
        
        // Construire les dates
        let cycleStart = calendar.date(from: DateComponents(year: cycleStartYear, month: cycleStartMonth, day: cutoffDay + 1)) ?? referenceDate
        let cutoffDate = calendar.date(from: DateComponents(year: cutoffYear, month: cutoffMonth, day: cutoffDay)) ?? referenceDate
        
        // Pour la date de prélèvement, ajuster au dernier jour du mois si configuré >= 28
        let debitDateComponents = DateComponents(year: debitYear, month: debitMonth, day: 1)
        let debitMonthDate = calendar.date(from: debitDateComponents) ?? referenceDate
        let lastDayOfDebitMonth = calendar.range(of: .day, in: .month, for: debitMonthDate)?.count ?? 30
        let effectiveDebitDay: Int
        if debitDay >= 28 {
            effectiveDebitDay = lastDayOfDebitMonth
        } else {
            effectiveDebitDay = min(debitDay, lastDayOfDebitMonth)
        }
        let debitDate = calendar.date(from: DateComponents(year: debitYear, month: debitMonth, day: effectiveDebitDay)) ?? referenceDate
        
        return (cycleStart, cutoffDate, debitDate)
    }
    
    /// Détermine si nous sommes avant ou après la bascule pour un mois donné
    static func isBeforeCutoff(for card: DeferredCard, referenceDate: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: referenceDate)
        return currentDay <= Int(card.cutoffDay)
    }
    
    /// Calcule la date de référence pour le cycle précédent
    /// Le cycle précédent est celui qui sera prélevé prochainement ou qui vient d'être prélevé
    static func previousCycleReferenceDate(for card: DeferredCard, referenceDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        // Reculer d'un mois pour obtenir le cycle précédent
        return calendar.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
    }
    
    // MARK: - Budget Impact Calculation
    
    /// Calcule l'impact de la carte sur le budget
    /// - Parameters:
    ///   - card: La carte à débit différé
    ///   - expenses: Les dépenses associées à la carte pour le cycle
    ///   - referenceDate: Date de référence
    /// - Returns: Le montant à prendre en compte dans le budget
    static func calculateBudgetImpact(
        for card: DeferredCard,
        expenses: [DeferredCardExpense],
        referenceDate: Date = Date()
    ) -> Double {
        guard card.isActive else { return 0 }
        
        let cycle = getCurrentCycle(for: card, referenceDate: referenceDate)
        let isBeforeCutoff = isBeforeCutoff(for: card, referenceDate: referenceDate)
        
        // Filtrer les dépenses du cycle en cours
        let cycleExpenses = expenses.filter { expense in
            expense.cardID == card.id &&
            expense.expenseDate >= cycle.start &&
            expense.expenseDate <= cycle.cutoff &&
            !expense.isSettled
        }
        
        let actualTotal = cycleExpenses.reduce(0) { $0 + $1.amount }
        
        if isBeforeCutoff {
            // Avant la bascule: utiliser l'enveloppe théorique
            // mais si les dépenses dépassent l'enveloppe, utiliser le montant réel
            return max(card.monthlyBudget, actualTotal)
        } else {
            // Après la bascule: utiliser le montant réel des dépenses
            return actualTotal
        }
    }
    
    /// Calcule l'impact total de toutes les cartes actives sur le budget
    static func calculateTotalBudgetImpact(
        cards: [DeferredCard],
        expenses: [DeferredCardExpense],
        referenceDate: Date = Date()
    ) -> Double {
        cards.filter { $0.isActive }.reduce(0) { total, card in
            total + calculateBudgetImpact(for: card, expenses: expenses, referenceDate: referenceDate)
        }
    }
    
    // MARK: - Expense Management
    
    /// Ajoute une dépense à une carte
    static func addExpense(
        to card: DeferredCard,
        amount: Double,
        description: String?,
        expenseDate: Date = Date(),
        modelContext: ModelContext
    ) {
        let cycle = getCurrentCycle(for: card, referenceDate: expenseDate)
        
        let expense = DeferredCardExpense(
            cardID: card.id,
            amount: amount,
            expenseDate: expenseDate,
            expenseDescription: description,
            cycleStartDate: cycle.start,
            cycleEndDate: cycle.cutoff,
            isSettled: false
        )
        
        modelContext.insert(expense)
        try? modelContext.save()
    }
    
    /// Marque les dépenses d'un cycle comme prélevées
    static func settleExpenses(
        for card: DeferredCard,
        cycleEndDate: Date,
        modelContext: ModelContext
    ) throws {
        let cardID = card.id
        let fetchDescriptor = FetchDescriptor<DeferredCardExpense>()
        
        let allExpenses = try modelContext.fetch(fetchDescriptor)
        let expensesToSettle = allExpenses.filter { expense in
            expense.cardID == cardID &&
            Calendar.current.isDate(expense.cycleEndDate, inSameDayAs: cycleEndDate) &&
            expense.isSettled == false
        }
        
        for expense in expensesToSettle {
            expense.isSettled = true
        }
        try modelContext.save()
    }
    
    // MARK: - Summary
    
    /// Résumé des dépenses d'une carte pour un cycle
    struct CycleSummary {
        let card: DeferredCard
        let cycleStart: Date
        let cycleCutoff: Date
        let debitDate: Date
        let totalExpenses: Double
        let budgetImpact: Double
        let remainingBudget: Double
        let isBeforeCutoff: Bool
        let expenseCount: Int
    }
    
    /// Obtient le résumé du cycle en cours pour une carte
    static func getCycleSummary(
        for card: DeferredCard,
        expenses: [DeferredCardExpense],
        referenceDate: Date = Date()
    ) -> CycleSummary {
        let cycle = getCurrentCycle(for: card, referenceDate: referenceDate)
        let beforeCutoff = isBeforeCutoff(for: card, referenceDate: referenceDate)
        
        let cycleExpenses = expenses.filter { expense in
            expense.cardID == card.id &&
            expense.expenseDate >= cycle.start &&
            expense.expenseDate <= cycle.cutoff &&
            !expense.isSettled
        }
        
        let totalExpenses = cycleExpenses.reduce(0) { $0 + $1.amount }
        let budgetImpact = calculateBudgetImpact(for: card, expenses: expenses, referenceDate: referenceDate)
        let remainingBudget = card.monthlyBudget - totalExpenses
        
        return CycleSummary(
            card: card,
            cycleStart: cycle.start,
            cycleCutoff: cycle.cutoff,
            debitDate: cycle.debit,
            totalExpenses: totalExpenses,
            budgetImpact: budgetImpact,
            remainingBudget: remainingBudget,
            isBeforeCutoff: beforeCutoff,
            expenseCount: cycleExpenses.count
        )
    }
}
