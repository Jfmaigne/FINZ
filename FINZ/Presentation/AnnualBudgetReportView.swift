import SwiftUI
import SwiftData

// MARK: - Data Models

struct ReportSubCategoryRow: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    var amounts: [Double] // 12 mois
    var total: Double { amounts.reduce(0, +) }
}

struct ReportCategorySection: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: String
    var subCategories: [ReportSubCategoryRow]
    var monthTotals: [Double] {
        (0..<12).map { m in subCategories.reduce(0) { $0 + $1.amounts[m] } }
    }
    var grandTotal: Double { subCategories.reduce(0) { $0 + $1.total } }
}

struct AnnualReportData {
    let year: Int
    var incomeCategories: [ReportCategorySection]
    var expenseCategories: [ReportCategorySection]
    var monthlyBalanceStart: [Double] // solde début de chaque mois
    
    var monthlyIncomes: [Double] {
        (0..<12).map { m in incomeCategories.reduce(0) { $0 + $1.monthTotals[m] } }
    }
    var monthlyExpenses: [Double] {
        (0..<12).map { m in expenseCategories.reduce(0) { $0 + $1.monthTotals[m] } }
    }
    var monthlyBalance: [Double] {
        (0..<12).map { m in monthlyBalanceStart[m] + monthlyIncomes[m] - monthlyExpenses[m] }
    }
    var totalIncomes: Double { monthlyIncomes.reduce(0, +) }
    var totalExpenses: Double { monthlyExpenses.reduce(0, +) }
}

// MARK: - Main View

