import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext

    private struct Slice: Identifiable, Equatable {
        let id = UUID()
        let label: String
        let value: Double
    }
    
    // FINZ palette and helpers
    private let finzColors: [Color] = [
        Color(red: 0.12, green: 0.47, blue: 0.98), // FINZ Blue
        Color(red: 0.52, green: 0.21, blue: 0.93), // FINZ Purple
        Color(red: 1.00, green: 0.29, blue: 0.63), // FINZ Pink
        Color(red: 0.13, green: 0.78, blue: 0.72), // FINZ Teal
        Color(red: 0.99, green: 0.74, blue: 0.11), // FINZ Amber
        Color(red: 0.36, green: 0.56, blue: 1.00)  // FINZ Indigo/Blue mix
    ]

    private func finzGradient(_ intensity: Double = 0.10) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.47, blue: 0.98).opacity(intensity),
                Color(red: 0.52, green: 0.21, blue: 0.93).opacity(intensity),
                Color(red: 1.00, green: 0.29, blue: 0.63).opacity(intensity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func total(_ slices: [Slice]) -> Double {
        slices.reduce(0) { $0 + $1.value }
    }

    private func percent(_ value: Double, of total: Double) -> String {
        guard total > 0 else { return "0%" }
        let p = (value / total) * 100
        return String(format: "%.0f%%", p)
    }
    
    private let monthFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "fr_FR")
        df.dateFormat = "LLLL yyyy"
        return df
    }()
    
    private let weekFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "fr_FR")
        df.dateFormat = "d MMM"
        return df
    }()
    
    private let yearFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "fr_FR")
        df.dateFormat = "yyyy"
        return df
    }()
    
    private func range(for period: Period, anchoredAt date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        switch period {
        case .week:
            let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
            let end = cal.date(byAdding: .weekOfYear, value: 1, to: start) ?? date
            return (start, end)
        case .month:
            let comps = cal.dateComponents([.year, .month], from: date)
            let start = cal.date(from: comps) ?? date
            let end = cal.date(byAdding: .month, value: 1, to: start) ?? date
            return (start, end)
        case .year:
            let comps = cal.dateComponents([.year], from: date)
            let start = cal.date(from: comps) ?? date
            let end = cal.date(byAdding: .year, value: 1, to: start) ?? date
            return (start, end)
        }
    }
    
    private enum Period: String, CaseIterable, Identifiable { case week = "Semaine", month = "Mois", year = "Année"; var id: String { rawValue } }
    @State private var selectedPeriod: Period = .month

    @State private var incomeSlices: [Slice] = []
    @State private var expenseSlices: [Slice] = []
    @State private var periodOptions: [Date] = []
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationStack {
            mainContent // Appel de la propriété calculée pour tout le contenu principal
        }
        .navigationBarTitleDisplayMode(.inline) // Déplacé ici
        .onAppear { // Déplacé ici
            preparePeriodOptions()
            if !periodOptions.contains(selectedDate), let last = periodOptions.last {
                selectedDate = last
            }
            loadData()
        }
        .onChange(of: selectedDate) { _ in // Déplacé ici
            loadData()
        }
        .finzHeader() // Déplacé ici
    }

    // MARK: - Extracted Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Statistiques")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(white: 0.1))
                        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    Spacer(minLength: 0)
                }
                .padding(.top, 8)
                
                // Period selection card
                periodSelectionCard
                
                // Account summary card
                accountSummaryCard
                
                // Expense distribution card
                expenseDistributionCard

                // Income distribution card
                incomeDistributionCard
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(
            finzGradient(0.06)
                .ignoresSafeArea()
        )
    }

    // MARK: - Extracted Subviews/Properties for Dashboard Cards
    private var periodSelectionCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Période")
                    .font(.headline)
                // Period wheel picker (liste roulante)
                Picker("Période", selection: $selectedPeriod) {
                    ForEach(Period.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 110)
                .clipped()
                .onChange(of: selectedPeriod) { _ in
                    preparePeriodOptions()
                    loadData()
                }

                if !periodOptions.isEmpty {
                    Picker("Période", selection: $selectedDate) {
                        ForEach(periodOptions, id: \.self) { date in
                            switch selectedPeriod {
                            case .week:
                                let r = range(for: .week, anchoredAt: date)
                                Text("Semaine du \(weekFormatter.string(from: r.start))")
                                    .tag(date)
                            case .month:
                                Text(monthFormatter.string(from: date).capitalized)
                                    .tag(date)
                            case .year:
                                Text(yearFormatter.string(from: date))
                                    .tag(date)
                            }
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 110)
                    .clipped()
                } else {
                    ProgressView()
                        .frame(height: 110)
                }
            }
        }
        .padding(.horizontal)
    }

    private var accountSummaryCard: some View {
        DashboardCard {
            HStack(alignment: .center, spacing: 12) {
                // Déclaration des variables ici, maintenant dans le scope de cette propriété
                let totalIncome = total(incomeSlices)
                let totalExpense = total(expenseSlices)
                let balance = totalIncome - totalExpense

                // Calculate combinedSlices here, outside the ZStack ViewBuilder context
                let combinedSlices: [Slice] = {
                    if totalIncome == 0 && totalExpense == 0 {
                        return [Slice(label: "Aucune donnée", value: 1)] // Fallback si pas de données
                    } else {
                        return [
                            Slice(label: "Recettes", value: totalIncome),
                            Slice(label: "Dépenses", value: totalExpense)
                        ].filter { $0.value > 0 } // N'affiche que les slices avec des valeurs positives
                    }
                }() // Immediately invoke the closure to get the value

                VStack(alignment: .leading, spacing: 8) {
                    Text("Votre compte")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)

                    // Supprimé : HStack avec le solde à gauche
                    // HStack(spacing: 4) {
                    //     Text("Solde")
                    //     Spacer()
                    //     Text("\(Int(balance)) €")
                    //         .font(.title2).bold()
                    //         .foregroundStyle(balance >= 0 ? finzColors[3] : finzColors[2])
                    // }
                    // .font(.callout)

                    Divider() // Conservé pour séparer "Votre compte" des recettes/dépenses

                    HStack(spacing: 4) {
                        Text("Recettes")
                        Spacer()
                        Text("\(Int(totalIncome)) €")
                            .font(.subheadline).bold()
                            .foregroundStyle(finzColors[1]) // FINZ Purple
                    }
                    .font(.callout)

                    HStack(spacing: 4) {
                        Text("Dépenses")
                        Spacer()
                        Text("\(Int(totalExpense)) €")
                            .font(.subheadline).bold()
                            .foregroundStyle(finzColors[2]) // FINZ Pink
                    }
                    .font(.callout)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Donut chart pour Recettes vs Dépenses avec Solde au centre
                ZStack {
                    Chart(combinedSlices) { slice in
                        SectorMark(
                            angle: .value("Montant", slice.value),
                            innerRadius: .ratio(0.68),
                            angularInset: 2.0
                        )
                        .foregroundStyle(by: .value("Catégorie", slice.label))
                        .cornerRadius(2)
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
                    }
                    .chartForegroundStyleScale( // Fixed: Using domain:range for explicit type inference
                        domain: ["Recettes", "Dépenses", "Aucune donnée"],
                        range: [finzColors[1], finzColors[2], Color.gray.opacity(0.4)]
                    )
                    .chartLegend(.hidden)
                    .frame(width: 170, height: 170)

                    // Texte central du solde (conservé)
                    VStack(spacing: 4) {
                        Text("Solde")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(balance)) €")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(balance >= 0 ? finzColors[3] : finzColors[2]) // Teal for positive, Pink for negative
                    }
                    .allowsHitTesting(false) // Permet d'interagir avec le graphique si nécessaire
                }
            }
        }
        .padding(.horizontal)
    }

    private var expenseDistributionCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Répartition des dépenses")
                    .font(.headline)

                let totalExpense = total(expenseSlices)
                if expenseSlices.isEmpty {
                    Text("Aucune donnée pour ce mois.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    ZStack {
                        Chart(expenseSlices) { slice in
                            SectorMark(
                                angle: .value("Montant", slice.value),
                                innerRadius: .ratio(0.68),
                                angularInset: 2.0
                            )
                            .foregroundStyle(by: .value("Catégorie", slice.label))
                            .cornerRadius(2)
                            .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
                        }
                        .chartForegroundStyleScale(range: finzColors)
                        .chartLegend(.hidden)
                        .frame(height: 240)

                        Text("\(Int(totalExpense)) €")
                            .font(.title2).bold()
                            .foregroundStyle(.primary)
                            .allowsHitTesting(false)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(expenseSlices.enumerated()), id: \.offset) { idx, s in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(finzColors[idx % finzColors.count])
                                .frame(width: 10, height: 10)
                            Text(s.label)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Text("\(percent(s.value, of: totalExpense)) • \(Int(s.value)) €")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }

    private var incomeDistributionCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Text("Répartition des recettes")
                        .font(.headline)
                    Text("🧾")
                }
                let totalIncome = total(incomeSlices)
                if incomeSlices.isEmpty {
                    Text("Aucune donnée pour ce mois.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    Chart(incomeSlices) { slice in
                        BarMark(
                            x: .value("Catégorie", slice.label),
                            y: .value("Montant", slice.value)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(6)
                        .annotation(position: .top) {
                            Text("\(Int(slice.value))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 220)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(incomeSlices.enumerated()), id: \.offset) { idx, s in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(finzColors[idx % finzColors.count])
                                .frame(width: 10, height: 10)
                            Text(s.label)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Text("\(percent(s.value, of: totalIncome)) • \(Int(s.value)) €")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }

    private func loadData() {
        let result = fetchSlicesFromOccurrences(for: selectedDate, period: selectedPeriod)
        incomeSlices = result.incomes
        expenseSlices = topNGrouped(result.expenses, limit: 8)
    }
    
    private func topNGrouped(_ slices: [Slice], limit: Int) -> [Slice] {
        guard slices.count > limit else { return slices }
        let top = Array(slices.prefix(limit))
        let otherTotal = slices.dropFirst(limit).reduce(0) { $0 + $1.value }
        guard otherTotal > 0 else { return top }
        return top + [Slice(label: "Autre", value: otherTotal)]
    }
    
    private func preparePeriodOptions() {
        var dates: [Date] = []
        let cal = Calendar.current
        let now = Date()
        switch selectedPeriod {
        case .week:
            if let start = cal.date(byAdding: .weekOfYear, value: -11, to: now) {
                for offset in 0...11 {
                    if let d = cal.date(byAdding: .weekOfYear, value: offset, to: start) {
                        let normalized = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: d)) ?? d
                        dates.append(normalized)
                    }
                }
            }
        case .month:
            if let start = cal.date(byAdding: .month, value: -11, to: now) {
                for offset in 0...11 {
                    if let d = cal.date(byAdding: .month, value: offset, to: start) {
                        let comps = cal.dateComponents([.year, .month], from: d)
                        if let first = cal.date(from: comps) { dates.append(first) }
                    }
                }
            }
        case .year:
            if let start = cal.date(byAdding: .year, value: -3, to: now) {
                for offset in 0...3 {
                    if let d = cal.date(byAdding: .year, value: offset, to: start) {
                        let comps = cal.dateComponents([.year], from: d)
                        if let first = cal.date(from: comps) { dates.append(first) }
                    }
                }
            }
        }
        periodOptions = dates
        // Snap selectedDate to start of its period
        let snapped = range(for: selectedPeriod, anchoredAt: now).start
        selectedDate = snapped
    }

    private func fetchSlicesFromOccurrences(for anchor: Date, period: Period) -> (incomes: [Slice], expenses: [Slice]) {
        let r = range(for: period, anchoredAt: anchor)
        let startOfRange = r.start
        let endOfRange = r.end
        
        let fetchDescriptor = FetchDescriptor<BudgetEntryOccurrence>(
            predicate: #Predicate { occurrence in
                occurrence.date >= startOfRange && occurrence.date < endOfRange && occurrence.kind != "balance"
            }
        )
        
        do {
            let objs = try modelContext.fetch(fetchDescriptor)
            var incomeTotals: [String: Double] = [:]
            var expenseTotals: [String: Double] = [:]
            
            for obj in objs {
                let kind = obj.kind
                let rawTitle = obj.title ?? "Autre"
                let category = rawTitle.split(separator: "—").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? rawTitle
                let amount = obj.amount
                guard amount.isFinite else { continue }
                
                if kind == "income" {
                    incomeTotals[category, default: 0] += max(0, amount)
                } else {
                    expenseTotals[category, default: 0] += abs(amount)
                }
            }
            
            let incomes = incomeTotals.filter { $0.value > 0 }.sorted { $0.value > $1.value }.map { Slice(label: $0.key, value: $0.value) }
            let expenses = expenseTotals.filter { $0.value > 0 }.sorted { $0.value > $1.value }.map { Slice(label: $0.key, value: $0.value) }
            return (incomes, expenses)
        } catch {
            return ([], [])
        }
    }
}

#Preview {
    StatisticsView()
}

