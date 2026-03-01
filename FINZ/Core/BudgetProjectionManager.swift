import Foundation
import SwiftData

@MainActor
struct BudgetProjectionManager {
    static func monthKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year, let month = components.month else {
            return ""
        }
        return String(format: "%04d-%02d", year, month)
    }
    
    static func projectIncomes(for date: Date, modelContext: ModelContext) throws {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: date)
        guard let year = comps.year, let month = comps.month else {
            return
        }
        
        // Compute last day of month
        var lastDay = 31
        if let range = calendar.range(of: .day, in: .month, for: date) {
            lastDay = range.count
        }
        
        let monthKey = Self.monthKey(for: date, calendar: calendar)
        
        // Delete existing BudgetEntryOccurrence objects for this monthKey and kind == "income"
        let fetchDescriptor = FetchDescriptor<BudgetEntryOccurrence>(
            predicate: #Predicate { occurrence in
                occurrence.monthKey == monthKey && occurrence.kind == "income" && occurrence.isManual == false
            }
        )
        
        let existingOccurrences = try modelContext.fetch(fetchDescriptor)
        for obj in existingOccurrences {
            modelContext.delete(obj)
        }
        
        // Fetch all Income objects
        let incomeFetch = FetchDescriptor<Income>()
        let incomes = try modelContext.fetch(incomeFetch)
        
        func parseMonths(from complement: String?) -> [Int] {
            guard let complement = complement else { return [] }
            
            // Try to find "mois=" pattern
            if let moisRange = complement.range(of: #"mois=([0-9,]+)"#, options: .regularExpression) {
                let matchedString = String(complement[moisRange])
                if let equalIndex = matchedString.firstIndex(of: "=") {
                    let csvString = matchedString[matchedString.index(after: equalIndex)...]
                    let parts = csvString.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                    return parts
                }
            }
            return []
        }
        
        func parseDay(from complement: String?) -> Int? {
            guard let complement = complement else { return nil }
            // Try to find "jour=" pattern
            if let jourRange = complement.range(of: #"jour=([0-9]+)"#, options: .regularExpression) {
                let matchedString = String(complement[jourRange])
                if let equalIndex = matchedString.firstIndex(of: "=") {
                    let dayString = matchedString[matchedString.index(after: equalIndex)...]
                    if let day = Int(dayString.trimmingCharacters(in: .whitespaces)) {
                        return day
                    }
                }
            }
            return nil
        }
        
        func clampDay(_ day: Int, year: Int, month: Int, calendar: Calendar) -> Int {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = 1
            
            if let date = calendar.date(from: comps), let range = calendar.range(of: .day, in: .month, for: date) {
                let maxDay = range.count
                return min(max(day, 1), maxDay)
            }
            return max(day, 1)
        }
        
        // Helper to determine if income applies to the month
        func isIncluded(periodicity: String?, monthsCSV: [Int], targetMonth: Int) -> Bool {
            guard let periodicity = periodicity?.lowercased() else {
                return false
            }
            switch periodicity {
            case "mensuel":
                return true
            case "mois spécifiques", "personnaliser":
                return monthsCSV.isEmpty || monthsCSV.contains(targetMonth)
            case "bimestriel", "trimestriel", "semestriel", "annuel", "ponctuel":
                return monthsCSV.contains(targetMonth)
            default:
                return true
            }
        }
        
        for income in incomes {
            let monthsFromCSV = parseMonths(from: income.complement)
            let included = isIncluded(periodicity: income.periodicity, monthsCSV: monthsFromCSV, targetMonth: month)
            
            guard included else { continue }
            
            var dayToUse = Int(income.day)
            if let parsedDay = parseDay(from: income.complement) {
                dayToUse = parsedDay
            }
            dayToUse = clampDay(dayToUse, year: year, month: month, calendar: calendar)
            
            var occurrenceComps = DateComponents()
            occurrenceComps.year = year
            occurrenceComps.month = month
            occurrenceComps.day = dayToUse
            
            guard let occurrenceDate = calendar.date(from: occurrenceComps) else { continue }
            
            let occurrence = BudgetEntryOccurrence(
                date: occurrenceDate,
                amount: income.amount,
                kind: "income",
                title: income.kind,
                monthKey: monthKey,
                isManual: false,
                sourceid: income.id
            )
            
            modelContext.insert(occurrence)
        }
        
        try modelContext.save()
    }
    
    static func projectExpenses(for date: Date, modelContext: ModelContext) throws {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: date)
        guard let year = comps.year, let month = comps.month else {
            return
        }
        
        let monthKey = Self.monthKey(for: date, calendar: calendar)
        
        // Delete existing expense occurrences
        let fetchDescriptor = FetchDescriptor<BudgetEntryOccurrence>(
            predicate: #Predicate { occurrence in
                occurrence.monthKey == monthKey && occurrence.kind == "expense" && occurrence.isManual == false
            }
        )
        
        let existingOccurrences = try modelContext.fetch(fetchDescriptor)
        for obj in existingOccurrences {
            modelContext.delete(obj)
        }
        
        // Fetch all Expense objects
        let expenseFetch = FetchDescriptor<Expense>()
        let expenses = try modelContext.fetch(expenseFetch)
        
        func parseMonths(from months: String?) -> [Int] {
            guard let months = months else { return [] }
            return months.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }
        
        func clampDay(_ day: Int, year: Int, month: Int, calendar: Calendar) -> Int {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = 1
            
            if let date = calendar.date(from: comps), let range = calendar.range(of: .day, in: .month, for: date) {
                let maxDay = range.count
                return min(max(day, 1), maxDay)
            }
            return max(day, 1)
        }
        
        func isIncluded(periodicity: String?, monthsCSV: [Int], targetMonth: Int) -> Bool {
            guard let periodicity = periodicity?.lowercased() else {
                return false
            }
            switch periodicity {
            case "mensuel":
                return true
            case "mois spécifiques", "personnaliser":
                return monthsCSV.isEmpty || monthsCSV.contains(targetMonth)
            case "bimestriel", "trimestriel", "semestriel", "annuel", "ponctuel":
                return monthsCSV.contains(targetMonth)
            default:
                return true
            }
        }
        
        for expense in expenses {
            let monthsFromCSV = parseMonths(from: expense.months)
            let included = isIncluded(periodicity: expense.periodicity, monthsCSV: monthsFromCSV, targetMonth: month)
            
            guard included else { continue }
            
            // Check endDate if provided
            if let endDate = expense.endDate, date > endDate {
                continue
            }
            
            let dayToUse = clampDay(Int(expense.day), year: year, month: month, calendar: calendar)
            
            var occurrenceComps = DateComponents()
            occurrenceComps.year = year
            occurrenceComps.month = month
            occurrenceComps.day = dayToUse
            
            guard let occurrenceDate = calendar.date(from: occurrenceComps) else { continue }
            
            let title = [expense.kind, expense.provider].compactMap { $0 }.joined(separator: " - ")
            
            let occurrence = BudgetEntryOccurrence(
                date: occurrenceDate,
                amount: -abs(expense.amount),
                kind: "expense",
                title: title.isEmpty ? "Dépense" : title,
                monthKey: monthKey,
                isManual: false,
                sourceid: expense.id
            )
            
            modelContext.insert(occurrence)
        }
        
        try modelContext.save()
    }
    
    static func getInitialBalance(for monthKey: String, modelContext: ModelContext) throws -> Double {
        let fetchDescriptor = FetchDescriptor<BudgetEntryOccurrence>(
            predicate: #Predicate { occurrence in
                occurrence.monthKey == monthKey && occurrence.kind == "balance"
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        let balances = try modelContext.fetch(fetchDescriptor)
        return balances.first?.amount ?? 0.0
    }
    
    static func getTotalIncomes(for monthKey: String, modelContext: ModelContext) throws -> Double {
        let fetchDescriptor = FetchDescriptor<BudgetEntryOccurrence>(
            predicate: #Predicate { occurrence in
                occurrence.monthKey == monthKey && occurrence.kind == "income"
            }
        )
        
        let incomes = try modelContext.fetch(fetchDescriptor)
        return incomes.reduce(0.0) { $0 + $1.amount }
    }
    
    static func getTotalExpenses(for monthKey: String, modelContext: ModelContext) throws -> Double {
        let fetchDescriptor = FetchDescriptor<BudgetEntryOccurrence>(
            predicate: #Predicate { occurrence in
                occurrence.monthKey == monthKey && occurrence.kind == "expense"
            }
        )
        
        let expenses = try modelContext.fetch(fetchDescriptor)
        return expenses.reduce(0.0) { $0 + abs($1.amount) }
    }
}