struct AnnualBudgetReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var reportData: AnnualReportData?
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var isLoading = true
    @State private var renderedImage: UIImage?
    @State private var showShareSheet = false
    
    private let finzPurple = Color(red: 0.52, green: 0.21, blue: 0.93)
    private let finzPink = Color(red: 1.00, green: 0.29, blue: 0.63)
    private let finzGradient = LinearGradient(
        colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
        startPoint: .leading, endPoint: .trailing
    )
    
    private let shortMonths = ["Jan", "Fév", "Mar", "Avr", "Mai", "Jun", "Jul", "Aoû", "Sep", "Oct", "Nov", "Déc"]
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Génération du rapport...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let data = reportData {
                    reportContent(data: data)
                } else {
                    Text("Aucune donnée disponible")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 12) {
                        Button { selectedYear -= 1; loadReport() } label: {
                            Image(systemName: "chevron.left")
                                .font(.caption.bold())
                        }
                        Text("Budget \(String(selectedYear))")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Button { selectedYear += 1; loadReport() } label: {
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        generateShareImage()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = renderedImage {
                    ActivityView(activityItems: [image])
                }
            }
        }
        .onAppear { loadReport() }
    }
    
    // MARK: - Report Content
    
    @ViewBuilder
    private func reportContent(data: AnnualReportData) -> some View {
        ScrollView(.horizontal, showsIndicators: true) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    reportHeader(data: data)
                    monthHeaderRow()
                    
                    // Solde initial
                    balanceRow(label: "💰 Solde initial", amounts: data.monthlyBalanceStart, color: finzPurple)
                    
                    sectionDivider(title: "RECETTES", icon: "arrow.up.circle.fill", color: .green)
                    
                    ForEach(data.incomeCategories) { cat in
                        categoryBlock(cat: cat, tintColor: .green)
                    }
                    
                    totalRow(label: "Total Recettes", amounts: data.monthlyIncomes, total: data.totalIncomes, color: .green)
                    
                    sectionDivider(title: "DÉPENSES", icon: "arrow.down.circle.fill", color: finzPink)
                    
                    ForEach(data.expenseCategories) { cat in
                        categoryBlock(cat: cat, tintColor: finzPink)
                    }
                    
                    totalRow(label: "Total Dépenses", amounts: data.monthlyExpenses, total: data.totalExpenses, color: finzPink)
                    
                    sectionDivider(title: "SOLDE", icon: "banknote.fill", color: finzPurple)
                    balanceRow(label: "📊 Solde fin de mois", amounts: data.monthlyBalance, color: finzPurple)
                }
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Header
    
    private func reportHeader(data: AnnualReportData) -> some View {
        HStack {
            Image("finz_logo_couleur")
                .resizable()
                .scaledToFit()
                .frame(height: 36)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Rapport Budget Annuel")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(String(data.year))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    // MARK: - Month Header
    
    private func monthHeaderRow() -> some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: 160, alignment: .leading)
                .padding(.horizontal, 8)
            
            ForEach(0..<12, id: \.self) { m in
                Text(shortMonths[m])
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 72)
            }
            
            Text("Total")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 80)
        }
        .padding(.vertical, 8)
        .background(finzGradient)
    }
    
    // MARK: - Section Divider
    
    private func sectionDivider(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
    }
    
    // MARK: - Category Block
    
    private func categoryBlock(cat: ReportCategorySection, tintColor: Color) -> some View {
        VStack(spacing: 0) {
            // Category header row
            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    Text(cat.icon)
                        .font(.system(size: 13))
                    Text(cat.name)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .frame(width: 160, alignment: .leading)
                .padding(.horizontal, 8)
                
                ForEach(0..<12, id: \.self) { m in
                    let v = cat.monthTotals[m]
                    Text(v > 0 ? formatCompact(v) : "—")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(v > 0 ? .primary : .quaternary)
                        .frame(width: 72)
                }
                
                Text(formatCompact(cat.grandTotal))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(tintColor)
                    .frame(width: 80)
            }
            .padding(.vertical, 6)
            .background(Color(.secondarySystemGroupedBackground).opacity(0.6))
            
            // Sub-category rows
            ForEach(cat.subCategories) { sub in
                subCategoryRow(sub: sub)
            }
        }
    }
    
    @ViewBuilder
    private func subCategoryRow(sub: ReportSubCategoryRow) -> some View {
        if sub.total > 0 {
            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    Text(sub.icon)
                        .font(.system(size: 11))
                    Text(sub.name)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 160, alignment: .leading)
                .padding(.leading, 24)
                .padding(.trailing, 8)
                
                ForEach(Array(0..<12), id: \.self) { (m: Int) in
                    let v = sub.amounts[m]
                    Text(v > 0 ? formatCompact(v) : "")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(v > 0 ? Color.secondary : Color.clear)
                        .frame(width: 72)
                }
                
                Text(formatCompact(sub.total))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 80)
            }
            .padding(.vertical, 4)
            
            Divider().padding(.leading, 24)
        }
    }
    
    // MARK: - Total Row
    
    private func totalRow(label: String, amounts: [Double], total: Double, color: Color) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 160, alignment: .leading)
                .padding(.horizontal, 8)
            
            ForEach(0..<12, id: \.self) { m in
                Text(formatCompact(amounts[m]))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .frame(width: 72)
            }
            
            Text(formatCompact(total))
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 80)
        }
        .padding(.vertical, 8)
        .background(color.opacity(0.06))
    }
    
    // MARK: - Balance Row
    
    private func balanceRow(label: String, amounts: [Double], color: Color) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .frame(width: 160, alignment: .leading)
                .padding(.horizontal, 8)
            
            ForEach(0..<12, id: \.self) { m in
                let v = amounts[m]
                Text(formatCompact(v))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(v >= 0 ? color : .red)
                    .frame(width: 72)
            }
            
            let t = amounts.last ?? 0
            Text(formatCompact(t))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(t >= 0 ? color : .red)
                .frame(width: 80)
        }
        .padding(.vertical, 8)
        .background(color.opacity(0.04))
    }
    
    // MARK: - Formatting
    
    private func formatCompact(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        let abs = Swift.abs(value)
        if abs >= 1000 {
            let k = value / 1000
            return String(format: "%.1fk", k)
        }
        return String(format: "%.0f", value)
    }
    
    // MARK: - Data Loading
    
    private func loadReport() {
        isLoading = true
        
        let cal = Calendar.current
        let year = selectedYear
        
        // Fetch all categories
        let mainCats: [MainCategory] = (try? modelContext.fetch(FetchDescriptor<MainCategory>(
            sortBy: [SortDescriptor(\.order)]
        ))) ?? []
        let subCats: [SubCategory] = (try? modelContext.fetch(FetchDescriptor<SubCategory>(
            sortBy: [SortDescriptor(\.order)]
        ))) ?? []
        
        let subCatByID: [UUID: SubCategory] = Dictionary(
            subCats.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let mainCatByID: [UUID: MainCategory] = Dictionary(
            mainCats.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        
        // Fetch all occurrences for the year
        var yearStart = DateComponents(); yearStart.year = year; yearStart.month = 1; yearStart.day = 1
        var yearEnd = DateComponents(); yearEnd.year = year + 1; yearEnd.month = 1; yearEnd.day = 1
        
        guard let startDate = cal.date(from: yearStart),
              let endDate = cal.date(from: yearEnd) else {
            isLoading = false
            return
        }
        
        let fetchDesc = FetchDescriptor<BudgetEntryOccurrence>(
            predicate: #Predicate { occ in
                occ.date >= startDate && occ.date < endDate
            }
        )
        
        let allOccurrences = (try? modelContext.fetch(fetchDesc)) ?? []
        
        // Build income categories
        let incomeMains = mainCats.filter { $0.categoryType == "income" }
        let expenseMains = mainCats.filter { $0.categoryType == "expense" }
        
        func buildSections(mains: [MainCategory], kind: String) -> [ReportCategorySection] {
            var sections: [ReportCategorySection] = []
            
            for main in mains {
                let mainSubs = subCats.filter { $0.mainCategory?.id == main.id }
                var subRows: [ReportSubCategoryRow] = []
                
                for sub in mainSubs {
                    var amounts = Array(repeating: 0.0, count: 12)
                    for occ in allOccurrences {
                        guard occ.kind == kind else { continue }
                        
                        // Résoudre la catégorie
                        var matchedSubID: UUID?
                        if occ.subCategoryID == sub.id {
                            matchedSubID = sub.id
                        } else if occ.subCategoryID == nil,
                                  occ.mainCategoryID == main.id {
                            // Pas de sous-cat assignée, mais main cat correspond
                            continue // skip, sera dans "non catégorisé" si nécessaire
                        }
                        
                        guard matchedSubID != nil else { continue }
                        
                        let month = cal.component(.month, from: occ.date) - 1
                        guard month >= 0 && month < 12 else { continue }
                        let val = kind == "income" ? max(0, occ.amount) : abs(occ.amount)
                        amounts[month] += val
                    }
                    
                    subRows.append(ReportSubCategoryRow(
                        name: sub.displayName,
                        icon: sub.icon,
                        amounts: amounts
                    ))
                }
                
                // Ajouter les montants sans sous-catégorie
                var uncategorizedAmounts = Array(repeating: 0.0, count: 12)
                for occ in allOccurrences {
                    guard occ.kind == kind else { continue }
                    guard occ.mainCategoryID == main.id, occ.subCategoryID == nil else { continue }
                    
                    let month = cal.component(.month, from: occ.date) - 1
                    guard month >= 0 && month < 12 else { continue }
                    let val = kind == "income" ? max(0, occ.amount) : abs(occ.amount)
                    uncategorizedAmounts[month] += val
                }
                if uncategorizedAmounts.reduce(0, +) > 0 {
                    subRows.append(ReportSubCategoryRow(
                        name: "Autre",
                        icon: "•",
                        amounts: uncategorizedAmounts
                    ))
                }
                
                let section = ReportCategorySection(
                    name: main.displayName,
                    icon: main.icon,
                    color: main.color,
                    subCategories: subRows
                )
                
                if section.grandTotal > 0 {
                    sections.append(section)
                }
            }
            
            return sections
        }
        
        let incomeCategories = buildSections(mains: incomeMains, kind: "income")
        let expenseCategories = buildSections(mains: expenseMains, kind: "expense")
        
        // Compute monthly starting balances
        var monthlyBalanceStart = Array(repeating: 0.0, count: 12)
        
        // Get initial balance for January
        let janKey = String(format: "%04d-01", year)
        let initialBalance = (try? BudgetProjectionManager.getInitialBalance(for: janKey, modelContext: modelContext)) ?? 0.0
        monthlyBalanceStart[0] = initialBalance
        
        // Compute running balance
        let monthlyIn = (0..<12).map { m in incomeCategories.reduce(0.0) { $0 + $1.monthTotals[m] } }
        let monthlyOut = (0..<12).map { m in expenseCategories.reduce(0.0) { $0 + $1.monthTotals[m] } }
        
        for m in 1..<12 {
            monthlyBalanceStart[m] = monthlyBalanceStart[m-1] + monthlyIn[m-1] - monthlyOut[m-1]
        }
        
        reportData = AnnualReportData(
            year: year,
            incomeCategories: incomeCategories,
            expenseCategories: expenseCategories,
            monthlyBalanceStart: monthlyBalanceStart
        )
        
        isLoading = false
    }
    
    // MARK: - Share / Print
    
    @MainActor
    private func generateShareImage() {
        guard let data = reportData else { return }
        
        let reportView = VStack(spacing: 0) {
            reportHeader(data: data)
            monthHeaderRow()
            balanceRow(label: "💰 Solde initial", amounts: data.monthlyBalanceStart, color: finzPurple)
            sectionDivider(title: "RECETTES", icon: "arrow.up.circle.fill", color: .green)
            ForEach(data.incomeCategories) { cat in
                categoryBlock(cat: cat, tintColor: .green)
            }
            totalRow(label: "Total Recettes", amounts: data.monthlyIncomes, total: data.totalIncomes, color: .green)
            sectionDivider(title: "DÉPENSES", icon: "arrow.down.circle.fill", color: finzPink)
            ForEach(data.expenseCategories) { cat in
                categoryBlock(cat: cat, tintColor: finzPink)
            }
            totalRow(label: "Total Dépenses", amounts: data.monthlyExpenses, total: data.totalExpenses, color: finzPink)
            balanceRow(label: "📊 Solde fin de mois", amounts: data.monthlyBalance, color: finzPurple)
        }
        .frame(width: 1200)
        .background(.white)
        
        let renderer = ImageRenderer(content: reportView)
        renderer.scale = 2.0
        
        if let image = renderer.uiImage {
            renderedImage = image
            showShareSheet = true
        }
    }
}
