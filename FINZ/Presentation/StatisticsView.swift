import SwiftUI
import SwiftData
import Charts

// MARK: - StatisticsView

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext

    // MARK: Data models
    struct CategorySlice: Identifiable, Equatable {
        let id = UUID()
        let label: String
        let value: Double
        var icon: String = ""
        var color: String = ""
        var mainCategoryID: UUID? = nil
    }

    // MARK: FINZ palette
    private let finzColors: [Color] = [
        Color(red: 0.52, green: 0.21, blue: 0.93),
        Color(red: 1.00, green: 0.29, blue: 0.63),
        Color(red: 0.12, green: 0.47, blue: 0.98),
        Color(red: 0.13, green: 0.78, blue: 0.72),
        Color(red: 0.99, green: 0.74, blue: 0.11),
        Color(red: 0.36, green: 0.56, blue: 1.00),
        Color(red: 0.95, green: 0.45, blue: 0.25),
        Color(red: 0.42, green: 0.80, blue: 0.35),
        Color(red: 0.75, green: 0.35, blue: 0.95),
    ]
    private let finzPurple = Color(red: 0.52, green: 0.21, blue: 0.93)
    private let finzPink = Color(red: 1.00, green: 0.29, blue: 0.63)
    private let finzGradient = LinearGradient(
        colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
        startPoint: .leading, endPoint: .trailing
    )

    static func colorFromHex(_ hex: String) -> Color {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return .gray }
        return Color(red: Double((val >> 16) & 0xFF)/255, green: Double((val >> 8) & 0xFF)/255, blue: Double(val & 0xFF)/255)
    }

    private func sliceColor(for slice: CategorySlice, at index: Int) -> Color {
        if !slice.color.isEmpty { return Self.colorFromHex(slice.color) }
        return finzColors[index % finzColors.count]
    }

    private func total(_ slices: [CategorySlice]) -> Double {
        slices.reduce(0) { $0 + $1.value }
    }

    private func percent(_ value: Double, of total: Double) -> String {
        guard total > 0, value.isFinite, total.isFinite else { return "0%" }
        let p = (value / total) * 100
        guard p.isFinite else { return "0%" }
        return String(format: "%.0f%%", p)
    }

    private func safeInt(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        return Int(value)
    }

    // MARK: Formatters
    private let monthFmt: DateFormatter = {
        let df = DateFormatter(); df.locale = Locale(identifier: "fr_FR"); df.dateFormat = "LLLL yyyy"; return df
    }()
    private let weekFmt: DateFormatter = {
        let df = DateFormatter(); df.locale = Locale(identifier: "fr_FR"); df.dateFormat = "d MMM"; return df
    }()
    private let yearFmt: DateFormatter = {
        let df = DateFormatter(); df.locale = Locale(identifier: "fr_FR"); df.dateFormat = "yyyy"; return df
    }()

    private func range(for period: Period, anchoredAt date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        switch period {
        case .week:
            let s = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
            return (s, cal.date(byAdding: .weekOfYear, value: 1, to: s) ?? date)
        case .month:
            let s = cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
            return (s, cal.date(byAdding: .month, value: 1, to: s) ?? date)
        case .year:
            let s = cal.date(from: cal.dateComponents([.year], from: date)) ?? date
            return (s, cal.date(byAdding: .year, value: 1, to: s) ?? date)
        }
    }

    // MARK: Period
    enum Period: String, CaseIterable, Identifiable {
        case week = "Semaine", month = "Mois", year = "Année"
        var id: String { rawValue }
        var shortLabel: String {
            switch self { case .week: return "Sem."; case .month: return "Mois"; case .year: return "Année" }
        }
    }

    // MARK: State
    @State private var selectedPeriod: Period = .month
    @State private var incomeSlices: [CategorySlice] = []
    @State private var expenseSlices: [CategorySlice] = []
    @State private var periodOptions: [Date] = []
    @State private var selectedDate: Date = Date()
    @State private var drillDownKind: String = "expense"
    @State private var drillDownSubSlices: [CategorySlice] = []
    @State private var drillDownItem: CategorySlice? = nil
    @State private var selectedExpenseAngle: Double? = nil
    @State private var selectedIncomeAngle: Double? = nil
    @State private var showAnnualReport = false

    // MARK: Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                periodCard
                summaryCard
                distributionCard(
                    title: "Dépenses",
                    icon: "arrow.down.circle.fill",
                    iconColor: finzPink,
                    slices: expenseSlices,
                    kind: "expense",
                    selectedAngle: $selectedExpenseAngle
                )
                distributionCard(
                    title: "Recettes",
                    icon: "arrow.up.circle.fill",
                    iconColor: .green,
                    slices: incomeSlices,
                    kind: "income",
                    selectedAngle: $selectedIncomeAngle
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.04), .purple.opacity(0.04), .pink.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .finzHeader(title: "Statistiques")
        .overlay(alignment: .topTrailing) {
            Button {
                showAnnualReport = true
            } label: {
                ZStack {
                    Circle()
                        .fill(finzGradient)
                        .frame(width: 38, height: 38)
                        .shadow(color: finzPurple.opacity(0.3), radius: 6, x: 0, y: 3)
                    Image(systemName: "list.clipboard")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 14)
            .padding(.trailing, 16)
        }
        .onAppear {
            preparePeriodOptions()
            if !periodOptions.contains(selectedDate), let last = periodOptions.last {
                selectedDate = last
            }
            loadData()
        }
        .onChange(of: selectedDate) { loadData() }
        .onChange(of: selectedExpenseAngle) { _, newValue in
            handleChartTap(angle: newValue, slices: expenseSlices, kind: "expense")
            selectedExpenseAngle = nil
        }
        .onChange(of: selectedIncomeAngle) { _, newValue in
            handleChartTap(angle: newValue, slices: incomeSlices, kind: "income")
            selectedIncomeAngle = nil
        }
        .sheet(item: $drillDownItem) { cat in
            CategoryDrillDownSheet(
                categorySlice: cat,
                kind: drillDownKind,
                subSlices: drillDownSubSlices,
                color: !cat.color.isEmpty ? Self.colorFromHex(cat.color) : finzPurple,
                finzColors: finzColors
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showAnnualReport) {
            AnnualBudgetReportView()
        }
    }

    // MARK: - Period Card
    private var periodCard: some View {
        VStack(spacing: 0) {
            // Tabs horizontaux
            HStack(spacing: 0) {
                ForEach(Period.allCases) { p in
                    Button {
                        // Pas de withAnimation — Charts crashe en interpolant les SectorMark
                        selectedPeriod = p
                        preparePeriodOptions()
                        loadData()
                    } label: {
                        Text(p.shortLabel)
                            .font(.system(size: 14, weight: selectedPeriod == p ? .bold : .medium, design: .rounded))
                            .foregroundStyle(selectedPeriod == p ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedPeriod == p
                                ? AnyShapeStyle(finzGradient)
                                : AnyShapeStyle(Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.bottom, 10)

            // Capsules de période
            HStack(spacing: 8) {
                ForEach(periodOptions, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(
                        date, equalTo: selectedDate,
                        toGranularity: granularity(for: selectedPeriod)
                    )
                    Button {
                        selectedDate = date
                    } label: {
                        Text(periodLabel(for: date))
                            .font(.system(size: 13, weight: isSelected ? .bold : .regular, design: .rounded))
                            .foregroundStyle(isSelected ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                isSelected
                                ? AnyShapeStyle(finzGradient)
                                : AnyShapeStyle(Color(.tertiarySystemBackground))
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        let totalIn = total(incomeSlices)
        let totalOut = total(expenseSlices)
        let balance = totalIn - totalOut

        return HStack(spacing: 0) {
            // Recettes
            VStack(spacing: 6) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("\(safeInt(totalIn)) €")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("Recettes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Solde central
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(finzGradient)
                        .frame(width: 56, height: 56)
                    VStack(spacing: 0) {
                        Text("\(safeInt(balance))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("€")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                Text("Solde")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Dépenses
            VStack(spacing: 6) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(finzPink)
                Text("\(safeInt(totalOut)) €")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("Dépenses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Distribution Card (dépenses ou recettes)
    private func distributionCard(
        title: String, icon: String, iconColor: Color,
        slices: [CategorySlice], kind: String,
        selectedAngle: Binding<Double?>
    ) -> some View {
        // Filtrer les slices à valeur 0 ou non-finie pour éviter les crashes Charts
        let validSlices = slices.filter { $0.value > 0 && $0.value.isFinite }
        let t = total(validSlices)

        return VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(safeInt(t)) €")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if validSlices.isEmpty || t <= 0 {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 36))
                            .foregroundStyle(.tertiary)
                        Text("Aucune donnée")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
            } else {
                // Donut chart — use id to force recreation (avoids Charts animation crash)
                let chartID = validSlices.map { $0.label }.joined(separator: ",")
                ZStack {
                    Chart(validSlices) { slice in
                        SectorMark(
                            angle: .value("Montant", slice.value),
                            innerRadius: .ratio(0.65),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("Cat", slice.label))
                        .cornerRadius(3)
                    }
                    .chartForegroundStyleScale(
                        domain: validSlices.map(\.label),
                        range: validSlices.enumerated().map { sliceColor(for: $1, at: $0) }
                    )
                    .chartLegend(.hidden)
                    .chartAngleSelection(value: selectedAngle)
                    .frame(height: 200)
                    .id(chartID)

                    VStack(spacing: 2) {
                        Text("Total")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("\(safeInt(t)) €")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .allowsHitTesting(false)
                }

                // Légende cliquable
                VStack(spacing: 4) {
                    ForEach(Array(validSlices.enumerated()), id: \.element.id) { idx, s in
                        Button {
                            if s.mainCategoryID != nil {
                                drillDownSubSlices = fetchSubSlices(for: s, kind: kind)
                                drillDownKind = kind
                                // Set item LAST to trigger sheet after data is ready
                                drillDownItem = s
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if !s.icon.isEmpty {
                                    Text(s.icon)
                                        .font(.system(size: 18))
                                        .frame(width: 30, height: 30)
                                        .background(sliceColor(for: s, at: idx).opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                } else {
                                    Circle()
                                        .fill(sliceColor(for: s, at: idx))
                                        .frame(width: 10, height: 10)
                                }

                                Text(s.label)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Spacer()

                                Text("\(safeInt(s.value)) €")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)

                                Text(percent(s.value, of: t))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36, alignment: .trailing)

                                if s.mainCategoryID != nil {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(Color(.tertiarySystemBackground).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Chart Tap Handling

    private func handleChartTap(angle: Double?, slices: [CategorySlice], kind: String) {
        guard let angle = angle else { return }
        let validSlices = slices.filter { $0.value > 0 && $0.value.isFinite }
        var cumulative: Double = 0
        for s in validSlices {
            cumulative += s.value
            if angle <= cumulative, s.mainCategoryID != nil {
                drillDownSubSlices = fetchSubSlices(for: s, kind: kind)
                drillDownKind = kind
                drillDownItem = s
                return
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() {
        incomeSlices = []
        expenseSlices = []
        let result = fetchSlicesFromOccurrences(for: selectedDate, period: selectedPeriod)
        incomeSlices = result.incomes
        expenseSlices = result.expenses
    }

    private func preparePeriodOptions() {
        var dates: [Date] = []
        let cal = Calendar.current
        let now = Date()
        switch selectedPeriod {
        case .week:
            for offset in -2...0 {
                if let d = cal.date(byAdding: .weekOfYear, value: offset, to: now) {
                    dates.append(cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: d)) ?? d)
                }
            }
        case .month:
            for offset in -2...0 {
                if let d = cal.date(byAdding: .month, value: offset, to: now),
                   let first = cal.date(from: cal.dateComponents([.year, .month], from: d)) {
                    dates.append(first)
                }
            }
        case .year:
            for offset in -2...0 {
                if let d = cal.date(byAdding: .year, value: offset, to: now),
                   let first = cal.date(from: cal.dateComponents([.year], from: d)) {
                    dates.append(first)
                }
            }
        }
        periodOptions = dates
        selectedDate = range(for: selectedPeriod, anchoredAt: now).start
    }

    private func periodLabel(for date: Date) -> String {
        switch selectedPeriod {
        case .week:
            let r = range(for: .week, anchoredAt: date)
            return "\(weekFmt.string(from: r.start)) – \(weekFmt.string(from: r.end))"
        case .month:
            return monthFmt.string(from: date).capitalized
        case .year:
            return yearFmt.string(from: date)
        }
    }

    private func granularity(for period: Period) -> Calendar.Component {
        switch period {
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
    }

    // MARK: - Fetch grouped by MainCategory
    private func fetchSlicesFromOccurrences(
        for anchor: Date, period: Period
    ) -> (incomes: [CategorySlice], expenses: [CategorySlice]) {
        let r = range(for: period, anchoredAt: anchor)
        let startOfRange = r.start
        let endOfRange = r.end

        let fetchDescriptor = FetchDescriptor<BudgetEntryOccurrence>(
            predicate: #Predicate { occ in
                occ.date >= startOfRange && occ.date < endOfRange && occ.kind != "balance"
            }
        )

        let mainCats: [UUID: MainCategory] = {
            guard let cats = try? modelContext.fetch(FetchDescriptor<MainCategory>()) else { return [:] }
            return Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })
        }()
        let subCats: [UUID: SubCategory] = {
            guard let subs = try? modelContext.fetch(FetchDescriptor<SubCategory>()) else { return [:] }
            return Dictionary(uniqueKeysWithValues: subs.map { ($0.id, $0) })
        }()

        do {
            let objs = try modelContext.fetch(fetchDescriptor)
            var incomeTotals: [UUID: Double] = [:]
            var expenseTotals: [UUID: Double] = [:]
            var incomeOther: Double = 0
            var expenseOther: Double = 0

            for obj in objs {
                let amount = obj.amount
                guard amount.isFinite else { continue }

                // Résoudre la catégorie principale
                var resolvedMainID: UUID? = obj.mainCategoryID
                if resolvedMainID == nil,
                   let subID = obj.subCategoryID,
                   let sub = subCats[subID] {
                    resolvedMainID = sub.mainCategory?.id
                }

                if obj.kind == "income" {
                    let val = max(0, amount)
                    if let mid = resolvedMainID { incomeTotals[mid, default: 0] += val }
                    else { incomeOther += val }
                } else {
                    let val = abs(amount)
                    if let mid = resolvedMainID { expenseTotals[mid, default: 0] += val }
                    else { expenseOther += val }
                }
            }

            func buildSlices(_ totals: [UUID: Double], other: Double) -> [CategorySlice] {
                var slices = totals.compactMap { (id, value) -> CategorySlice? in
                    guard value > 0, value.isFinite, let cat = mainCats[id] else { return nil }
                    return CategorySlice(
                        label: cat.displayName, value: value,
                        icon: cat.icon, color: cat.color,
                        mainCategoryID: id
                    )
                }.sorted { $0.value > $1.value }
                if other > 0, other.isFinite, other.isFinite {
                    slices.append(CategorySlice(label: "Autre", value: other, icon: "❓", color: ""))
                }
                return slices
            }

            return (
                incomes: buildSlices(incomeTotals, other: incomeOther),
                expenses: buildSlices(expenseTotals, other: expenseOther)
            )
        } catch {
            return ([], [])
        }
    }

    // MARK: - Fetch sous-catégories pour drill-down
    private func fetchSubSlices(for categorySlice: CategorySlice, kind: String) -> [CategorySlice] {
        guard let mainID = categorySlice.mainCategoryID else { return [] }

        let r = range(for: selectedPeriod, anchoredAt: selectedDate)
        let startOfRange = r.start
        let endOfRange = r.end
        let targetKind = kind

        let fetchDescriptor = FetchDescriptor<BudgetEntryOccurrence>(
            predicate: #Predicate { occ in
                occ.date >= startOfRange && occ.date < endOfRange && occ.kind == targetKind
            }
        )

        let subCats: [UUID: SubCategory] = {
            guard let subs = try? modelContext.fetch(FetchDescriptor<SubCategory>()) else { return [:] }
            return Dictionary(uniqueKeysWithValues: subs.map { ($0.id, $0) })
        }()

        do {
            let objs = try modelContext.fetch(fetchDescriptor)
            var subTotals: [UUID: Double] = [:]
            var noSubTotal: Double = 0

            for obj in objs {
                var resolvedMainID: UUID? = obj.mainCategoryID
                if resolvedMainID == nil,
                   let subID = obj.subCategoryID,
                   let sub = subCats[subID] {
                    resolvedMainID = sub.mainCategory?.id
                }
                guard resolvedMainID == mainID else { continue }

                let val = kind == "income" ? max(0, obj.amount) : abs(obj.amount)
                if let subID = obj.subCategoryID {
                    subTotals[subID, default: 0] += val
                } else {
                    noSubTotal += val
                }
            }

            var slices = subTotals.compactMap { (id, value) -> CategorySlice? in
                guard value > 0, value.isFinite, let sub = subCats[id] else { return nil }
                return CategorySlice(label: sub.displayName, value: value, icon: sub.icon, color: "")
            }.sorted { $0.value > $1.value }

            if noSubTotal > 0, noSubTotal.isFinite {
                slices.append(CategorySlice(label: "Non catégorisé", value: noSubTotal, icon: "—", color: ""))
            }
            return slices
        } catch {
            return []
        }
    }
}

// MARK: - Drill-Down Sheet

struct CategoryDrillDownSheet: View {
    let categorySlice: StatisticsView.CategorySlice
    let kind: String
    let subSlices: [StatisticsView.CategorySlice]
    let color: Color
    let finzColors: [Color]

    @Environment(\.dismiss) private var dismiss

    private var t: Double { subSlices.reduce(0) { $0 + $1.value } }

    private func pct(_ v: Double) -> String {
        guard t > 0 else { return "0%" }
        return String(format: "%.0f%%", (v / t) * 100)
    }

    private func safeInt(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        return Int(value)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header catégorie
                    VStack(spacing: 8) {
                        Text(categorySlice.icon)
                            .font(.system(size: 44))
                        Text(categorySlice.label)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text("\(safeInt(categorySlice.value)) €")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(color)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                    if subSlices.isEmpty || t <= 0 {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 36))
                                .foregroundStyle(.tertiary)
                            Text("Aucun détail disponible")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else {
                        // Donut sous-catégories
                        let validSubs = subSlices.filter { $0.value > 0 && $0.value.isFinite }
                        ZStack {
                            Chart(validSubs) { s in
                                SectorMark(
                                    angle: .value("Montant", s.value),
                                    innerRadius: .ratio(0.60),
                                    angularInset: 2
                                )
                                .foregroundStyle(by: .value("Sub", s.label))
                                .cornerRadius(3)
                            }
                            .chartForegroundStyleScale(
                                domain: validSubs.map(\.label),
                                range: validSubs.indices.map { finzColors[$0 % finzColors.count] }
                            )
                            .chartLegend(.hidden)
                            .frame(height: 180)

                            Text("\(safeInt(t)) €")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .allowsHitTesting(false)
                        }
                        .padding(.horizontal, 16)

                        // Liste détaillée
                        VStack(spacing: 6) {
                            ForEach(Array(subSlices.enumerated()), id: \.element.id) { idx, s in
                                HStack(spacing: 12) {
                                    Text(s.icon.isEmpty ? "•" : s.icon)
                                        .font(.system(size: 18))
                                        .frame(width: 32, height: 32)
                                        .background(finzColors[idx % finzColors.count].opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(s.label)
                                            .font(.system(size: 14, weight: .medium))
                                        Text(pct(s.value))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text("\(safeInt(s.value)) €")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.tertiarySystemBackground).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    StatisticsView()
}
